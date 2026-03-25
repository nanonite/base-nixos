# tracey — structured observability for agent runs
# Source: github:bearcove/tracey (Rust workspace, binary at crates/tracey)
#
# The build embeds a Vite dashboard (crates/tracey/src/bridge/http/dashboard/).
# pnpm deps are pre-fetched via pnpm_9.fetchDeps to satisfy the Nix sandbox.
#
# Hash-filling order:
#   1. nix build .#tracey 2>&1 | grep "got:"  → src hash
#   2. nix build .#tracey 2>&1 | grep "got:"  → pnpmDeps hash
#   3. nix build .#tracey 2>&1 | grep "got:"  → cargoHash

{ rustPlatform, fetchFromGitHub, nodejs, pnpm_9 }:

rustPlatform.buildRustPackage rec {
  pname   = "tracey";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "bearcove";
    repo  = "tracey";
    rev   = "6fe672f12dc7005a48a33f0f9c486794e49a9974";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Pre-fetch pnpm node_modules for the embedded Vite dashboard.
  # The configHook installs them before the Rust build runs build.rs.
  pnpmDeps = pnpm_9.fetchDeps {
    pname   = "${pname}-dashboard";
    inherit version src;
    sourceRoot = "source/crates/tracey/src/bridge/http/dashboard";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ nodejs pnpm_9 pnpm_9.configHook ];

  # configHook expects to run where pnpm-lock.yaml lives
  preBuild = ''
    pushd crates/tracey/src/bridge/http/dashboard > /dev/null
    pnpm install --frozen-lockfile --offline
    popd > /dev/null
  '';

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  cargoBuildFlags = [ "-p" "tracey" ];
  cargoTestFlags  = [ "-p" "tracey" ];
}
