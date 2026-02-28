# ── Per-project dev shell template ───────────────────────────────────────────
#
# Drop this flake.nix into any project root.
# Run: nix develop        → enter the dev environment
#      nix develop --command zsh  → enter with a specific shell
#
# VS Code + the direnv extension picks this up automatically when you open
# the folder — no manual `nix develop` needed.
#
# This template has two variants — uncomment the one you need:
#   1. Rust project (overrides system stable with a specific version/nightly)
#   2. Python / marimo data project (richer package set than the system env)
#
# For most projects you'll only need one. They can be combined.

{
  description = "Project dev environment";

  inputs = {
    nixpkgs.url    = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay   = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        # ── VARIANT 1: Rust project ──────────────────────────────────────
        # Uncomment and adjust the channel/date as needed.
        # Options:
        #   pkgs.rust-bin.stable.latest.default       ← same as system
        #   pkgs.rust-bin.beta.latest.default         ← beta channel
        #   pkgs.rust-bin.nightly.latest.default      ← latest nightly
        #   pkgs.rust-bin.nightly."2025-06-01".default ← pinned nightly date

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          # Uncomment for cross-compilation targets, e.g. embedded or WASM:
          # targets = [ "thumbv7em-none-eabihf" "wasm32-unknown-unknown" ];
        };

        # ── VARIANT 2: Python / marimo data project ──────────────────────
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          # Expand this list per-project — it won't affect your system Python
          marimo
          numpy
          pandas
          polars
          matplotlib
          seaborn
          plotly
          altair
          scikit-learn
          scipy
          # Add project-specific packages here:
          # sqlalchemy
          # duckdb
          # pyarrow
        ]);

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # ── Uncomment the variant(s) you need ──────────────────────
            rustToolchain   # Variant 1: Rust
            # pythonEnv    # Variant 2: Python/marimo

            # Common tools available in all project shells
            pkgs.git
            pkgs.just       # command runner (like make but nicer)
            pkgs.direnv     # auto-activates this shell when you cd into the dir
          ];

          # Shell hook runs when you enter the dev environment
          shellHook = ''
            echo "🦀 Dev environment ready"
            echo "   Rust: $(rustc --version 2>/dev/null || echo 'not included')"
            echo "   Python: $(python3 --version 2>/dev/null || echo 'not included')"
          '';

          # Environment variables scoped to this dev shell only
          # RUST_LOG = "debug";
          # DATABASE_URL = "postgres://localhost/mydb";
        };
      }
    );
}
