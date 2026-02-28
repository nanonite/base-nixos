{ inputs, pkgs, lib, ... }:

{
  home.username = "you";        # change to your actual username
  home.homeDirectory = "/home/you"; # change accordingly

  # Match this to system.stateVersion in common.nix — do NOT change after first install
  home.stateVersion = "25.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # ── niri Wayland compositor config ────────────────────────────────────────
  # The niri HM module manages ~/.config/niri/config.kdl declaratively.
  # Keybinds use the Mod key (Super/Windows key by default).

  programs.niri = {
    settings = {
      # Key bindings
      binds = with inputs.niri.lib.kdl; {
        # Terminal
        "Mod+Return"       = action.spawn "foot";
        # App launcher
        "Mod+D"            = action.spawn "fuzzel";
        # Close window
        "Mod+Q"            = action.close-window;
        # Focus windows
        "Mod+H"            = action.focus-column-left;
        "Mod+L"            = action.focus-column-right;
        "Mod+J"            = action.focus-window-down;
        "Mod+K"            = action.focus-window-up;
        # Move windows
        "Mod+Shift+H"      = action.move-column-left;
        "Mod+Shift+L"      = action.move-column-right;
        # Workspaces
        "Mod+1"            = action.focus-workspace 1;
        "Mod+2"            = action.focus-workspace 2;
        "Mod+3"            = action.focus-workspace 3;
        "Mod+4"            = action.focus-workspace 4;
        "Mod+5"            = action.focus-workspace 5;
        "Mod+Shift+1"      = action.move-window-to-workspace 1;
        "Mod+Shift+2"      = action.move-window-to-workspace 2;
        "Mod+Shift+3"      = action.move-window-to-workspace 3;
        # Screenshot (region)
        "Print"            = action.screenshot;
        "Mod+Print"        = action.screenshot-screen;
        # Fullscreen
        "Mod+F"            = action.fullscreen-window;
        # Lock screen
        "Mod+Shift+L"      = action.spawn "swaylock";
        # Exit niri
        "Mod+Shift+E"      = action.quit;
        # Volume (using wpctl via pipewire)
        "XF86AudioRaiseVolume"  = action.spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
        "XF86AudioLowerVolume"  = action.spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
        "XF86AudioMute"         = action.spawn "wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle";
        # Backlight
        "XF86MonBrightnessUp"   = action.spawn "light" "-A" "5";
        "XF86MonBrightnessDown" = action.spawn "light" "-U" "5";
      };

      # Window layout tweaks
      layout = {
        gaps = 8;
        center-focused-column = "never";
        default-column-width.proportion = 0.5;
        focus-ring = {
          enable = true;
          width  = 2;
          active.color   = "#89b4fa"; # blue (Catppuccin Mocha)
          inactive.color = "#313244";
        };
      };

      # Output configuration — niri auto-detects, but you can be explicit
      # outputs."eDP-1" = {
      #   scale = 1.5;  # increase for HiDPI
      # };

      # Startup applications
      spawn-at-startup = [
        { command = [ "waybar" ]; }
        { command = [ "mako" ]; }
        { command = [ "swaybg" "-i" "~/.config/wallpaper.jpg" "-m" "fill" ]; }
        { command = [ "xwayland-satellite" ]; }  # X11 app support
        {
          command = [
            "swayidle" "-w"
            "timeout" "300"  "swaylock -f"
            "timeout" "600"  "niri msg action power-off-monitors"
            "before-sleep"   "swaylock -f"
          ];
        }
      ];
    };
  };

  # ── tmux ──────────────────────────────────────────────────────────────────

  programs.tmux = {
    enable       = true;
    clock24      = true;
    keyMode      = "vi";
    mouse        = true;
    baseIndex    = 1;          # windows start at 1 not 0
    escapeTime   = 0;          # no ESC delay (important for neovim)
    historyLimit = 50000;
    terminal     = "tmux-256color";
    prefix       = "C-a";      # Ctrl+a instead of Ctrl+b

    extraConfig = ''
      # Better splits — open in current directory
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes with vim keys (hold Ctrl)
      bind -r C-h resize-pane -L 5
      bind -r C-l resize-pane -R 5
      bind -r C-j resize-pane -D 5
      bind -r C-k resize-pane -U 5

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Don't rename windows automatically
      set -g allow-rename off

      # Status bar styling (Catppuccin-inspired, no plugin needed)
      set -g status-position top
      set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
      set -g status-left-length 30
      set -g status-left  '#[fg=#89b4fa,bold] #S  '
      set -g status-right '#[fg=#a6e3a1]%H:%M  #[fg=#89b4fa]%d %b'

      set -g window-status-format         ' #I:#W '
      set -g window-status-current-format '#[fg=#1e1e2e,bg=#89b4fa,bold] #I:#W '

      # True color support
      set -as terminal-features ',tmux-256color:RGB'

      # Pane border styling
      set -g pane-border-style        'fg=#313244'
      set -g pane-active-border-style 'fg=#89b4fa'
    '';

    plugins = with pkgs.tmuxPlugins; [
      # Sane defaults (faster key repeat, etc.)
      sensible

      # Copy to system clipboard in copy mode (yank with 'y')
      yank

      # Save and restore sessions across reboots
      resurrect

      # Auto-save sessions every 15 minutes (pairs with resurrect)
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
  };

  # ── VS Code ───────────────────────────────────────────────────────────────
  # Using Home Manager's vscode module so extensions and settings are declared
  # in your flake — no manual marketplace clicking after a fresh install.

  programs.vscode = {
    enable  = true;
    package = pkgs.vscode; # swap for pkgs.vscodium for the fully open-source build

    # Extensions — sourced from nixpkgs (vscode-extensions.*) or the Open VSX
    # registry via nix-vscode-extensions if you need something not in nixpkgs.
    extensions = with pkgs.vscode-extensions; [
      # Nix
      jnoortheen.nix-ide          # nix language support, syntax, formatting

      # General dev
      eamodio.gitlens             # inline git blame, history explorer
      esbenp.prettier-vscode      # opinionated formatter (JS/TS/JSON/YAML/MD)
      usernamehw.errorlens        # show errors/warnings inline in the editor
      gruntfuggly.todo-tree       # highlights TODO/FIXME comments
      mkhl.direnv                 # auto-load .envrc / nix develop shells in terminal

      # Go (useful for working on masterblaster which is a Go project)
      golang.go

      # Rust
      rust-lang.rust-analyzer  # uses the rust-analyzer binary from dev-tooling.nix

      # Themes
      catppuccin.catppuccin-vsc           # Catppuccin Mocha — matches niri/tmux colors above
      catppuccin.catppuccin-vsc-icons
    ];

    userSettings = {
      # Editor
      "editor.fontFamily"              = "'JetBrainsMono Nerd Font', monospace";
      "editor.fontSize"                = 14;
      "editor.fontLigatures"           = true;
      "editor.lineHeight"              = 1.6;
      "editor.formatOnSave"            = true;
      "editor.defaultFormatter"        = "esbenp.prettier-vscode";
      "editor.minimap.enabled"         = false;
      "editor.renderWhitespace"        = "boundary";
      "editor.cursorBlinking"          = "smooth";
      "editor.smoothScrolling"         = true;

      # Workbench
      "workbench.colorTheme"           = "Catppuccin Mocha";
      "workbench.iconTheme"            = "catppuccin-mocha";
      "workbench.startupEditor"        = "none";
      "workbench.tree.indent"          = 16;

      # Terminal — use tmux inside VS Code's integrated terminal
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "terminal.integrated.fontSize"   = 13;
      "terminal.integrated.shell.linux" = "${pkgs.bash}/bin/bash";

      # Window
      "window.titleBarStyle"           = "custom"; # required for Wayland
      "window.menuBarVisibility"       = "toggle";

      # Files
      "files.autoSave"                 = "onFocusChange";
      "files.trimTrailingWhitespace"   = true;
      "files.insertFinalNewline"       = true;

      # Git
      "git.autofetch"                  = true;
      "git.confirmSync"                = false;

      # Nix IDE
      "nix.enableLanguageServer"       = true;
      "nix.serverPath"                 = "nixd"; # set below in packages

      # Telemetry off
      "telemetry.telemetryLevel"       = "off";
    };
  };

  # ── Shell — bash with useful defaults ────────────────────────────────────
  # Swap for programs.zsh or programs.fish if you prefer

  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    shellAliases = {
      # NixOS rebuild shortcuts
      update  = "sudo nixos-rebuild switch --flake /etc/nixos#framework";
      upgrade = "sudo nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#framework";
      rollback = "sudo nixos-rebuild switch --rollback";
      generations = "nixos-rebuild list-generations";
      # btrfs snapshot before a risky operation
      snap    = "sudo btrbk snapshot";
      # mb (masterblaster) is in systemPackages but alias for clarity
      ls      = "ls --color=auto";
      ll      = "ls -lah --color=auto";
    };
    initExtra = ''
      # Auto-start tmux on terminal open (if not already inside tmux)
      if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
        tmux attach-session -t main 2>/dev/null || tmux new-session -s main
      fi
    '';
  };

  # ── wayvnc config ─────────────────────────────────────────────────────────
  # Declares the wayvnc config file at ~/.config/wayvnc/config
  # Set a password separately (it's not stored in the flake for security):
  #   wayvncpasswd ~/.config/wayvnc/password.ini

  xdg.configFile."wayvnc/config".text = ''
    address=0.0.0.0
    port=5900

    # Enable TLS encryption (recommended if exposing beyond localhost)
    # Generate a self-signed cert:
    #   openssl req -x509 -newkey rsa:4096 -days 3650 \
    #     -keyout ~/.config/wayvnc/tls_key.pem \
    #     -out ~/.config/wayvnc/tls_cert.pem -nodes
    # Then uncomment:
    # enable_auth=true
    # certificate=/home/you/.config/wayvnc/tls_cert.pem
    # private_key=/home/you/.config/wayvnc/tls_key.pem
    # password_file=/home/you/.config/wayvnc/password.ini
  '';

  # ── User packages (installed via Home Manager, not system-wide) ───────────

  home.packages = with pkgs; [
    # Utilities
    ripgrep
    fd
    bat          # better cat
    eza          # better ls (fork of exa)
    fzf          # fuzzy finder
    htop
    btop
    unzip

    # Nix helpers
    nixd         # Nix language server (used by VS Code nix-ide extension above)
    nixfmt-rfc-style  # nix formatter
    nix-tree     # visualise nix store dependencies
    nix-du       # find what's eating disk space in /nix/store
    nvd          # diff between NixOS generations (shows what changed)

    # Wayland utilities
    wl-clipboard
    wev          # Wayland event viewer (useful for finding key names for niri)

    # Notes
    obsidian     # Electron app — uses Wayland natively via NIXOS_OZONE_WL in common.nix
  ];
}
