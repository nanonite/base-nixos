{ inputs, pkgs, lib, ... }:

{
  imports = [
    inputs.niri.homeModules.niri    # provides config.lib.niri.actions (needed by DMS)
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];
  home.username = "you";        # change to your actual username
  home.homeDirectory = "/home/you"; # change accordingly

  # Match this to system.stateVersion in common.nix — do NOT change after first install
  home.stateVersion = "25.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # ── niri Wayland compositor config ────────────────────────────────────────
  # The niri HM module manages ~/.config/niri/config.kdl declaratively.
  # DMS manages layout, colors, outputs via includes at runtime.
  #
  # KEYBINDINGS NOTE:
  # DMS window management keybindings (focus, move, workspaces, terminal, etc.)
  # are NOT set by enableKeybinds — that only covers DMS panel/launcher shortcuts.
  # Niri bindings live in ~/.config/niri/dms/binds.kdl, written by DMS at runtime
  # via: dms keybinds set niri "Mod+Key" "action" --desc "..."
  # Or via the GUI: Mod+Comma → Keyboard Shortcuts Editor
  #
  # We intentionally do NOT manage binds.kdl via home-manager because that would
  # make it a read-only symlink and break DMS's GUI editor.
  # After configuring keybindings on a machine, back up the file:
  #   cp ~/.config/niri/dms/binds.kdl ~/nix-workspace/hosts/framework/binds.kdl.bak

  # ── DankMaterialShell ─────────────────────────────────────────────────────
  programs.dank-material-shell = {
    enable = true;
    enableSystemMonitoring = true;
    enableVPN              = true;
    enableDynamicTheming   = true;
    enableAudioWavelength  = true;
    enableCalendarEvents   = true;  # khal build was fixed in nixpkgs after Feb 28 2026
    enableClipboardPaste   = true;
    systemd = {
      enable = true;           # run DMS as a systemd user service (generates config files before niri reads them)
      restartIfChanged = true;
    };
    niri.enableKeybinds = true;
  };

  # ── tmux ──────────────────────────────────────────────────────────────────

  # ── Atuin — shell history with Ctrl+R ─────────────────────────────────────
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      show_preview = true;
    };
  };

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

      # True color support — target xterm-kitty (what kitty sets $TERM to)
      set -as terminal-features ",xterm-kitty:RGB"

      # Undercurl / colored underlines (requires tmux 3.0+, supported by kitty natively)
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

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

  # ── Kitty terminal ────────────────────────────────────────────────────────
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 14;
    };

    # Disable title/cursor shape changes — tmux intercepts these OSC codes
    shellIntegration.mode = "no-title no-cursor";
    shellIntegration.enableBashIntegration = true;

    settings = {
      window_padding_width    = 8;
      confirm_os_window_close = 0;
      enable_audio_bell       = false;
      scrollback_lines        = 10000;
      repaint_delay           = 10;
      sync_to_monitor         = true;
    };
  };

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

  # ── chainlink config ─────────────────────────────────────────────────────
  # chainlink is the task database: issues, sub-issues, milestones, labels.
  # Planner agents decompose goals here; exomonad workers read/update via MCP.
  # See: github:dollspace-gay/chainlink for full config schema.

  xdg.configFile."chainlink/config.toml".text = ''
    # chainlink — task database config for agent framework

    # tilth — code intelligence: symbol search, file reading, AST-aware navigation
    [[server]]
    name    = "tilth"
    command = ["tilth", "serve"]

    # tmux-mcp — exposes tmux as an MCP server (uncomment once installed)
    # [[server]]
    # name    = "tmux"
    # command = ["tmux-mcp"]
  '';

  xdg.configFile."jira/config.yml".text = ''
    # go-jira user config — overrides planner/jira-config.yaml
    # Set your actual values below or via environment variables.
    endpoint: https://yourorg.atlassian.net
    login: your-email@example.com
    project: MYPROJ
    authentication-method: api-token
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

  # ── exomonad WASM plugins ─────────────────────────────────────────────────
  # exomonad looks for WASM in ~/.exo/wasm/ as its global fallback.
  # Symlink the Nix-built plugins there so `exomonad new/init` finds them
  # without manual setup. Updated automatically on nixos-rebuild.
  home.activation.exomonadWasm = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.exo/wasm"
    for f in ${pkgs.exomonad}/share/exomonad/wasm/*.wasm; do
      ln -sf "$f" "$HOME/.exo/wasm/$(basename $f)"
    done
  '';

  # ── Claude Code global MCP servers ────────────────────────────────────────
  # Registers agent tools globally in ~/.claude.json so every Claude Code
  # session (planner + all fork_wave spawned agents) has them available.
  # Runs after each nixos-rebuild. tilth path is always overwritten because the
  # nix store hash changes on rebuild — a stale path silently breaks the MCP server.
  # ~/.claude.json must already exist (created on first `claude` launch).
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_JSON="$HOME/.claude.json"
    JQ="${pkgs.jq}/bin/jq"

    if [ -f "$CLAUDE_JSON" ]; then
      # Always overwrite — store hash changes on every rebuild, stale path = silent failure
      $JQ '.mcpServers.tilth = {"command": "${pkgs.tilth}/bin/tilth", "args": ["--mcp"]}' \
        "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    fi
  '';

  # ── Claude Code context-mode plugin ───────────────────────────────────────
  # Installs the context-mode Claude Code plugin declaratively from the Nix
  # store — no marketplace download required on a fresh machine.
  # Symlinks the plugin tree into the cache path Claude Code expects, then
  # patches installed_plugins.json and settings.json to register it.
  home.activation.claudeContextModePlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    JQ="${pkgs.jq}/bin/jq"
    PLUGIN_SRC="${pkgs."context-mode"}/share/context-mode/plugin"
    PLUGIN_VER="1.0.53"
    PLUGIN_KEY="context-mode@context-mode"
    CACHE_DIR="$HOME/.claude/plugins/cache/context-mode/context-mode/$PLUGIN_VER"
    INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"
    SETTINGS_JSON="$HOME/.claude/settings.json"

    # Symlink plugin tree into Claude Code's cache path
    mkdir -p "$(dirname "$CACHE_DIR")"
    if [ ! -L "$CACHE_DIR" ] || [ "$(readlink "$CACHE_DIR")" != "$PLUGIN_SRC" ]; then
      ln -sfn "$PLUGIN_SRC" "$CACHE_DIR"
    fi

    # Register in installed_plugins.json (create file if absent)
    if [ ! -f "$INSTALLED_JSON" ]; then
      echo '{}' > "$INSTALLED_JSON"
    fi
    if ! $JQ -e --arg k "$PLUGIN_KEY" '.[$k]' "$INSTALLED_JSON" > /dev/null 2>&1; then
      $JQ --arg k "$PLUGIN_KEY" --arg path "$CACHE_DIR" --arg ver "$PLUGIN_VER" \
        '.[$k] = [{"scope":"user","installPath":$path,"version":$ver,"installedAt":"1970-01-01T00:00:00.000Z","lastUpdated":"1970-01-01T00:00:00.000Z","gitCommitSha":"316e0de2c11d166246dea83f787472236eb57207"}]' \
        "$INSTALLED_JSON" > "$INSTALLED_JSON.tmp" && mv "$INSTALLED_JSON.tmp" "$INSTALLED_JSON"
    fi

    # Register in settings.json (create file if absent)
    if [ ! -f "$SETTINGS_JSON" ]; then
      echo '{}' > "$SETTINGS_JSON"
    fi
    if ! $JQ -e --arg k "$PLUGIN_KEY" '.enabledPlugins[$k]' "$SETTINGS_JSON" > /dev/null 2>&1; then
      $JQ --arg k "$PLUGIN_KEY" \
        '.enabledPlugins[$k] = true
         | .extraKnownMarketplaces["context-mode"] = {"source":{"source":"github","repo":"mksglu/context-mode"}}' \
        "$SETTINGS_JSON" > "$SETTINGS_JSON.tmp" && mv "$SETTINGS_JSON.tmp" "$SETTINGS_JSON"
    fi
  '';

  # ── User packages (installed via Home Manager, not system-wide) ───────────

  home.packages = with pkgs; [
    # Browser
    firefox

    # Notes
    obsidian

    # AI tooling
    claude-code

    # Password manager
    bitwarden-desktop
    bitwarden-cli

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
    grimblast    # screenshot helper (wraps grim+slurp, auto-names files)

    # Image & document viewers
    imv          # lightweight Wayland image viewer
    evince       # PDF viewer

    # Creative
    blender

    # AI tooling
    claude-code  # unfree — DISABLE_AUTOUPDATER=1 is set automatically by nixpkgs wrapper

    # Password manager
    bitwarden-desktop
    bitwarden-cli   # `bw` command for scripting / terminal access

    # Notes
    obsidian  # unfree — allowUnfree enabled
  ];

  # ── Screenshot desktop entry (shows in fuzzel app list) ──────────────────


  # ── niri extra keybinds ────────────────────────────────────────────────────
  programs.niri.settings.binds = {
    "Print".action.spawn = [ "sh" "-c" "mkdir -p ~/ Pictures && grim -g \"$(slurp)\" ~/Pictures/$(date +%Y%m%d_%H%M%S).png" ];
  };

  # ── VSCode ────────────────────────────────────────────────────────────────
  programs.vscode = {
    enable  = true;
    package = pkgs.vscode;  # FHS chroot — needed for extensions that download pre-compiled binaries
    profiles.default.userSettings = {
      "claudeCode.claudeProcessWrapper" = "/etc/profiles/per-user/framework/bin/claude";
    };
  };
}
