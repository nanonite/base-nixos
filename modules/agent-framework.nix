{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

# ── agent-framework.nix — agentic coding platform ─────────────────────────────
#
# Installs and configures all orchestration tools for the AI coding framework.
# Loaded on every host (framework, desktop, embedded) via mkSystem in flake.nix.
#
# Custom tool derivations live in pkgs/ (overlay applied in flake.nix).
# Tools are uncommented here as their pkgs/ derivations are verified to build.
#
{
  options.agentFramework = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the agentic coding framework tools on this host.";
    };

    benchmarkMode = lib.mkEnableOption ''
      benchmark mode — dispatches each task to Gemini, Claude, and opencode in
      parallel. Results are written to ./benchmark-results/ and compared in the
      Marimo dashboard. Toggle without rebuild via BENCHMARK_MODE=1 env var.
    '';

    codexAuth.enable = lib.mkEnableOption ''
      Codex auth.json restoration from the codex_auth_json sops secret.
      Enable only after adding that secret to secrets.yaml.
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

        # bun — fast JS/TS runtime; agents may generate and execute JS/TS scripts.
        # Also satisfies context-mode's "install bun for faster JS/TS" tip.
        bun

        # codex — OpenAI coding agent CLI
        codex

        # ── Custom derivations from pkgs/ overlay ────────────────────────────────
        # Workflow to activate each tool:
        #   1. nix build .#<tool> 2>&1 | grep "got:"   ← get correct hashes
        #   2. Fill hashes in pkgs/<tool>.nix
        #   3. Uncomment the line below
        #
        # tilth — code intelligence MCP server (AST-aware symbol search, file read)
        # Registered globally in ~/.claude.json (home.nix activation).
        # For spawned agents: add to each project's .exo/config.toml:
        #   [extra_mcp_servers.tilth]
        #   type    = "stdio"
        #   command = "tilth"
        #   args    = ["--mcp"]
        pkgs.tilth

        # tracey — structured observability for agent runs
        pkgs.tracey

        # kaish — constrained agent shell (agent-safe, structured I/O)
        pkgs.kaish

        # context-mode — context window manager (per-agent + planner preambles)
        # NOTE: context-mode hooks conflict with exomonad hooks. Disable/unload
        # context-mode before running exomonad init in a project session.
        pkgs."context-mode"

        # chainlink — CLI issue tracker with MCP tools (issues, sub-issues, milestones)
        # Planner stage writes tasks here; exomonad agents consume via chainlink MCP tools.
        # Hook conflict: chainlink Claude Code hooks conflict with exomonad hooks — keep
        # chainlink hooks disabled; use exomonad hooks when in an exomonad session.
        pkgs.chainlink

        # exomonad — agent orchestration (Rust binary + Haskell WASM plugins)
        # Extra tools for agents go in per-project .exo/config.toml, not here.
        # Grafana Tempo observability companion example:
        #   [[companions]]
        #   name         = "tempo"
        #   agent_type   = "process"
        #   command      = "docker compose -f .exo/otel/docker-compose.yml up"
        pkgs.exomonad

        # opencode — AI coding agent (TypeScript, anomalyco)
        pkgs.opencode

        # docker-sbx — Docker Sandboxes host CLI/runtime for pwa-sandbox workflows
        pkgs.docker-sbx

        # ── Not binary tools — installed differently ─────────────────────────────
        # learning-opportunities — Claude Code plugin:
        #   claude plugin marketplace add https://github.com/DrCatHicks/learning-opportunities.git
        #   Belongs in planner agent config, NOT in agent sandboxes (see updated_plan.md)
        #
        # monolith-rlm (deeprecurse) — Python library, no CLI entry points, no derivation
        # pyncd — research notebooks only, no package structure, no derivation

      ];

      security.apparmor = {
        enable = true;
        policies.docker-sbx-nerdbox-shim.path =
          "${pkgs.docker-sbx}/etc/apparmor.d/docker-sbx-nerdbox-shim";
      };

    })

    # ── Benchmark mode — runtime toggle, no rebuild needed ──────────────────────
    (lib.mkIf config.agentFramework.benchmarkMode {
      environment.sessionVariables.EXOMONAD_BENCHMARK = "1";
    })

  ];
}
