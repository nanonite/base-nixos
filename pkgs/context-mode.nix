# context-mode — context window manager (per-agent + planner preambles)
# Source: github:mksglu/context-mode (TypeScript/Bun, pre-bundled .mjs)
# Exposes: context-mode CLI (wraps cli.bundle.mjs with Node.js)
#
# No Nix build tooling needed — the bundled JS is committed to the repo.

{ stdenv, fetchFromGitHub, nodejs, makeWrapper }:

stdenv.mkDerivation {
  pname   = "context-mode";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "mksglu";
    repo  = "context-mode";
    rev   = "ed967fea414bdb67432d832c76a27cb768ac1dd7";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/context-mode $out/bin
    cp cli.bundle.mjs $out/lib/context-mode/
    makeWrapper ${nodejs}/bin/node $out/bin/context-mode \
      --add-flags "$out/lib/context-mode/cli.bundle.mjs"
  '';
}
