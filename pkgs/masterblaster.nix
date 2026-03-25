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
    hash  = "sha256-hgZLMXU3OuYIJkY/tJJHqcgm1t9cpGyZTQDgW8aZI28=";
  };

  # Only build the root binary — exclude .dagger CI subdirectory
  subPackages = [ "." ];

  vendorHash = "sha256-eB8BHIWuIqVgweUYaO6pb/dUs6GM5nxv/wJwWiPF0pM=";
}
