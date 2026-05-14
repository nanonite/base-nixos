{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  lz4,
  zlib,
  zstd,
}:

stdenv.mkDerivation {
  pname = "docker-sbx";
  version = "0.29.0";

  src = fetchurl {
    url = "https://download.docker.com/linux/ubuntu/dists/noble/pool/stable/amd64/docker-sbx_0.29.0-1~ubuntu.24.04~noble_amd64.deb";
    hash = "sha256-dTvwVXiaGPGpzuZWdYxav6g3AEgk5ZnXLIx0KyXhN30=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    lz4
    zlib
    zstd
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec $out/etc/apparmor.d $out/share/doc/docker-sbx
    cp usr/bin/sbx $out/bin/sbx
    cp -r usr/libexec/* $out/libexec/
    cp -r usr/share/doc/docker-sbx/* $out/share/doc/docker-sbx/ 2>/dev/null || true
    substitute etc/apparmor.d/docker-sbx-nerdbox-shim \
      $out/etc/apparmor.d/docker-sbx-nerdbox-shim \
      --replace-fail /usr/libexec/containerd-shim-nerdbox-v1 \
        $out/libexec/containerd-shim-nerdbox-v1

    runHook postInstall
  '';

  meta = {
    description = "Docker Sandboxes CLI and runtime support";
    homepage = "https://docs.docker.com/sandbox/";
    platforms = [ "x86_64-linux" ];
  };
}
