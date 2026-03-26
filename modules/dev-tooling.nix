{ pkgs, inputs, ... }:

# ── Dev Tooling — Rust + Python ───────────────────────────────────────────────
#
# DESIGN DECISIONS — worth reading before changing anything here:
#
# RUST
# ────
# We install a stable Rust toolchain system-wide via rust-overlay rather than
# rustup. This gives you `cargo`, `rustc`, `rust-analyzer`, `clippy`, and
# `rustfmt` available in every terminal immediately.
#
# Why not rustup?
#   rustup wants to manage toolchains in ~/.rustup and download them at runtime.
#   On NixOS this fights with the Nix store and creates untracked mutable state.
#   rust-overlay gives you the same flexibility (any stable/nightly/dated version)
#   but as proper Nix derivations, pinned in flake.lock, reproducible.
#
# For projects that need a *different* version (e.g. a specific nightly for
# embedded work), override it in that project's flake.nix devShell:
#
#   devShells.default = pkgs.mkShell {
#     buildInputs = [
#       pkgs.rust-bin.nightly."2025-01-01".default
#     ];
#   };
#
# PYTHON
# ──────
# We install a base Python 3 interpreter system-wide. This gives you `python3`
# and `pip` in your PATH. However, we intentionally keep global pip installs
# minimal — Python package conflicts are real and Nix solves them better with
# per-environment isolation.
#
# marimo is the exception: it's your primary notebook tool and you want it
# available anywhere, so it's in a dedicated Python env managed by Nix
# (not installed with pip, which would be untracked and fragile).
#
# For data science / analysis projects, the pattern is a per-project flake.nix:
#
#   devShells.default = pkgs.mkShell {
#     buildInputs = [
#       (pkgs.python3.withPackages (ps: with ps; [
#         numpy pandas polars matplotlib seaborn scikit-learn
#         marimo  # included here too if the project uses it
#       ]))
#     ];
#   };
#
# Then `nix develop` drops you into that environment. VS Code + direnv
# (via the direnv extension) picks it up automatically when you open the folder.

{
  # Wireshark — packet capture requires the setuid wrapper managed by the
  # programs module (sets CAP_NET_RAW on dumpcap, creates the wireshark group).
  # Add your user to the wireshark group: users.users.you.extraGroups = [ "wireshark" ]
  programs.wireshark.enable = true;


  environment.systemPackages = with pkgs; [

    # ── Network analysis ──────────────────────────────────────────────────
    nmap           # port scanning and network discovery
    wireshark
    tshark

    # ── Android / ADB ─────────────────────────────────────────────────────
    # programs.adb was removed; systemd 258+ handles uaccess rules automatically.
    # android-tools provides adb, fastboot, etc. No extra group needed.
    android-tools

    # ── Rust toolchain (system-wide stable) ───────────────────────────────
    # rust-bin comes from the rust-overlay flake injected in flake.nix.
    # .default gives you: rustc, cargo, clippy, rustfmt
    # .default.override { extensions = [...] } adds more components.
    (rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"        # needed by rust-analyzer for stdlib go-to-definition
        "rust-analyzer"   # LSP server (VS Code rust-analyzer extension uses this)
        "clippy"          # linter
        "rustfmt"         # formatter
      ];
    })

    # Cargo helper tools (these ARE in nixpkgs, no overlay needed)
    cargo-watch    # cargo watch -x run — reruns on file change
    cargo-edit     # cargo add / cargo rm — edit Cargo.toml from CLI
    cargo-nextest  # faster test runner (drop-in for cargo test)
    cargo-expand   # expand macros to see what they generate
    sccache        # shared compilation cache — speeds up rebuilds significantly

    # ── Python base interpreter ────────────────────────────────────────────
    # Bare interpreter + pip. Keep global pip installs to zero — use
    # per-project devShells or the marimo env below for actual packages.
    python3
    python3Packages.pip
    uv             # fast Python package/project manager (Rust-based, Astral)
                   # use `uv run` and `uv venv` for quick one-off environments

    # ── marimo — disabled: nixpkgs 0.19.4 patch is broken, re-enable when fixed
    # (python3.withPackages (ps: with ps; [
    #   marimo numpy pandas polars matplotlib seaborn plotly altair
    #   requests httpx pydantic python-dotenv ipykernel
    # ]))
  ];

  # ── sccache config — shared Rust compilation cache ────────────────────────
  # Caches compiled Rust artifacts so rebuilding after minor changes is fast.
  # Works transparently — cargo calls sccache automatically once RUSTC_WRAPPER is set.
  environment.sessionVariables = {
    RUSTC_WRAPPER = "sccache";
    # Cargo home in a stable location (not randomised per-shell)
    CARGO_HOME    = "$HOME/.cargo";
    # Make rust-analyzer find the system rust-src
    RUST_SRC_PATH = "${pkgs.rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" ];
    }}/lib/rustlib/src/rust/library";
  };
}
