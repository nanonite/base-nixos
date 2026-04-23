# exomonad — task orchestration router (Opus planner → agent sandboxes)
# Source: github:nanonite/exomonad (Rust + Haskell WASM)
#
# Two-phase build:
#   exomonadWasm (pkgs/exomonad-wasm.nix) — Haskell roles compiled to wasm32-wasi
#   buildRustPackage                       — Rust MCP server binary
#
# WASM plugins are installed to $out/share/exomonad/wasm/; exomonad loads them
# from there at runtime (override with EXOMONAD_WASM_DIR or ~/.exo/wasm/).
#
# Hash-filling:
#   nix build .#exomonadWasm 2>&1 | grep "got:"  → fill outputHash in exomonad-wasm.nix
#   nix build .#exomonad     2>&1 | grep "got:"  → fill cargoHash below

{ rustPlatform, fetchFromGitHub, pkg-config, openssl, protobuf, exomonadWasm }:

rustPlatform.buildRustPackage {
  pname   = "exomonad";
  version = "unstable-2026-04-22";

  src = fetchFromGitHub {
    owner = "nanonite";
    repo  = "exomonad";
    rev   = "ca33d5d53bed7e276ebe55249ee6c9cd79b0cd66";
    hash  = "sha256-8wSunqJdO82fLyX3Suue76XyqymEv+J9EE071XYB2T0=";
  };

  nativeBuildInputs = [ pkg-config protobuf ];
  buildInputs       = [ openssl ];

  cargoHash = "sha256-e6LL6079wxvRiw98n2/pE55GO72EcqXDXz3VkdmbK70=";

  cargoBuildFlags = [ "-p" "exomonad" ];
  cargoTestFlags  = [ "-p" "exomonad" ];

  postInstall = ''
    # Store WASM plugins in the package share directory.
    # home-manager activation (home/home.nix) symlinks these into ~/.exo/wasm/
    # which is where exomonad looks by default.
    mkdir -p $out/share/exomonad/wasm
    cp ${exomonadWasm}/*.wasm $out/share/exomonad/wasm/
  '';
}
