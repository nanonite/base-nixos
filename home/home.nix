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
      binds = {
        # Terminal
        "Mod+Return".action.spawn            = "foot";
        # App launcher
        "Mod+D".action.spawn                 = "fuzzel";
        # Close window
        "Mod+Q".action.close-window          = {};
        # Focus windows
        "Mod+H".action.focus-column-left     = {};
        "Mod+L".action.focus-column-right    = {};
        "Mod+J".action.focus-window-down     = {};
        "Mod+K".action.focus-window-up       = {};
        # Move windows
        "Mod+Shift+H".action.move-column-left  = {};
        "Mod+Shift+L".action.move-column-right = {};
        # Workspaces
        "Mod+1".action.focus-workspace       = 1;
        "Mod+2".action.focus-workspace       = 2;
        "Mod+3".action.focus-workspace       = 3;
        "Mod+4".action.focus-workspace       = 4;
        "Mod+5".action.focus-workspace       = 5;
        "Mod+Shift+1".action.move-window-to-workspace = 1;
        "Mod+Shift+2".action.move-window-to-workspace = 2;
        "Mod+Shift+3".action.move-window-to-workspace = 3;
        # Screenshot
        "Print".action.screenshot            = {};
        "Mod+Print".action.screenshot-screen = {};
        # Fullscreen
        "Mod+F".action.fullscreen-window     = {};
        # Lock screen
        "Mod+Shift+S".action.spawn           = "swaylock";
        # Exit niri
        "Mod+Shift+E".action.quit            = {};
        # Volume (using wpctl via pipewire)
        "XF86AudioRaiseVolume".action.spawn  = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
        "XF86AudioLowerVolume".action.spawn  = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
        "XF86AudioMute".action.spawn         = ["wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle"];
        # Backlight
        "XF86MonBrightnessUp".action.spawn   = ["light" "-A" "5"];
        "XF86MonBrightnessDown".action.spawn = ["light" "-U" "5"];
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
  # Disabled for initial install — vscode requires allowUnfree.
  # Re-enable after adding nixpkgs.config.allowUnfree = true to your config.
  # programs.vscode = { ... };

  # ── Shell — bash with useful defaults ────────────────────────────────────
  # Swap for programs.zsh or programs.fish if you prefer

  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    shellAliases = {
      # NixOS rebuild shortcuts
      update     = "sudo nixos-rebuild switch --flake /etc/nixos#framework";
      upgrade    = "sudo nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#framework";
      rollback   = "sudo nixos-rebuild switch --rollback";
      generations = "nixos-rebuild list-generations";

      # btrfs snapshot before a risky operation
      snap       = "sudo btrbk snapshot";

      # ls improvements
      ls         = "ls --color=auto";
      ll         = "ls -lah --color=auto";

      # ── Agent orchestration ──────────────────────────────────────────────
      # Normal mode — one agent per task
      agent-gemini  = "mb up --config /etc/nixos/agent-sandbox/jcard-gemini.toml";
      agent-claude  = "mb up --config /etc/nixos/agent-sandbox/jcard-claude.toml";
      agent-open    = "mb up --config /etc/nixos/agent-sandbox/jcard-opencode.toml";

      # Benchmark mode — all agents in parallel for the same task
      benchmark     = "BENCHMARK_MODE=1 mb up --config /etc/nixos/agent-sandbox/jcard-benchmark.toml";

      # Marimo dashboard
      dashboard     = "marimo run /etc/nixos/planner/dashboard.py";
      dashboard-edit = "marimo edit /etc/nixos/planner/dashboard.py";

      # JIRA shortcuts (go-jira)
      jl            = "jira issue list --project \${JIRA_PROJECT:-MYPROJ} --status 'In Progress'";
      jc            = "jira issue create --project \${JIRA_PROJECT:-MYPROJ}";
      jt            = "jira issue transition";

      # Mixtape build + publish
      mixtape-build = "nix build /etc/nixos/mixtape/.#mixtape";
      mixtape-pub   = "mb mixtape publish agent-workbench:latest ./result";
    };
    initExtra = ''
      # Auto-start tmux on terminal open (if not already inside tmux)
      if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
        tmux attach-session -t main 2>/dev/null || tmux new-session -s main
      fi
    '';
  };

  # ── go-jira config ────────────────────────────────────────────────────────
  # go-jira reads ~/.jira.d/config.yml for per-user overrides.
  # Project-level config lives in planner/jira-config.yaml.
  # Set JIRA_API_TOKEN and JIRA_PROJECT in your shell environment (not committed).

  xdg.configFile."jira/config.yml".text = ''
    # go-jira user config — overrides planner/jira-config.yaml
    # Set your actual values below or via environment variables.
    endpoint: https://yourorg.atlassian.net
    login: your-email@example.com
    project: MYPROJ
    authentication-method: api-token
  '';

  # ── chainlink config — MCP server composition ──────────────────────────────
  # chainlink composes multiple MCP servers into a single tool surface for agents.
  # Agents reference this config to get: tilth, tmux-mcp, and any other MCP tools.
  # See: github:dollspace-gay/chainlink for full config schema.

  xdg.configFile."chainlink/config.toml".text = ''
    # chainlink — unified MCP server composition for agent tool surface

    # tilth — code intelligence: symbol search, file reading, AST-aware navigation
    [[server]]
    name    = "tilth"
    command = ["tilth", "serve"]
    # tilth reads the project directory automatically from the working dir

    # tmux-mcp — exposes tmux as an MCP server
    # Agents can open panes, run commands, read output via structured MCP calls
    # [[server]]
    # name    = "tmux"
    # command = ["tmux-mcp"]   # uncomment once tmux-mcp is installed

    # Future MCP servers: add [[server]] blocks here as they become available
  '';

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
    # obsidian  # unfree — install manually after adding allowUnfree = true
  ];
}
