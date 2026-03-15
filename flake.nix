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
    # NOTE: Run `nix flake show <url>` to verify each of these has flake outputs
    # before relying on inputs.<name>.packages.${system}.default in agent-framework.nix.
    # The plan's "Items for Claude Code to Investigate" section lists them all.

    # MCP server composition — composes multiple MCP servers into unified tool surface
    chainlink.url              = "github:dollspace-gay/chainlink";

    # Orchestration router — Opus plans, agents execute; handles task dispatch
    exomonad.url               = "github:tidepool-heavy-industries/exomonad";

    # Recursive LM self-reflection engine
    axon.url                   = "github:Diogenesoftoronto/axon";

    # Agent shell — constrained, structured, agent-safe environment
    kaish.url                  = "github:tobert/kaish";

    # Context window management (per-agent + planner)
    context-mode.url           = "github:mksglu/context-mode";

    # Learning opportunities / deliberate skill development
    learning-opportunities.url = "github:DrCatHicks/learning-opportunities";

    # Tracing / observability for agent runs
    tracey.url                 = "github:bearcove/tracey";

    # ── Non-flake packages ──────────────────────────────────────────────────────
    # These have no guaranteed flake outputs — derivations written in agent-framework.nix:
    #   monolith   → github:WingchunSiu/Monolith   (RLM reward signal — buildRustPackage)
    #   crosslink  → lib.rs/crates/crosslink        (library only — Cargo dep, no derivation)
    #   tilth      → crates.io/crates/tilth         (code intelligence MCP — buildRustPackage)
    #   pyncd      → github:mit-zardini-lab/pyncd   (NCD similarity scoring — buildPythonPackage)
  };

  outputs = {
    self, nixpkgs, nixos-hardware, home-manager, niri, masterblaster, rust-overlay,
    chainlink, exomonad, axon, kaish, context-mode, learning-opportunities, tracey,
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
          ./modules/agent-framework.nix

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
