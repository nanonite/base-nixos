# exomonad — task orchestration router (Opus planner → agent sandboxes)
# Source: github:tidepool-heavy-industries/exomonad (Rust + Haskell WASM)
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
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "tidepool-heavy-industries";
    repo  = "exomonad";
    rev   = "5dfab102fe65d5d1d57d54651c000b6de1336e70";
    hash  = "sha256-ILK9PEjJYvVq2IpnWsRFhOIkncEoOgobN7cA/an29kk=";
  };

  nativeBuildInputs = [ pkg-config protobuf ];
  buildInputs       = [ openssl ];

  cargoHash = "sha256-09D4PCB5ZjDTNFPZm6JvWNdv/AQjurWp8MRiijVSmuA=";

  cargoBuildFlags = [ "-p" "exomonad" ];
  cargoTestFlags  = [ "-p" "exomonad" ];

  # Bundle WASM plugins alongside the binary
  postInstall = ''
    mkdir -p $out/share/exomonad/wasm
    cp ${exomonadWasm}/*.wasm $out/share/exomonad/wasm/
  '';
}
