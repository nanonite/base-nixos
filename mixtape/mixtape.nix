{ pkgs, inputs, ... }:

# ── mixtape.nix — packages baked into every agent sandbox ────────────────────
#
# This NixOS module is applied on top of the base stereOS image.
# Everything listed here is installed at image-build time — zero bootstrap cost
# per `mb up`. Agents start immediately productive.
#
# Build: nix build mixtape/.#mixtape
# Publish: mb mixtape publish agent-workbench:latest ./result
# Use: mb pull agent-workbench:latest  (in each jcard toml)

{
  environment.systemPackages = with pkgs; [

    # ── Agent shell ─────────────────────────────────────────────────────────
    # kaish — constrained, structured, agent-safe shell
    inputs.kaish.packages.${pkgs.system}.default

    # ── tmux (tmux-mcp configured separately) ───────────────────────────────
    # tmux exposes the terminal multiplexer as an MCP server via tmux-mcp.
    # Agents can open panes, run commands, and read output through structured calls.
    # tmux-mcp: check https://github.com/punkpeye/tmux-mcp for install instructions
    # and configure it in the agent's chainlink MCP composition config.
    tmux

    # ── Structural code search ───────────────────────────────────────────────
    # ast-grep understands AST structure — finds/rewrites code patterns, not just text
    ast-grep

    # ── Recursive LM self-reflection ────────────────────────────────────────
    inputs.axon.packages.${pkgs.system}.default

    # ── Rust test runner ────────────────────────────────────────────────────
    # cargo-nextest: faster parallel test execution, better output formatting
    cargo-nextest

    # ── Python analysis stack ────────────────────────────────────────────────
    # marimo: agent-side notebooks for data analysis and benchmark output
    # pyncd is included here once the derivation is written (see agent-framework.nix)
    (python3.withPackages (ps: with ps; [
      marimo
      numpy
      pandas
      polars
      matplotlib
      plotly
      altair

      # pyncd — NCD similarity scoring for RLM layer
      # TODO: add once derivation is verified:
      # pyncd
    ]))

    # ── Standard dev tools every agent needs ────────────────────────────────
    git
    ripgrep
    fd
    jq
    curl

    # ── tilth — code intelligence MCP server ────────────────────────────────
    # TODO: add buildRustPackage derivation once hash is verified (see agent-framework.nix)

    # ── Monolith — RLM reward signal ────────────────────────────────────────
    # TODO: add buildRustPackage derivation once hash is verified (see agent-framework.nix)

  ];

  # crosslink (cross-process shared memory, planner ↔ sandboxes) is a library —
  # no standalone binary derivation needed. It's a Cargo dependency in consuming crates.
}
