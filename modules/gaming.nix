{ pkgs, config, ... }:

{
  # ── 32-bit support ─────────────────────────────────────────────────────────
  # Steam and Proton are 32-bit applications. Without this, Steam won't launch.

  hardware.graphics = {
    enable        = true;
    enable32Bit   = true;
  };

  # ── Steam ──────────────────────────────────────────────────────────────────
  # Unfree — install manually after adding nixpkgs.config.allowUnfree = true
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall      = true;
  #   dedicatedServer.openFirewall = false;
  #   extraCompatPackages = with pkgs; [ proton-ge-bin ];
  # };

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

    # Discord — unfree, install manually after enabling allowUnfree
    # vesktop

    # Useful for checking what Proton version a game needs before launching
    # Visit protondb.com for community compatibility reports
  ];
}
