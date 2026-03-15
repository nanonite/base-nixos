{ lib, pkgs, config, inputs, ... }:

# ── embedded/configuration.nix — board-agnostic base ─────────────────────────
#
# Common config for ALL embedded targets (RPi 4, RPi 5, future SBCs).
# Board-specific overrides (boot loader, kernel modules) live in rpi4.nix etc.
# and are passed in via extraModules in flake.nix.
#
# NOT imported: gaming.nix, remote-desktop.nix, nvidia.nix (desktop-only)
# agent-framework.nix is loaded by mkSystem for all hosts.

{
  imports = [
    ./hardware-configuration.nix

    # Dev tooling — agents need Rust, Python, and standard dev tools
    ../../modules/dev-tooling.nix

    # No gaming.nix, remote-desktop.nix, or nvidia.nix on embedded
  ];

  networking.hostName = "embedded";

  # ── Headless boot — no display manager, no compositor ─────────────────────
  # Auto-login on tty1 so agent processes can start without a password prompt.
  # Replace "you" with your actual username.
  services.getty.autologinUser = lib.mkDefault "you";

  # Serial console for debugging without a monitor — essential for SBCs
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];

  # ── SSH access ─────────────────────────────────────────────────────────────
  # The planner dispatches mb workloads to the embedded host over SSH.
  # Key-only auth — add your public key below.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # Add your SSH public key:
  # users.users.you.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA... you@framework"
  # ];

  # Open SSH in firewall (embedded uses a simple firewall)
  networking.firewall.allowedTCPPorts = [ 22 ];

  # ── Minimal package set ───────────────────────────────────────────────────
  # Dev tooling comes from dev-tooling.nix.
  # Agent framework tools come from agent-framework.nix (loaded by mkSystem).
  # Add embedded-specific utilities here.
  environment.systemPackages = with pkgs; [
    # Useful for embedded debugging
    usbutils    # lsusb
    pciutils    # lspci
    iproute2    # ip addr, ip route
    ethtool
    htop
  ];

  # ── No audio on headless embedded ─────────────────────────────────────────
  sound.enable    = false;
  hardware.pulseaudio.enable = false;
  # services.pipewire is NOT enabled for embedded (not needed for agent runs)

  # ── Nix settings for aarch64 ──────────────────────────────────────────────
  # Allow the embedded host to be a remote builder for aarch64 derivations.
  nix.settings.trusted-users = [ "root" "@wheel" ];
}
