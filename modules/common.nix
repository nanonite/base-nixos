{ inputs, pkgs, lib, config, ... }:

# ── common.nix — shared base for ALL hosts ────────────────────────────────────
#
# What lives here: bootloader, Nix settings, btrfs, audio, portals, users.
# What does NOT live here: gaming, remote-desktop, dev-tooling, nvidia.
# Those are imported explicitly per-host so embedded hosts stay minimal.

{

  nixpkgs.config.allowUnfree = true;

  # ── Nix / Flakes ──────────────────────────────────────────────────────────

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Public binary caches — speeds up builds dramatically
      substituters = [
        "https://cache.nixos.org"
        "https://niri.cachix.org"         # niri compositor pre-built binaries
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSBd4="
      ];
      # Allow your user to use nix commands without sudo
      trusted-users = [ "root" "@wheel" ];
    };

    # Garbage collect automatically — removes old store paths not needed by
    # any current generation. 30d keeps enough runway to rollback comfortably.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Keep build inputs around so rollbacks can always rebuild without internet
    settings.keep-outputs = true;
    settings.keep-derivations = true;
  };

  # ── Bootloader (systemd-boot + boot counting) ─────────────────────────────
  #
  # Boot counting: each new generation gets 3 attempts to reach a healthy
  # running system. If it fails all 3 times, systemd-boot automatically falls
  # back to the previous good generation — no manual intervention needed.

  boot.loader = {
    systemd-boot = {
      enable = true;
      # Keep the last 10 generations in the boot menu
      configurationLimit = 10;
      # Enable automatic boot assessment / boot counting
      # Requires systemd-boot to be the bootloader (not GRUB)
      consoleMode = "auto";
    };
    efi.canTouchEfiVariables = true;
  };

  # Mark the boot as "successful" once we reach a running system.
  # This is what satisfies the boot counter so it doesn't count as a failure.
  systemd.additionalUpstreamSystemUnits = [
    "systemd-boot-check-no-failures.service"
  ];

  # ── Filesystem / btrfs ────────────────────────────────────────────────────
  #
  # Actual mount points live in hardware-configuration.nix per host.
  # This declares the btrfs maintenance services shared across all hosts.

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly"; # check data integrity, detect silent corruption
    fileSystems = [ "/" ];
  };

  # btrbk — scheduled btrfs snapshots as a safety net beneath Nix generations
  services.btrbk.instances.main = {
    onCalendar = "daily";
    settings = {
      snapshot_preserve     = "7d 4w 6m"; # 7 daily, 4 weekly, 6 monthly
      snapshot_preserve_min = "2d";
      volume."/" = {
        snapshot_dir = ".snapshots";
        subvolume = {
          "@"     = {};
          "@home" = {};
        };
      };
    };
  };

  # ── Locale / Time ─────────────────────────────────────────────────────────

  time.timeZone = "America/Bogota"; # change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Networking ────────────────────────────────────────────────────────────

  networking = {
    networkmanager.enable = true; # easiest wifi management
    firewall.enable = true;
  };

  # ── Users ─────────────────────────────────────────────────────────────────
  # IMPORTANT: Change "you" to your actual username throughout this file

  users.users.framework = {
    isNormalUser = true;
    description  = "framework";
    extraGroups  = [
      "wheel"        # sudo access
      "networkmanager"
      "video"        # backlight control
      "audio"
      "wireshark"    # live packet capture without sudo
      "users"        # /etc/nixos group ownership for git without sudo
      "kvm"          # KVM access for masterblaster
      "libvirtd"
      "docker"
    ];
    shell = pkgs.bash;
  };

  # Disable the root password — sudo via wheel is the only escalation path
  security.sudo.wheelNeedsPassword = true;

  # ── Virtualisation (required for masterblaster / mb) ─────────────────────

  virtualisation = {
    libvirtd.enable = true;
    # Enable vhost-vsock — used by masterblaster's Linux/KVM backend for
    # fast control-plane communication with stereOS sandboxes
    # (equivalent of what Vz.framework does on macOS)
  };

  boot.kernelModules     = [ "kvm-intel" "vhost_vsock" ];
  boot.extraModulePackages = [];

  # QEMU binfmt — allows building aarch64-linux derivations on x86_64 hosts.
  # Required for cross-compiling NixOS closures for the Raspberry Pi:
  #   nixos-rebuild switch --flake .#rpi4 --target-host pi@raspberrypi.local
  # Only meaningful on x86_64 hosts; harmless on aarch64.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # ── Audio (Pipewire) ──────────────────────────────────────────────────────

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    wireplumber.enable = true;
  };

  # ── XDG Portal (screen sharing, file pickers, etc.) ──────────────────────

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.niri.default = [ "gnome" "gtk" ];
  };

  # ── Fonts ─────────────────────────────────────────────────────────────────

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # ── Environment ───────────────────────────────────────────────────────────

  environment.sessionVariables = {
    # Tell all Electron apps (Discord, VSCode, etc.) to use native Wayland
    NIXOS_OZONE_WL = "1";
  };

  # ── System Packages (minimal — prefer Home Manager for user packages) ─────

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    gcc
    # TODO: re-enable after verifying masterblaster has flake packages output
    # inputs.masterblaster.packages.${pkgs.system}.default
  ];

  system.stateVersion = "25.05"; # do NOT change after first install
}
