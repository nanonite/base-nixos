{
  description = "NixOS config — Framework 13 (11th gen Intel) + Desktop";

  inputs = {
    # Track unstable for best hardware support and freshest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware-specific quirks and drivers, including Framework modules
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager — manages user-level config (tmux, shell, dotfiles, etc.)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # must use the same nixpkgs as the system
    };

    # niri Wayland tiling compositor — community flake with NixOS + HM modules
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # masterblaster (mb) — stereOS AI agent sandbox manager
    masterblaster = {
      url = "github:papercomputeco/masterblaster";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # rust-overlay — declarative Rust toolchain management.
    # Better than rustup on NixOS: toolchains are proper Nix derivations,
    # pinned in flake.lock, reproducible, and composable in dev shells.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, niri, masterblaster, rust-overlay, ... }@inputs:
  let
    # Helper to build a NixOS system config — keeps outputs block clean
    mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Inject rust-overlay into nixpkgs so pkgs.rust-bin.* is available
          # everywhere — in system packages, Home Manager, and dev shells.
          ({ ... }: { nixpkgs.overlays = [ rust-overlay.overlays.default ]; })

          # Core shared config applied to every host
          ./modules/common.nix

          # niri NixOS system module (installs the compositor + session)
          niri.nixosModules.niri

          # Host-specific config (hardware, hostname, etc.)
          ./hosts/${hostname}/configuration.nix

          # Home Manager as a NixOS module — manages user "you" declaratively
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;     # share system nixpkgs (avoids duplicate downloads)
              useUserPackages = true;   # install HM packages into the system profile
              extraSpecialArgs = { inherit inputs; };
              users.you = import ./home/home.nix; # change "you" to your actual username
            };
          }
        ] ++ extraModules;
      };
  in
  {
    nixosConfigurations = {

      # ── Framework 13" 11th-gen Intel ──────────────────────────────────────
      framework = mkSystem {
        hostname = "framework";
        extraModules = [
          # Framework 13" 11th gen Intel hardware module — handles thermald,
          # power profiles, backlight, fingerprint reader, etc.
          nixos-hardware.nixosModules.framework-13-inch-11th-gen-intel
        ];
      };

      # ── Main Desktop (NVIDIA) ─────────────────────────────────────────────
      # Uncomment and fill in once you're ready to set up the desktop
      # desktop = mkSystem {
      #   hostname = "desktop";
      #   extraModules = [
      #     ./modules/nvidia.nix
      #   ];
      # };

    };
  };
}
