# chainlink — composes multiple MCP servers into a unified agent tool surface
# Source: github:nanonite/chainlink (Rust crate at chainlink/ subdir)
#
# Fill in hashes:
#   nix build .#chainlink 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname   = "chainlink";
  version = "unstable-2026-04-29";

  src = fetchFromGitHub {
    owner = "nanonite";
    repo  = "chainlink";
    rev   = "9ce9928feb3de014cd79e106aa4090b7320c12ad";
    hash  = "sha256-Z5j3G6AmyKjgPaxoDNE09t3R90Tusap//4PHfYSRcLM=";
  };

  # Rust crate lives in the chainlink/ subdirectory of the repo
  sourceRoot = "source/chainlink";

  cargoHash = "sha256-LdczNjkvji1IOuuq/dA3MH2i+aNMr02YCWWpvidnGC8=";
}
