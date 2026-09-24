{ lib
, stdenv
, fetchurl
, makeWrapper
, alsa-lib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, coreutils
, cups
, dbus
, expat
, fontconfig
, freetype
, glib
, gnutar
, gtk3
, libdrm
, libgbm
, libX11
, libXcomposite
, libXdamage
, libXext
, libXfixes
, libXi
, libXrandr
, libXrender
, libXScrnSaver
, libXtst
, libxcb
, libxkbcommon
, mesa
, nspr
, nss
, openssh
, pango
, procps
, systemd
, which
}:

let
  todeSrc = fetchurl {
    url = "https://tode-releases.zenbu-labs.workers.dev/dl/dev/main-4c37066/tode-linux-x64.tar.gz";
    hash = "sha256-KJOCO2DxRayTlrJwRzdhoT11pGPIiIG4AUYNVwRqlXE=";
  };

  codeServerSrc = fetchurl {
    url = "https://github.com/coder/code-server/releases/download/v4.132.0/code-server-4.132.0-linux-amd64.tar.gz";
    hash = "sha256-o40m9MuB92j+3f954pN/0/Ocg9Pai+PaciXhCH5i5O0=";
  };

  runtimeLibs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    glib
    gtk3
    libdrm
    libgbm
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXScrnSaver
    libXtst
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
  ];

  runtimeBins = [
    coreutils
    fontconfig
    gnutar
    openssh
    procps
    which
  ];
in
stdenv.mkDerivation {
  pname = "terminal-code";
  version = "dev-4c37066";

  src = todeSrc;

  nativeBuildInputs = [ makeWrapper ];

  unpackPhase = ''
    mkdir -p tode code-server
    tar -xzf "$src" -C tode --strip-components=1
    tar -xzf ${codeServerSrc} -C code-server --strip-components=1
  '';

  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/libexec/tode" "$out/libexec/code-server" "$out/bin"
    cp -R tode/. "$out/libexec/tode/"
    cp -R code-server/. "$out/libexec/code-server/"

    makeWrapper "$out/libexec/tode/bin/tode" "$out/bin/tode" \
      --set TODE_INSTALL_ROOT "$out/libexec/tode" \
      --set TODE_CODE_SERVER "$out/libexec/code-server/bin/code-server" \
      --set TODE_TERMINAL_BROWSER_BIN "$out/libexec/tode/vendor/terminal-browser/bin/terminal-browser" \
      --prefix PATH : "${lib.makeBinPath runtimeBins}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
  '';

  meta = {
    description = "VS Code inside your terminal";
    homepage = "https://github.com/zenbu-labs/terminal-code";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tode";
  };
}
