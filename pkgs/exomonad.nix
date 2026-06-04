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
  version = "unstable-2026-05-25";

  src = fetchFromGitHub {
    owner = "nanonite";
    repo  = "exomonad";
    # feat/codex-integration
    rev   = "e0ac788e73e4499c1fc558686f2b49fde32a5cdb";
    hash  = "sha256-DT519nrx0LcxUDwngLIEr63T/0qfX9s+hWRdUd5bDv4=";
  };

  nativeBuildInputs = [ pkg-config protobuf ];
  buildInputs       = [ openssl ];

  cargoHash = "sha256-QA9sueqhHqPyr2NDH6z0V8L101E9xzArfvr8u1ebOzY=";

  depsExtraArgs = {
    preBuild = ''
      # crates.io rejects the helper's default python-requests user agent.
      mkdir -p .nix-cargo-vendor-bin
      cp "$(command -v fetch-cargo-vendor-util)" .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      chmod +w .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      substituteInPlace .nix-cargo-vendor-bin/fetch-cargo-vendor-util \
        --replace-fail 'session = requests.Session()' 'session = requests.Session(); session.headers.update({"User-Agent": "nixpkgs-fetch-cargo-vendor"})'
      chmod +x .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      export PATH="$PWD/.nix-cargo-vendor-bin:$PATH"
    '';
  };

  doCheck = false;

  cargoBuildFlags = [ "-p" "exomonad" ];

  postInstall = ''
    # Store WASM plugins in the package share directory.
    # home-manager activation (home/home.nix) symlinks these into ~/.exo/wasm/
    # which is where exomonad looks by default.
    mkdir -p $out/share/exomonad/wasm
    cp ${exomonadWasm}/*.wasm $out/share/exomonad/wasm/
  '';
}
