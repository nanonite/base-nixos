# tracey — structured observability for agent runs
# Source: github:bearcove/tracey (Rust workspace, binary at crates/tracey)
#
# The build embeds a Vite dashboard (crates/tracey/src/bridge/http/dashboard/).
# pnpm deps are pre-fetched via pnpm_9.fetchDeps to satisfy the Nix sandbox.
#
# Hash-filling order:
#   1. nix build .#tracey 2>&1 | grep "got:"  → src hash
#   2. nix build .#tracey 2>&1 | grep "got:"  → pnpmDeps hash
#   3. Cargo dependencies are pinned by upstream Cargo.lock.

{ rustPlatform, fetchFromGitHub, nodejs, pnpm_9, fetchPnpmDeps, pnpmConfigHook, gitMinimal }:

rustPlatform.buildRustPackage rec {
  pname   = "tracey";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "bearcove";
    repo  = "tracey";
    rev   = "6fe672f12dc7005a48a33f0f9c486794e49a9974";
    hash  = "sha256-2011vY0xOGnmrpxGms8LSTa+o7PJ0HRuqlMmzm3X5N0=";
  };

  # Pre-fetch pnpm node_modules for the embedded Vite dashboard.
  # fetcherVersion = 3 stores a reproducible pnpm store tarball for pnpm 9.
  pnpmDeps = fetchPnpmDeps {
    pname   = "${pname}-dashboard";
    inherit version src;
    pnpm = pnpm_9;
    sourceRoot = "source/crates/tracey/src/bridge/http/dashboard";
    fetcherVersion = 3;
    hash = "sha256-nxDSFhpwL7o05wp62qcrUDYRDSyRi9JVAXen63tW7P4=";
  };

  # Tell pnpmConfigHook where package.json / pnpm-lock.yaml live
  pnpmRoot = "crates/tracey/src/bridge/http/dashboard";

  nativeBuildInputs = [ nodejs pnpm_9 pnpmConfigHook gitMinimal ];

  cargoLock.lockFile = "${src}/Cargo.lock";

  cargoBuildFlags = [ "-p" "tracey" ];
  cargoTestFlags  = [ "-p" "tracey" ];
}
