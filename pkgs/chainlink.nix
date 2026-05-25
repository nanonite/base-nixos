# chainlink — composes multiple MCP servers into a unified agent tool surface
# Source: github:nanonite/chainlink (Rust crate at chainlink/ subdir)
#
# Fill in hashes:
#   nix build .#chainlink 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname   = "chainlink";
  version = "unstable-2026-05-25";

  src = fetchFromGitHub {
    owner = "nanonite";
    repo  = "chainlink";
    rev   = "c90648adeb3f850db24659404560544ad79fbffb";
    hash  = "sha256-5LVHF8e5hj2Q4T8/2dQ85/C9MkOwlHB1teW0Qb6UbDg=";
  };

  # Rust crate lives in the chainlink/ subdirectory of the repo
  sourceRoot = "source/chainlink";

  cargoHash = "sha256-LdczNjkvji1IOuuq/dA3MH2i+aNMr02YCWWpvidnGC8=";

  doCheck = false;
}
