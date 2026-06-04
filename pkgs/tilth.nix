# tilth — code intelligence MCP server
# Source: crates.io/crates/tilth v0.8.4 (Rust)
#
# Fill in hashes:
#   nix build .#tilth 2>&1 | grep "got:"

{ rustPlatform, fetchCrate, gitMinimal }:

rustPlatform.buildRustPackage {
  pname   = "tilth";
  version = "0.8.4";

  src = fetchCrate {
    pname   = "tilth";
    version = "0.8.4";
    hash    = "sha256-ZWU/RdNzDgTmHYuYWLQmrMYX4idEpKIu3sJs5EStSR0=";
  };

  cargoHash = "sha256-XXZXgC5KA/1Z1CIVIvbp3BtadhOL+nFh3/0P+7sWTn0=";

  nativeCheckInputs = [ gitMinimal ];

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
