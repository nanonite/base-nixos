# chainlink — composes multiple MCP servers into a unified agent tool surface
# Source: github:dollspace-gay/chainlink (Rust crate at chainlink/ subdir)
#
# Fill in hashes:
#   nix build .#chainlink 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname   = "chainlink";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "dollspace-gay";
    repo  = "chainlink";
    rev   = "ab49ee11eb4d2539d7cfd6acae17eed9242c786b";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Rust crate lives in the chainlink/ subdirectory of the repo
  sourceRoot = "source/chainlink";

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
