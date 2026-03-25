# masterblaster (mb) — stereOS AI agent sandbox manager
# Source: github:papercomputeco/masterblaster (Go)
#
# Fill in hashes:
#   nix build .#masterblaster 2>&1 | grep "got:"   (run on laptop after each fake hash)

{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname   = "masterblaster";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "papercomputeco";
    repo  = "masterblaster";
    rev   = "0583118a806deeecd1b0d9dccf87b75a863f971e";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Run with fake hash first to get the real vendorHash from the error output
  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
