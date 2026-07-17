{
  lib,
  stdenv,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  bubblewrap,
  clang,
  cmake,
  gitMinimal,
  libcap,
  libclang,
  librusty_v8 ? callPackage ./nixpkgs-codex/librusty_v8.nix {
    inherit (callPackage ./nixpkgs-codex/fetchers.nix { }) fetchLibrustyV8;
  },
  livekit-libwebrtc,
  makeBinaryWrapper,
  nix-update-script,
  pkg-config,
  openssl,
  ripgrep,
  versionCheckHook,
  installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "codex";
  # Keep this pinned to the latest upstream Rust release tag after verifying it.
  # When updating, diff against nixpkgs' codex package and preserve its build
  # shape so we do not regress into a full-workspace, fat-LTO local build.
  version = "0.144.5";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${finalAttrs.version}";
    hash = "sha256-v8MsNWeqiYsTvPtlXs8UMuZKLf7Cj71Vl+MHXihAkos=";
  };

  sourceRoot = "${finalAttrs.src.name}/codex-rs";

  cargoHash = "sha256-S4dsZXfmKvJItL2XYKyxfhqdCMATEG6oPjrtVRwkuYc=";

  depsExtraArgs = {
    preBuild = ''
      # Codex has a large lockfile; avoid crates.io API rate limiting while
      # preserving nixpkgs' fetch-cargo-vendor build shape.
      mkdir -p .nix-cargo-vendor-bin
      cp "$(command -v fetch-cargo-vendor-util)" .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      chmod +w .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      substituteInPlace .nix-cargo-vendor-bin/fetch-cargo-vendor-util \
        --replace-fail 'total=5' 'total=20' \
        --replace-fail 'backoff_factor=0.5' 'backoff_factor=2' \
        --replace-fail 'status_forcelist=[500, 502, 503, 504]' 'status_forcelist=[429, 500, 502, 503, 504]' \
        --replace-fail 'return f"https://crates.io/api/v1/crates/{pkg["name"]}/{pkg["version"]}/download"' 'return f"https://static.crates.io/crates/{pkg["name"]}/{pkg["name"]}-{pkg["version"]}.crate"' \
        --replace-fail 'session = requests.Session()' 'session = requests.Session(); session.headers.update({"User-Agent": "nixpkgs-fetch-cargo-vendor"})' \
        --replace-fail 'with mp.Pool(min(5, mp.cpu_count())) as pool:' 'with mp.Pool(1) as pool:'
      chmod +x .nix-cargo-vendor-bin/fetch-cargo-vendor-util
      export PATH="$PWD/.nix-cargo-vendor-bin:$PATH"
    '';
  };

  # Match upstream's release build for the codex binary only.
  cargoBuildFlags = [ "--package" "codex-cli" ];
  cargoCheckFlags = [ "--package" "codex-cli" ];

  postPatch = ''
    # webrtc-sys asks rustc to link libwebrtc statically by default,
    # but nixpkgs provides libwebrtc as a shared library.
    substituteInPlace $cargoDepsCopy/*/webrtc-sys-*/build.rs \
      --replace-fail "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"

    # Upstream uses a heavier release profile than is practical for local Nix
    # builds of the CLI. Mirror nixpkgs here so rebuilds stay tractable.
    substituteInPlace Cargo.toml \
      --replace-fail 'lto = "thin"' "" \
      --replace-fail 'codegen-units = 4' ""
  '';

  nativeBuildInputs = [
    clang
    cmake
    gitMinimal
    installShellFiles
    makeBinaryWrapper
    pkg-config
  ];

  buildInputs = [
    libclang
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ];

  env = {
    LIBCLANG_PATH = "${lib.getLib libclang}/lib";
    LK_CUSTOM_WEBRTC = lib.getDev livekit-libwebrtc;
    NIX_CFLAGS_COMPILE = toString (
      lib.optionals stdenv.cc.isGNU [
        "-Wno-error=stringop-overflow"
      ]
      ++ lib.optionals stdenv.cc.isClang [
        "-Wno-error=character-conversion"
      ]
    );
    RUSTY_V8_ARCHIVE = librusty_v8;
  };

  doCheck = false;

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/codex --prefix PATH : ${
      lib.makeBinPath ([ ripgrep ] ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ])
    }
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--use-github-releases"
        "--version-regex"
        "^rust-v(\\d+\\.\\d+\\.\\d+)$"
      ];
    };
  };

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    maintainers = with lib.maintainers; [
      delafthi
      jeafleohj
      malo
    ];
    platforms = lib.platforms.unix;
  };
})
