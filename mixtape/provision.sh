#!/usr/bin/env bash
# provision.sh — install custom agent tools into a coder-x86 sandbox
#
# Run once inside the VM after `mb up`:
#   mb ssh -- bash /workspace/mixtape/provision.sh
#
# Tools from nixpkgs are handled via extraPackages in jcard.toml.
# This script installs the custom tools that aren't in nixpkgs.

set -euo pipefail

FLAKE="github:nanonite/base-nixos/framework-agent"

echo "==> Installing agent tools from $FLAKE"

nix profile install "$FLAKE#axon"          # recursive LM reasoning (MCP server)
nix profile install "$FLAKE#tilth"         # AST-aware code intelligence (MCP server)
nix profile install "$FLAKE#context-mode"  # context window indexer (MCP server)
nix profile install "$FLAKE#chainlink"     # local task/issue tracker

echo "==> Done. Verify with: axon --version && tilth --help && chainlink --version"
