{ pkgs, config, lib, ... }:

# ── Remote Desktop — wayvnc ────────────────────────────────────────────────────
#
# Traditional VNC servers (x11vnc, tigervnc) don't work on Wayland — they need
# an X11 server to capture frames from. wayvnc is a VNC server built for
# Wayland compositors. It uses the wlr-screencopy protocol, which niri supports.
#
# ┌──────────────────────────────────────────────────────────────────────────┐
# │ Connecting from another machine:                                         │
# │   Any VNC client works: RealVNC, TigerVNC viewer, Remmina (Linux),      │
# │   built-in macOS Screen Sharing, Remote Ripple (iOS/Android)             │
# │                                                                          │
# │   Address:  <framework-ip>:5900                                          │
# │   Find IP:  ip addr  (or check your router's DHCP table)                 │
# │                                                                          │
# │ SECURITY: wayvnc listens on all interfaces by default.                   │
# │   - Set a password (see wayvncpasswd below)                              │
# │   - Consider binding to LAN only via the address option                  │
# │   - Or tunnel over SSH: ssh -L 5900:localhost:5900 you@framework         │
# │     then connect your VNC client to localhost:5900                       │
# └──────────────────────────────────────────────────────────────────────────┘

{
  environment.systemPackages = with pkgs; [
    wayvnc        # Wayland VNC server — start with: wayvnc (also provides wayvncpasswd)
    tigervnc      # provides the vncviewer client if you want to VNC *out* from here
  ];

  # ── wayvnc as a systemd user service ──────────────────────────────────────
  #
  # wayvnc must run as your user (not root) because it needs access to the
  # running Wayland session. We use a systemd user service that starts
  # automatically when your graphical session starts.
  #
  # After first login, set a VNC password:
  #   wayvncpasswd ~/.config/wayvnc/password.ini
  # Then enable and start the service:
  #   systemctl --user enable --now wayvnc

  systemd.user.services.wayvnc = {
    description = "wayvnc Wayland VNC server";

    # Start after the graphical session (niri) is up
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];
    after    = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc --config=%h/.config/wayvnc/config 0.0.0.0 5900";
      Restart      = "on-failure";
      RestartSec   = "3s";
    };
  };

  # ── Firewall — open VNC port on LAN ───────────────────────────────────────
  # If you only want SSH tunnelling (more secure), remove these lines and
  # keep the firewall closed. Then connect via: ssh -L 5900:localhost:5900 you@framework

  networking.firewall = {
    allowedTCPPorts = [ 5900 ]; # VNC
  };

  # ── SSH — enables the SSH tunnel option and remote terminal access ─────────

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # key-based auth only (more secure)
      PermitRootLogin        = "no";
    };
  };

  # To add your SSH public key, either:
  # A) Add it here in the config (most reproducible):
  # users.users.you.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA... you@yourmachine"
  # ];
  #
  # B) Or copy it manually after first boot:
  # ssh-copy-id you@framework-ip
}
