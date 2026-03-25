{
  description = "agent-workbench — pre-baked stereOS mixtape for AI agent sandboxes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # stereOS base image (provides mb mixtape infrastructure + buildMixtape lib)
    masterblaster = {
      url = "github:papercomputeco/masterblaster";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, masterblaster, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system}.extend
      # Apply the same custom overlay as the host flake so pkgs.kaish, pkgs.axon,
      # pkgs.tilth, etc. are available inside the mixtape module.
      (import ../pkgs/default.nix);
  in
  {
    # Build the OCI image with all agent tools pre-installed.
    # Usage:
    #   nix build .#mixtape
    #   mb mixtape publish agent-workbench:latest ./result
    packages.${system} = {
      mixtape = masterblaster.lib.buildMixtape {
        inherit pkgs inputs;
        module = ./mixtape.nix;
        name   = "agent-workbench";
        tag    = "latest";
      };
      default = self.packages.${system}.mixtape;
    };
  };
}
