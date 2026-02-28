{ pkgs, config, ... }:

{
  # ── 32-bit support ─────────────────────────────────────────────────────────
  # Steam and Proton are 32-bit applications. Without this, Steam won't launch.

  hardware.opengl = {
    enable        = true;
    driSupport    = true;
    driSupport32Bit = true;
  };

  # ── Steam ──────────────────────────────────────────────────────────────────

  programs.steam = {
    enable = true;
    remotePlay.openFirewall      = true;
    dedicatedServer.openFirewall = false;

    # Proton-GE: community fork of Proton with extra patches, better codec
    # support, and faster fixes for newly released games than stock Proton.
    # Select it per-game in Steam → Properties → Compatibility → Force use of...
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # ── GameMode ───────────────────────────────────────────────────────────────
  # Lets games request a performance CPU governor, reduced background process
  # priority, and other optimisations for the duration of a gaming session.
  # Enable per game via Steam launch option: gamemoderun %command%

  programs.gamemode.enable = true;

  # ── Gaming packages ────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    # Proton tooling
    protontricks   # apply Winetricks fixes to specific Proton game prefixes
    protonup-qt    # GUI to download and manage Proton-GE versions

    # Overlays and monitoring
    mangohud       # in-game overlay: FPS, frametime, GPU/CPU temp, VRAM usage
                   # Enable per game: mangohud %command%  (or gamemoderun mangohud %command%)
    goverlay       # graphical config editor for MangoHud

    # Discord
    # vesktop is strongly preferred over the official discord package:
    #  - ships Vencord (plugin system) built in
    #  - updates independently of nixpkgs so you won't hit "client outdated" errors
    #  - proper Wayland screen share via Pipewire out of the box
    vesktop

    # Useful for checking what Proton version a game needs before launching
    # Visit protondb.com for community compatibility reports
  ];
}
