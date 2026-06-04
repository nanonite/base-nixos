# tilth — code intelligence MCP server
# Source: crates.io/crates/tilth v0.8.4 (Rust)
#
# Fill in hashes:
#   nix build .#tilth 2>&1 | grep "got:"

{ rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname   = "tilth";
  version = "0.8.4";

  src = fetchCrate {
    pname   = "tilth";
    version = "0.8.4";
    hash    = "sha256-ZWU/RdNzDgTmHYuYWLQmrMYX4idEpKIu3sJs5EStSR0=";
  };

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
