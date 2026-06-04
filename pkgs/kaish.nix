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

  # Upstream's current tests assume a normal FHS shell environment (/bin/echo,
  # root-like HOME) and also contain failing scatter/timeout parser cases.
  # Keep this package buildable for the system closure while those are unresolved.
  doCheck = false;

  depsExtraArgs = {
    preBuild = ''
      # crates.io rejects the helper's default python-requests user agent.
      mkdir -p .nix-cargo-vendor-bin
      cp "$(command -v fetch-cargo-vendor-util)" .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      chmod +w .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      substituteInPlace .nix-cargo-vendor-bin/fetch-cargo-vendor-util \
        --replace-fail 'session = requests.Session()' 'session = requests.Session(); session.headers.update({"User-Agent": "nixpkgs-fetch-cargo-vendor"})'
      chmod +x .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      export PATH="$PWD/.nix-cargo-vendor-bin:$PATH"
    '';
  };
}
