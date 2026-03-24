# pkgs/default.nix — custom overlay for agent framework tools
#
# All upstream repos exist on GitHub but lack Nix flake outputs.
# Derivations are added one at a time as they are verified to build.
# Apply this overlay in flake.nix and mixtape/flake.nix.
#
# Usage in flake.nix:
#   nixpkgs.overlays = [ rust-overlay.overlays.default (import ./pkgs/default.nix) ];

final: prev: {

  # ── Tools added incrementally (uncomment after derivation is verified) ──────

  # tilth — code intelligence MCP server (crates.io/crates/tilth)
  # tilth = final.callPackage ./tilth.nix {};

  # tracey — structured observability for agent runs (github:bearcove/tracey)
  # tracey = final.callPackage ./tracey.nix {};

  # kaish — constrained agent shell (github:tobert/kaish)
  # kaish = final.callPackage ./kaish.nix {};

  # axon — recursive LM self-reflection engine (github:Diogenesoftoronto/axon)
  # axon = final.callPackage ./axon.nix {};

  # context-mode — context window manager (github:mksglu/context-mode)
  # context-mode = final.callPackage ./context-mode.nix {};

  # chainlink — MCP server composition (github:dollspace-gay/chainlink)
  # chainlink = final.callPackage ./chainlink.nix {};

  # exomonad — task orchestration router (github:tidepool-heavy-industries/exomonad)
  # exomonad = final.callPackage ./exomonad.nix {};

  # learning-opportunities — (github:DrCatHicks/learning-opportunities)
  # learning-opportunities = final.callPackage ./learning-opportunities.nix {};

  # monolith-rlm — RLM reward signal (github:WingchunSiu/Monolith)
  # monolith-rlm = final.callPackage ./monolith.nix {};

  # pyncd — NCD similarity scoring (github:mit-zardini-lab/pyncd)
  # pyncd = final.python3Packages.callPackage ./pyncd.nix {};

}
