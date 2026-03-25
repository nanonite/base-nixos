# tracey — structured observability for agent runs
# Source: github:bearcove/tracey (Rust workspace, binary at crates/tracey)
#
# Fill in hashes:
#   nix build .#tracey 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub, nodejs }:

rustPlatform.buildRustPackage {
  pname   = "tracey";
  version = "unstable-2026-01-15";

  src = fetchFromGitHub {
    owner = "bearcove";
    repo  = "tracey";
    rev   = "6fe672f12dc7005a48a33f0f9c486794e49a9974";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ nodejs ];

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  # Workspace — build only the main tracey binary
  cargoBuildFlags = [ "-p" "tracey" ];
  cargoTestFlags  = [ "-p" "tracey" ];
}
