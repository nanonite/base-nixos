# ── Flutter + Android SDK dev shell ──────────────────────────────────────────
#
# TO USE: Copy this file into your Flutter project root and rename as needed.
#
#   cp ~/nix-workspace/devshells/flutter/flake.nix /path/to/my-flutter-project/flake.nix
#
# Then from your project root:
#   nix develop          → enter the dev environment
#   flutter doctor       → verify everything is wired up
#   flutter build apk    → build APK
#   adb devices          → list connected devices
#
# ─────────────────────────────────────────────────────────────────────────────

{
  description = "Flutter + Android SDK dev environment";  # rename this to your project name

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions  = [ "34.0.0" ];
          platformVersions    = [ "34" ];
          abiVersions         = [ "arm64-v8a" "x86_64" ];
          includeEmulator     = false;  # set true to use the Android emulator
          includeSystemImages = false;
        };

        androidSdk = androidComposition.androidsdk;

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            flutter
            androidSdk
            jdk17
            gradle
            git
          ];

          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          ANDROID_HOME     = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME        = "${pkgs.jdk17}";

          shellHook = ''
            export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
            echo "Flutter dev environment ready"
            echo "  Flutter: $(flutter --version 2>/dev/null | head -1)"
            echo "  Android SDK: $ANDROID_SDK_ROOT"
          '';
        };
      }
    );
}
