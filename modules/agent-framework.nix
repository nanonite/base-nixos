{ lib, pkgs, config, inputs, ... }:

# ── agent-framework.nix — agentic coding platform ─────────────────────────────
#
# Installs and configures all orchestration tools for the AI coding framework.
# Loaded on every host (framework, desktop, embedded) via mkSystem in flake.nix.
#
# Key responsibilities:
#   - Install planner-side tools: exomonad, chainlink, go-jira
#   - Expose benchmark mode toggle (NixOS option + env var)
#   - Stub deferred integrations (token-monitor, lolearn) so integration points
#     are obvious when the time comes
#
# IMPORTANT — before first build, verify flake outputs for all agent inputs:
#   nix flake show github:dollspace-gay/chainlink
#   nix flake show github:tidepool-heavy-industries/exomonad
#   nix flake show github:Diogenesoftoronto/axon
#   nix flake show github:tobert/kaish
#   nix flake show github:mksglu/context-mode
#   nix flake show github:bearcove/tracey
# If any lack packages.${system}.default, fall back to buildRustPackage/buildGoPackage.

{
  options.agentFramework = {
    enable = lib.mkOption {
      type        = lib.types.bool;
      default     = true;
      description = "Enable the agentic coding framework tools on this host.";
    };

    benchmarkMode = lib.mkEnableOption ''
      benchmark mode — dispatches each task to Gemini, Claude, and opencode in
      parallel. Results are written to ./benchmark-results/ and compared in the
      Marimo dashboard. Toggle without rebuild via BENCHMARK_MODE=1 env var.
    '';
  };

  config = lib.mkMerge [

    # ── Main config block (always on when agentFramework.enable is true) ────────
    (lib.mkIf config.agentFramework.enable {

      environment.systemPackages = with pkgs; [

        # ── Planner / orchestration ─────────────────────────────────────────────

        # exomonad — routes tasks from Opus planner to agent sandboxes
        # Reads planner/exomonad.toml for routing rules and agent role declarations
        inputs.exomonad.packages.${pkgs.system}.default

        # chainlink — composes multiple MCP servers into a unified agent tool surface
        # Config lives in home/home.nix (chainlink stanza) and per-agent jcard toml
        inputs.chainlink.packages.${pkgs.system}.default

        # go-jira — JIRA CLI for task lifecycle management
        # Planner creates/updates issues; config in planner/jira-config.yaml
        go-jira

        # ── Agent sandbox tools (also pre-baked into mixtape) ───────────────────

        # axon — recursive LM self-reflection engine
        inputs.axon.packages.${pkgs.system}.default

        # kaish — constrained agent shell (agent-safe, structured I/O)
        inputs.kaish.packages.${pkgs.system}.default

        # context-mode — context window manager (per-agent + planner preambles)
        inputs.context-mode.packages.${pkgs.system}.default

        # tracey — tracing / structured observability for agent runs
        inputs.tracey.packages.${pkgs.system}.default

        # ast-grep — structural code search/rewrite (AST-aware, not regex)
        ast-grep

        # ── tilth — code intelligence MCP server ────────────────────────────────
        # Source: crates.io/crates/tilth (no flake output — buildRustPackage)
        # TODO: fill in version and hash once verified:
        #
        # (pkgs.rustPlatform.buildRustPackage {
        #   pname   = "tilth";
        #   version = "0.1.0"; # check crates.io for latest
        #   src     = pkgs.fetchCrate {
        #     pname  = "tilth";
        #     version = "0.1.0";
        #     hash   = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        #   };
        #   cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        # })

        # ── Monolith — RLM reward signal ────────────────────────────────────────
        # Source: github:WingchunSiu/Monolith (no flake output — buildRustPackage)
        # TODO: fill in rev and hashes once verified:
        #
        # (pkgs.rustPlatform.buildRustPackage {
        #   pname   = "monolith";
        #   version = "0.1.0";
        #   src     = pkgs.fetchFromGitHub {
        #     owner  = "WingchunSiu";
        #     repo   = "Monolith";
        #     rev    = "main"; # pin to a specific commit
        #     hash   = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        #   };
        #   cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        # })

        # ── pyncd — NCD similarity scoring ──────────────────────────────────────
        # Source: github:mit-zardini-lab/pyncd (no flake output — buildPythonPackage)
        # Check if it's on PyPI first (`pip index versions pyncd`) — if so, use
        # pkgs.python3Packages.pyncd (may already be in nixpkgs).
        # TODO: fill in hash once verified:
        #
        # (pkgs.python3Packages.buildPythonPackage {
        #   pname   = "pyncd";
        #   version = "0.1.0";
        #   src     = pkgs.fetchFromGitHub {
        #     owner  = "mit-zardini-lab";
        #     repo   = "pyncd";
        #     rev    = "main"; # pin to a specific commit
        #     hash   = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        #   };
        #   format = "pyproject"; # or "setuptools" depending on the project
        # })

      ];

      # ── TOKEN MONITOR — deferred ─────────────────────────────────────────────
      # Integrate after core NixOS architecture is proven.
      # When ready: add ANTHROPIC_BASE_URL proxy, wire ledger to Marimo dashboard.
      #
      # services.token-monitor = {
      #   enable      = true;
      #   proxyPort   = 9999;
      #   ledgerPath  = "/var/lib/token-monitor";
      # };
      #
      # And add to each jcard secrets:
      #   ANTHROPIC_BASE_URL = "http://localhost:9999"

    })

    # ── Benchmark mode — runtime toggle, no rebuild needed ──────────────────────
    (lib.mkIf config.agentFramework.benchmarkMode {
      environment.sessionVariables.EXOMONAD_BENCHMARK = "1";
    })

  ];
}
