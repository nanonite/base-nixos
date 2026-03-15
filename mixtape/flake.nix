{
  description = "agent-workbench — pre-baked stereOS mixtape for AI agent sandboxes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # stereOS base image (provides the mb mixtape infrastructure)
    masterblaster = {
      url = "github:papercomputeco/masterblaster";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agent tools — same inputs as the host flake
    axon.url  = "github:Diogenesoftoronto/axon";
    kaish.url = "github:tobert/kaish";
  };

  outputs = { self, nixpkgs, masterblaster, axon, kaish, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in
  {
    # Build the OCI image with all agent tools pre-installed.
    # Usage:
    #   nix build .#mixtape
    #   mb mixtape publish agent-workbench:latest ./result
    packages.${system}.mixtape = masterblaster.lib.buildMixtape {
      inherit pkgs inputs;
      # NixOS module that adds packages on top of the base stereOS image
      module = ./mixtape.nix;
      # Image metadata
      name = "agent-workbench";
      tag  = "latest";
    };

    packages.${system}.default = self.packages.${system}.mixtape;
  };
}
