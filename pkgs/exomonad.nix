# exomonad — task orchestration router (Opus planner → agent sandboxes)
# Source: github:tidepool-heavy-industries/exomonad (Rust workspace at rust/)
# Config: planner/exomonad.toml
#
# NOTE: As of 2026-03-24, rust/exomonad/src/ appears empty upstream.
# This derivation is a skeleton — update when the crate is implemented.
#
# Fill in hashes:
#   nix build .#exomonad 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname   = "exomonad";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "tidepool-heavy-industries";
    repo  = "exomonad";
    rev   = "5dfab102fe65d5d1d57d54651c000b6de1336e70";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Rust workspace lives under rust/ subdirectory
  sourceRoot = "source/rust";

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  # Build only the main exomonad binary
  cargoBuildFlags = [ "-p" "exomonad" ];
  cargoTestFlags  = [ "-p" "exomonad" ];
}
