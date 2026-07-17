{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  codex,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex-fugu";
  version = "2026-07-16";

  src = fetchFromGitHub {
    owner = "SakanaAI";
    repo = "fugu";
    rev = "83f099cc678c3d9a88c1b1bcd085ed679ec3b89f";
    hash = "sha256-eSwpQJih+dbAAPrXUwOn3bQq22bbV61X//zkZDjQHXI=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/codex-fugu
    cp configs/files/fugu.json $out/share/codex-fugu/fugu.json
    cp configs/formats/modern/files/fugu.config.toml $out/share/codex-fugu/fugu.config.toml
    cp configs/injects/model_providers.sakana.toml $out/share/codex-fugu/model_providers.sakana.toml

    makeWrapper ${lib.getExe codex} $out/bin/codex-fugu \
      --add-flags "-p fugu"

    runHook postInstall
  '';

  passthru = {
    fuguRepo = finalAttrs.src;
    upstreamCommit = finalAttrs.src.rev;
    bundleCodexVersion = "0.144.4";
  };

  meta = {
    description = "Sakana Fugu launcher and profile assets for Codex CLI";
    homepage = "https://github.com/SakanaAI/fugu";
    mainProgram = "codex-fugu";
    platforms = lib.platforms.unix;
  };
})
