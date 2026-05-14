# lolearn — local learning/memory CLI
# Source: github:nanonite/legendary-couscous-lolearn
#
# First build on the Framework laptop will report the fixed-output hash mismatch:
#   nix build .#lolearn
# Replace the src hash with the reported "got:" value.

{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "nanonite";
    repo = "legendary-couscous-lolearn";
    rev = "dd2bcee52663e01fb788553c2305913cfbcaa548";
    hash = lib.fakeHash;
  };
in
rustPlatform.buildRustPackage {
  pname = "lolearn";
  version = "unstable-2026-05-14";

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = {
    description = "Local learning and memory CLI for agent workflows";
    homepage = "https://github.com/nanonite/legendary-couscous-lolearn";
    mainProgram = "lolearn";
    platforms = [ "x86_64-linux" ];
  };
}
