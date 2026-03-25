{ pkgs, ... }:

# ── mixtape.nix — packages baked into every agent sandbox ────────────────────
#
# This NixOS module is applied on top of the base stereOS image.
# Everything listed here is installed at image-build time — zero bootstrap cost
# per `mb up`. Agents start immediately productive.
#
# Build: nix build mixtape/.#mixtape
# Publish: mb mixtape publish agent-workbench:latest ./result
# Use: mb pull agent-workbench:latest  (in each jcard toml)
#
# Custom tools come from the pkgs/ overlay (applied in mixtape/flake.nix).
# Uncomment each tool after filling in its hashes in pkgs/<tool>.nix.

{
  environment.systemPackages = with pkgs; [

    # ── Agent shell ──────────────────────────────────────────────────────────
    # kaish — constrained, structured, agent-safe shell
    # pkgs.kaish   # uncomment after filling hashes in pkgs/kaish.nix

    # ── tmux (tmux-mcp configured separately) ────────────────────────────────
    # tmux exposes the terminal multiplexer as an MCP server via tmux-mcp.
    # Agents can open panes, run commands, and read output through structured calls.
    # tmux-mcp: https://github.com/punkpeye/tmux-mcp — configure in chainlink MCP config
    tmux

    # ── Structural code search ────────────────────────────────────────────────
    # ast-grep understands AST structure — finds/rewrites code patterns, not regex
    ast-grep

    # ── Recursive LM self-reflection ─────────────────────────────────────────
    # pkgs.axon   # uncomment after filling hashes in pkgs/axon.nix

    # ── Code intelligence MCP server ─────────────────────────────────────────
    # pkgs.tilth  # uncomment after filling hashes in pkgs/tilth.nix

    # ── Rust test runner ──────────────────────────────────────────────────────
    # cargo-nextest: faster parallel test execution, better output formatting
    cargo-nextest

    # ── Python analysis stack ─────────────────────────────────────────────────
    # marimo: agent-side notebooks for data analysis and benchmark output
    (python3.withPackages (ps: with ps; [
      marimo
      numpy
      pandas
      polars
      matplotlib
      plotly
      altair
    ]))

    # ── Standard dev tools every agent needs ─────────────────────────────────
    git
    ripgrep
    fd
    jq
    curl

  ];

  # crosslink (cross-process shared memory, planner ↔ sandboxes) is a library —
  # no standalone binary derivation needed. It's a Cargo dependency in consuming crates.
}
