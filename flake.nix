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

    # DankMaterialShell — Material Design shell layer for niri
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Rust toolchain management
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GHC 9.12 wasm32-wasi cross-compilation toolchain
    # Needed to build exomonad's Haskell WASM plugins (wasm-guest-devswarm.wasm)
    ghc-wasm-meta.url = "gitlab:haskell-wasm/ghc-wasm-meta?host=gitlab.haskell.org";

    # ── Agent Infrastructure ────────────────────────────────────────────────────
    # masterblaster (mb) — stereOS AI agent sandbox manager
    masterblaster = {
      url = "github:papercomputeco/masterblaster";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # opencode — AI coding agent (TypeScript, anomalyco)
    opencode = {
      url = "github:anomalyco/opencode/v1.14.20";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Agent Framework ─────────────────────────────────────────────────────────
    # All agent tools lack Nix flake outputs — built via custom derivations in pkgs/.
    # See pkgs/default.nix for the full list and build status.
    # crosslink is a library-only Cargo dependency — no binary derivation needed.
  };

  outputs = {
    self, nixpkgs, nixos-hardware, home-manager, niri, dms, masterblaster, rust-overlay,
    ghc-wasm-meta, opencode,
    ...
  }@inputs:
  let
    system = "x86_64-linux";

    # nixpkgs with both overlays applied — used for exposing pkgs/ tools as
    # first-class flake outputs so `nix build .#<tool>` works for hash-filling.
    pkgs = nixpkgs.legacyPackages.${system}.extend
      (nixpkgs.lib.composeExtensions
        rust-overlay.overlays.default
        (import ./pkgs/default.nix { inherit ghc-wasm-meta; }));

    # Helper to build a NixOS system config — keeps outputs block clean.
    # withNiri: set false for headless hosts (embedded) that don't run a compositor.
    mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [], withNiri ? true }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Inject overlays into nixpkgs:
          #   rust-overlay  — pkgs.rust-bin.* for declarative Rust toolchain management
          #   pkgs/default  — custom agent framework tools (added incrementally)
          ({ inputs, ... }: { nixpkgs.overlays = [
            rust-overlay.overlays.default
            (import ./pkgs/default.nix { inherit (inputs) ghc-wasm-meta; })
            opencode.overlays.default
          ]; })

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
        # niri.nixosModules.niri removed — it pins niri v25.08 which lacks `include` support.
        # nixpkgs niri v25.11+ has include support; enabled via programs.niri.enable in config.
        ++ extraModules;
      };
  in
  {
    # ── Agent tool packages — for hash-filling workflow ────────────────────────
    # Usage: nix build .#<tool> 2>&1 | grep "got:"
    # Fill the "got:" hash into pkgs/<tool>.nix, then repeat for cargoHash/vendorHash.
    packages.${system} = {
      inherit (pkgs)
        masterblaster
        tilth
        kaish
        chainlink
        exomonad
        exomonadWasm;
      inherit (pkgs) context-mode;
      opencode = (opencode.packages.${system}.opencode).override {
        bun = pkgs.bun;
      };
    };

    nixosConfigurations = {

      # ── Framework 13" 11th-gen Intel ──────────────────────────────────────────
      framework = mkSystem {
        hostname = "framework";
        extraModules = [
          nixos-hardware.nixosModules.framework-11th-gen-intel
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
