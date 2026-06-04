{ pkgs, lib, config, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Modules not in common.nix (excluded so embedded hosts stay minimal)
    ../../modules/dev-tooling.nix
    ../../modules/gaming.nix
    ../../modules/remote-desktop.nix
    # nvidia.nix is loaded via extraModules in flake.nix (keeps it out of embedded)
  ];

  networking.hostName = "desktop";

  # ── niri Wayland compositor ────────────────────────────────────────────────
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
      user    = "greeter";
    };
  };

  # Companion Wayland applications (same set as framework)
  environment.systemPackages = with pkgs; [
    waybar
    fuzzel
    foot
    swaylock
    swayidle
    mako
    xwayland-satellite
    grim
    slurp
    wl-clipboard
    swaybg
    wlsunset
    polkit_gnome
  ];

  security.polkit.enable = true;
  systemd.user.services.polkit-gnome = {
    description = "Polkit GNOME agent";
    wantedBy    = [ "graphical-session.target" ];
    wants       = [ "graphical-session.target" ];
    after       = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  };

  # ── Power management ───────────────────────────────────────────────────────
  # Desktop stays on AC — no TLP needed. Just enable power profiles for
  # on-demand GPU workload scaling (useful for NVIDIA + CUDA agent runs).
  services.power-profiles-daemon.enable = true;

  # ── Bluetooth ──────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable      = true;
    powerOnBoot = true; # desktop can keep BT always on
  };
  services.blueman.enable = true;
}
