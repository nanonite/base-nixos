# pkgs/default.nix — custom overlay for agent framework tools
#
# All upstream repos exist on GitHub but lack Nix flake outputs.
# Derivations are written here and activated incrementally:
#   1. Run: nix build .#<tool> 2>&1 | grep "got:"   (on laptop, fills in hashes)
#   2. Replace fake hashes in pkgs/<tool>.nix with the "got:" values
#   3. Uncomment pkgs.<tool> in modules/agent-framework.nix
#
# This overlay is lazy — tools are only built when referenced in active config.
# All tools are exposed here so `nix build .#<tool>` works for hash-filling.
#
# Not included (not binary tools):
#   learning-opportunities — Claude Code plugin, install via: claude plugin install
#   monolith-rlm           — Python library "deeprecurse", no entry points
#   pyncd                  — Research notebooks, no package structure

final: prev: {

  # masterblaster (mb) — stereOS AI agent sandbox manager (Go)
  masterblaster = final.callPackage ./masterblaster.nix {};

  # tilth — code intelligence MCP server (Rust, crates.io)
  tilth = final.callPackage ./tilth.nix {};

  # kaish — constrained agent shell (Rust)
  kaish = final.callPackage ./kaish.nix {};

  # axon — recursive LM self-reflection engine (Rust)
  axon = final.callPackage ./axon.nix {};

  # tracey — structured observability for agent runs (Rust workspace)
  tracey = final.callPackage ./tracey.nix {};

  # chainlink — MCP server composition (Rust, chainlink/ subdir)
  chainlink = final.callPackage ./chainlink.nix {};

  # exomonad — task orchestration router (Rust, rust/ subdir, WIP upstream)
  exomonad = final.callPackage ./exomonad.nix {};

  # context-mode — context window manager (TypeScript, pre-bundled, Node.js wrapper)
  context-mode = final.callPackage ./context-mode.nix {};

}
