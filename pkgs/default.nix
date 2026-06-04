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

{ ghc-wasm-meta }:

final: prev: {

  # masterblaster (mb) — stereOS AI agent sandbox manager (Go)
  # REMOVED from active config: no x86_64 binary available upstream.
  # Kept here for hash-filling workflow if/when x86 support lands.
  masterblaster = final.callPackage ./masterblaster.nix { };

  # tilth — code intelligence MCP server (Rust, crates.io)
  tilth = final.callPackage ./tilth.nix { };

  # kaish — constrained agent shell (Rust)
  kaish = final.callPackage ./kaish.nix { };

  # tracey — structured observability for agent runs (Rust + Vite dashboard)
  tracey = final.callPackage ./tracey.nix { };

  # chainlink — CLI issue tracker + MCP server (issues, sub-issues, milestones, labels)
  # SQLite at .chainlink/issues.db — planner stage writes here, exomonad agents read/update
  chainlink = final.callPackage ./chainlink.nix { };

  # exomonad-wasm — Haskell WASM plugins (FOD, built with GHC 9.12 wasm32-wasi)
  exomonadWasm = final.callPackage ./exomonad-wasm.nix {
    wasmToolchain = ghc-wasm-meta.packages.${final.stdenv.hostPlatform.system}.all_9_12;
  };

  # exomonad — task orchestration router (Rust binary; WASM injected via callPackage)
  exomonad = final.callPackage ./exomonad.nix { };

  # context-mode — context window manager (TypeScript, pre-bundled, Node.js wrapper)
  context-mode = final.callPackage ./context-mode.nix { };

  # docker-sbx — Docker Sandboxes host CLI/runtime used by pwa-sandbox workflows
  docker-sbx = final.callPackage ./docker-sbx.nix { };

  # codex — local override to pin a newer release than the current nixpkgs input
  codex = final.callPackage ./codex.nix { };

}
