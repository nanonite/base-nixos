# axon — recursive LM self-reflection engine
# Source: github:Diogenesoftoronto/axon (Rust)
#
# Fill in hashes:
#   nix build .#axon 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname   = "axon";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "Diogenesoftoronto";
    repo  = "axon";
    rev   = "315b6923793d6048b9d65af06d770e34409ad2c3";
    hash  = "sha256-55Uv9tgm6T9Vmbs+IyBwSRtlG2I5TjmII5/I5Tk5gO8=";
  };

  cargoHash = "sha256-l8lTvcQETjhNYeC4fEM7BsuVOnb54goPRQd8v2YOfYw=";

  # ouros-0.0.4 (transitive dep) has `include_str!("../../../README.md")`
  # in src/lib.rs — designed to be used nested inside its own repo.
  # In the Nix sandbox the path resolves to /build/README.md (one level
  # above the unpacked source); create a stub to satisfy the macro.
  postPatch = ''
    touch ../README.md
  '';
}
