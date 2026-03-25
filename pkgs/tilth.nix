# tilth — code intelligence MCP server
# Source: crates.io/crates/tilth v0.5.1 (Rust)
#
# Fill in hashes:
#   nix build .#tilth 2>&1 | grep "got:"

{ rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname   = "tilth";
  version = "0.5.1";

  src = fetchCrate {
    pname   = "tilth";
    version = "0.5.1";
    hash    = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
