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

{ stdenv, fetchFromGitHub, wasmToolchain, wizer, cacert, curl }:

stdenv.mkDerivation {
  pname   = "exomonad-wasm";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "tidepool-heavy-industries";
    repo  = "exomonad";
    rev   = "5dfab102fe65d5d1d57d54651c000b6de1336e70";
    hash  = "sha256-ILK9PEjJYvVq2IpnWsRFhOIkncEoOgobN7cA/an29kk=";
  };

  nativeBuildInputs = [ wasmToolchain wizer cacert curl ];

  # Use system curl for HTTPS — wasm32-wasi-cabal's built-in HTTP client has no TLS.
  # curl is from nixpkgs and has full HTTPS support.
  CURL_CA_BUNDLE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  # FOD: allows network access during build; reproducible once hash is known.
  # Run `nix build .#exomonad-wasm` with a placeholder hash to get the real one.
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash     = "sha256-k/xAwye4oJcYMSAo6dEib46VyoNt0FVeYNU308XQAeg=";

  postPatch = ''
    # Remove developer-local external role paths (not present outside author's machine)
    sed -i '/shoal/d' cabal.project.wasm
    sed -i '/penumbra/d' cabal.project.wasm

    # head.hackage only provides a patched 'time' package for wasm32 compatibility,
    # but GHC 9.12 already ships time-1.14 as a boot library — not needed.
    sed -i '/^repository head\.hackage/,/^$/d' cabal.project.wasm

    # Force cabal to use system curl (which has full HTTPS) instead of its
    # built-in Haskell HTTP client (compiled without TLS in the wasm toolchain).
    echo 'http-transport: curl' >> cabal.project.wasm
  '';

  buildPhase = ''
    export HOME=$TMPDIR
    export CABAL_DIR=$TMPDIR/cabal

    # Fetch Hackage index (needed for aeson, unordered-containers, etc.)
    wasm32-wasi-cabal update --project-file=cabal.project.wasm

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
