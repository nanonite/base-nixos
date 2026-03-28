# context-mode — context window manager (per-agent + planner preambles)
# Source: github:mksglu/context-mode (TypeScript/Bun, pre-bundled .mjs)
# Exposes:
#   $out/bin/context-mode          — CLI MCP server (wraps cli.bundle.mjs)
#   $out/share/context-mode/plugin — full plugin tree for Claude Code plugin system
#
# No Nix build tooling needed — the bundled JS is committed to the repo.
# node_modules is NOT needed: the .bundle.mjs files are fully self-contained.

{ stdenv, fetchFromGitHub, nodejs, makeWrapper }:

stdenv.mkDerivation {
  pname   = "context-mode";
  version = "1.0.53";

  src = fetchFromGitHub {
    owner = "mksglu";
    repo  = "context-mode";
    rev   = "316e0de2c11d166246dea83f787472236eb57207"; # v1.0.53
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # refill: nix build .#context-mode 2>&1 | grep "got:"
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    # CLI binary
    mkdir -p $out/lib/context-mode $out/bin
    cp cli.bundle.mjs $out/lib/context-mode/
    makeWrapper ${nodejs}/bin/node $out/bin/context-mode \
      --add-flags "$out/lib/context-mode/cli.bundle.mjs"

    # Full plugin tree for the Claude Code plugin system.
    # Claude Code loads from the installPath in installed_plugins.json;
    # home.activation symlinks this into ~/.claude/plugins/cache/.
    # node_modules is absent by design — bundles are self-contained.
    mkdir -p $out/share/context-mode/plugin
    cp -r . $out/share/context-mode/plugin/
  '';
}
