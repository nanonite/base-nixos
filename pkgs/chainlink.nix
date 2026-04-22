# chainlink — composes multiple MCP servers into a unified agent tool surface
# Source: github:nanonite/chainlink (Rust crate at chainlink/ subdir)
#
# Fill in hashes:
#   nix build .#chainlink 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname   = "chainlink";
  version = "unstable-2026-04-10";

  src = fetchFromGitHub {
    owner = "nanonite";
    repo  = "chainlink";
    rev   = "d2a134479a5657f281279f852c68863895c000fa";
    hash  = "";
  };

  # Rust crate lives in the chainlink/ subdirectory of the repo
  sourceRoot = "source/chainlink";

  cargoHash = "";
}
