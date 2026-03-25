# mixtape/flake.nix — placeholder
#
# We originally planned to build a custom stereOS disk image here using
# masterblaster.lib.buildMixtape, but masterblaster does not expose a
# lib output — mixtapes are pre-built OCI images from download.stereos.ai.
#
# Current approach (option 1):
#   1. mb pull coder-x86:latest
#   2. mb up --config jcard.toml
#   3. mb ssh -- bash /nix-workspace/mixtape/provision.sh
#
# Option 2 (future): build a full NixOS raw disk image via nixos-generators,
# package as OCI artifact in mb's format, distribute via local registry.
# See mixtape.nix for the intended package list.
