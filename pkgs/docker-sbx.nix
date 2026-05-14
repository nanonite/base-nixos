{
  stdenvNoCC,
  fetchurl,
  dpkg,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "docker-sbx";
  version = "0.29.0";

  src = fetchurl {
    url = "https://download.docker.com/linux/ubuntu/dists/noble/pool/stable/amd64/docker-sbx_0.29.0-1~ubuntu.24.04~noble_amd64.deb";
    hash = "sha256-dTvwVXiaGPGpzuZWdYxav6g3AEgk5ZnXLIx0KyXhN30=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/docker-sbx $out/share/doc/docker-sbx
    cp usr/bin/sbx $out/libexec/docker-sbx/sbx
    cp -r usr/libexec/* $out/libexec/docker-sbx/
    cp -r usr/share/doc/docker-sbx/* $out/share/doc/docker-sbx/ 2>/dev/null || true

    makeWrapper $out/libexec/docker-sbx/sbx $out/bin/sbx \
      --set DOCKER_SBX_LIBEXEC $out/libexec/docker-sbx

    runHook postInstall
  '';

  meta = {
    description = "Docker Sandboxes CLI and runtime support";
    homepage = "https://docs.docker.com/sandbox/";
    platforms = [ "x86_64-linux" ];
  };
}
