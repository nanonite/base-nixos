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

{ rustPlatform, fetchFromGitHub, nodejs, pnpm_9, fetchPnpmDeps, pnpmConfigHook }:

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
  # fetcherVersion = 2 matches pnpm lockfileVersion 9.0
  pnpmDeps = fetchPnpmDeps {
    pname   = "${pname}-dashboard";
    inherit version src;
    sourceRoot = "source/crates/tracey/src/bridge/http/dashboard";
    fetcherVersion = 2;
    hash = "sha256-oFyJcA5/tzTaxDOP07nudp1jn/s+sixHC7MuasINFf8=";
  };

  # Tell pnpmConfigHook where package.json / pnpm-lock.yaml live
  pnpmRoot = "crates/tracey/src/bridge/http/dashboard";

  nativeBuildInputs = [ nodejs pnpm_9 pnpmConfigHook ];

  cargoHash = "sha256-Rnlbh3qnzez8D9kEikzHpgT0tSO60S9fuhREzJ7HhwY=";

  cargoBuildFlags = [ "-p" "tracey" ];
  cargoTestFlags  = [ "-p" "tracey" ];
}
