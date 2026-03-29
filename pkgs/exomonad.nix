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
  version = "unstable-2026-03-28";

  src = fetchFromGitHub {
    owner = "tidepool-heavy-industries";
    repo  = "exomonad";
    rev   = "cb47b67464d0ea779acf2e1d6f79f82a72a355c5";
    hash  = "sha256-VReVtxB9R8ClY2jhu9WQswBoeSS1I0MOS6peZOcSBwA=";
  };

  nativeBuildInputs = [ pkg-config protobuf ];
  buildInputs       = [ openssl ];

  cargoHash = "sha256-09D4PCB5ZjDTNFPZm6JvWNdv/AQjurWp8MRiijVSmuA=";

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
