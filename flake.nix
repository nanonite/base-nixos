{
  description = "NixOS config — Framework 13 / Desktop / Raspberry Pi — Agentic Sandbox Platform";

  inputs = {
    # ── Core NixOS ─────────────────────────────────────────────────────────────
    nixpkgs.url        = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri Wayland tiling compositor — community flake with NixOS + HM modules
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Rust toolchain management
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Agent Infrastructure ────────────────────────────────────────────────────
    # masterblaster (mb) — stereOS AI agent sandbox manager
    masterblaster = {
      url = "github:papercomputeco/masterblaster";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Agent Framework ─────────────────────────────────────────────────────────
    # NOTE: These inputs are commented out until each repo is confirmed to have
    # a flake.nix with packages.${system}.default output.
    # Verify with: nix flake show <url>

    # chainlink.url              = "github:dollspace-gay/chainlink";
    # exomonad.url               = "github:tidepool-heavy-industries/exomonad";
    # axon.url                   = "github:Diogenesoftoronto/axon";
    # kaish.url                  = "github:tobert/kaish";
    # context-mode.url           = "github:mksglu/context-mode";
    # learning-opportunities.url = "github:DrCatHicks/learning-opportunities";
    # tracey.url                 = "github:bearcove/tracey";

    # ── Non-flake packages ──────────────────────────────────────────────────────
    # These have no guaranteed flake outputs — derivations written in agent-framework.nix:
    #   monolith   → github:WingchunSiu/Monolith   (RLM reward signal — buildRustPackage)
    #   crosslink  → lib.rs/crates/crosslink        (library only — Cargo dep, no derivation)
    #   tilth      → crates.io/crates/tilth         (code intelligence MCP — buildRustPackage)
    #   pyncd      → github:mit-zardini-lab/pyncd   (NCD similarity scoring — buildPythonPackage)
  };

  outputs = {
    self, nixpkgs, nixos-hardware, home-manager, niri, masterblaster, rust-overlay,
    ...
  }@inputs:
  let
    # Helper to build a NixOS system config — keeps outputs block clean.
    # withNiri: set false for headless hosts (embedded) that don't run a compositor.
    mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [], withNiri ? true }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Inject rust-overlay into nixpkgs so pkgs.rust-bin.* is available
          # in system packages, Home Manager, and dev shells
          ({ ... }: { nixpkgs.overlays = [ rust-overlay.overlays.default ]; })

          # Core shared config (bootloader, Nix GC, btrfs, audio, portals, users)
          ./modules/common.nix

          # Agentic coding framework (orchestration, JIRA CLI, benchmark toggle)
          # TODO: re-enable after verifying all agent input flakes exist
          # ./modules/agent-framework.nix

          # Host-specific config (hardware, hostname, compositor, etc.)
          ./hosts/${hostname}/configuration.nix

          # Home Manager — manages user-level config declaratively
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs    = true;   # share system nixpkgs (avoids duplicate downloads)
              useUserPackages  = true;   # install HM packages into the system profile
              extraSpecialArgs = { inherit inputs; };
              users.you        = import ./home/home.nix; # replace "you" with your username
            };
          }
        ]
        # niri compositor — included for graphical hosts only
        ++ (if withNiri then [ niri.nixosModules.niri ] else [])
        ++ extraModules;
      };
  in
  {
    nixosConfigurations = {

      # ── Framework 13" 11th-gen Intel ──────────────────────────────────────────
      framework = mkSystem {
        hostname = "framework";
        extraModules = [
          nixos-hardware.nixosModules.framework-13-inch-11th-gen-intel
        ];
      };

      # ── Main Desktop (NVIDIA) ──────────────────────────────────────────────────
      desktop = mkSystem {
        hostname = "desktop";
        extraModules = [
          ./modules/nvidia.nix
        ];
      };

      # ── Raspberry Pi 4 (aarch64) ───────────────────────────────────────────────
      rpi4 = mkSystem {
        hostname = "embedded";
        system   = "aarch64-linux";
        withNiri = false; # headless — no compositor
        extraModules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./hosts/embedded/rpi4.nix
        ];
      };

      # ── Raspberry Pi 5 — add when ready ───────────────────────────────────────
      # rpi5 = mkSystem {
      #   hostname = "embedded";
      #   system   = "aarch64-linux";
      #   withNiri = false;
      #   extraModules = [ ./hosts/embedded/rpi5.nix ];
      # };

      # ── Future boards ─────────────────────────────────────────────────────────
      # rock5b = mkSystem {
      #   hostname = "embedded";
      #   system   = "aarch64-linux";
      #   withNiri = false;
      #   extraModules = [ ./hosts/embedded/rock5b.nix ];
      # };

    };
  };
}
