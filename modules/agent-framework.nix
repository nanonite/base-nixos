{ lib, pkgs, config, inputs, ... }:

# ── agent-framework.nix — agentic coding platform ─────────────────────────────
#
# Installs and configures all orchestration tools for the AI coding framework.
# Loaded on every host (framework, desktop, embedded) via mkSystem in flake.nix.
#
# Custom tool derivations live in pkgs/ (overlay applied in flake.nix).
# Tools are uncommented here as their pkgs/ derivations are verified to build.
#
# Deferred (stubs only):
#   token-monitor — integrate after core architecture is proven
#   lolearn       — integrate after core architecture is proven

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

        # ── Already in nixpkgs ───────────────────────────────────────────────────

        # go-jira — JIRA CLI for task lifecycle management
        # Planner creates/updates issues; config in planner/jira-config.yaml
        go-jira

        # ast-grep — structural code search/rewrite (AST-aware, not regex)
        ast-grep

        # ── Custom derivations from pkgs/ overlay ────────────────────────────────
        # Workflow to activate each tool:
        #   1. nix build .#<tool> 2>&1 | grep "got:"   ← get correct hashes
        #   2. Fill hashes in pkgs/<tool>.nix
        #   3. Uncomment the line below
        #
        # masterblaster (mb) — stereOS AI agent sandbox manager
        # pkgs.masterblaster

        # tilth — code intelligence MCP server
        # pkgs.tilth

        # tracey — structured observability for agent runs
        # pkgs.tracey

        # kaish — constrained agent shell (agent-safe, structured I/O)
        # pkgs.kaish

        # axon — recursive LM self-reflection engine
        # pkgs.axon

        # context-mode — context window manager (per-agent + planner preambles)
        # pkgs."context-mode"

        # chainlink — composes multiple MCP servers into a unified tool surface
        # Config: home/home.nix (chainlink stanza) and per-agent jcard toml
        # pkgs.chainlink

        # exomonad — routes tasks from Opus planner to agent sandboxes
        # Config: planner/exomonad.toml
        # NOTE: rust/exomonad/src/ was empty upstream as of 2026-03-24 — verify before enabling
        # pkgs.exomonad

        # ── Not binary tools — installed differently ─────────────────────────────
        # learning-opportunities — Claude Code plugin:
        #   claude plugin marketplace add https://github.com/DrCatHicks/learning-opportunities.git
        #   Belongs in planner agent config, NOT in agent sandboxes (see updated_plan.md)
        #
        # monolith-rlm (deeprecurse) — Python library, no CLI entry points, no derivation
        # pyncd — research notebooks only, no package structure, no derivation

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
