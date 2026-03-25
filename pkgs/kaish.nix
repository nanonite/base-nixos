# kaish — constrained agent shell (agent-safe, structured I/O)
# Source: github:tobert/kaish (Rust)
#
# Fill in hashes:
#   nix build .#kaish 2>&1 | grep "got:"

{ rustPlatform, fetchFromGitHub, pkg-config, openssl }:

rustPlatform.buildRustPackage {
  pname   = "kaish";
  version = "unstable-2026-01-15";

  nativeBuildInputs = [ pkg-config ];
  buildInputs       = [ openssl ];

  src = fetchFromGitHub {
    owner = "tobert";
    repo  = "kaish";
    rev   = "c18e77ef7d948ec1b8bbd04da05f0f038a735dbe";
    hash  = "sha256-4sYK6jvHw8UmxLyGeNhnmM/oIIBB9VdtNeIDkEvnlL4=";
  };

  cargoHash = "sha256-hcc2qK8pl8XO5i9wbGYwIl3Rshe4tSJextXmYE8svRU=";
}
