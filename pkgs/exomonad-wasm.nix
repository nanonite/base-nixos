# exomonad-wasm — Haskell WASM plugins for exomonad
#
# Builds wasm-guest-devswarm.wasm and wasm-guest-e2e-test.wasm from the
# exomonad repo's Haskell source using GHC 9.12 wasm32-wasi toolchain.
#
# This is a fixed-output derivation (FOD) because `wasm32-wasi-cabal update`
# needs network access to fetch head.hackage index patches. The outputHash
# makes the result content-addressed and reproducible.
#
# Fill in outputHash:
#   nix build .#exomonad-wasm 2>&1 | grep "got:"

{ stdenv, fetchFromGitHub, wasmToolchain, wizer, cacert }:

stdenv.mkDerivation {
  pname   = "exomonad-wasm";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "tidepool-heavy-industries";
    repo  = "exomonad";
    rev   = "5dfab102fe65d5d1d57d54651c000b6de1336e70";
    hash  = "sha256-ILK9PEjJYvVq2IpnWsRFhOIkncEoOgobN7cA/an29kk=";
  };

  nativeBuildInputs = [ wasmToolchain wizer cacert ];

  # Required for cabal to make HTTPS connections to head.hackage in the Nix sandbox
  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  # FOD: allows network access during build; reproducible once hash is known.
  # Run `nix build .#exomonad-wasm` with a placeholder hash to get the real one.
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash     = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  postPatch = ''
    # Remove developer-local external role paths (not present outside author's machine)
    sed -i '/shoal/d' cabal.project.wasm
    sed -i '/penumbra/d' cabal.project.wasm

    # wasm32-wasi-cabal is compiled without TLS support so it cannot fetch the
    # head.hackage index over HTTPS. Remove the head.hackage repository stanza —
    # all packages it patches are already vendored under haskell/vendor/ and
    # cabal.project.wasm sets allow-newer: all, so regular Hackage suffices.
    sed -i '/^repository head\.hackage/,/^$/d' cabal.project.wasm
  '';

  buildPhase = ''
    export HOME=$TMPDIR
    export CABAL_DIR=$TMPDIR/cabal

    # Compile devswarm role (planner + TL + dev + worker + testrunner)
    wasm32-wasi-cabal build \
      --project-file=cabal.project.wasm \
      wasm-guest-devswarm

    # Compile e2e-test role
    wasm32-wasi-cabal build \
      --project-file=cabal.project.wasm \
      wasm-guest-e2e-test
  '';

  installPhase = ''
    mkdir -p $out
    find dist-newstyle -name "wasm-guest-*.wasm" -type f -exec cp {} $out/ \;
  '';
}
