# ExoMonad Build Notes

## crates.io 403 During Cargo Vendoring

Observed on 2026-06-04 while building the Framework NixOS toplevel:

```text
Exception: Failed to fetch file from https://crates.io/api/v1/crates/debugid/0.8.0/download. Status code: 403
```

This happened in the fixed-output cargo vendor staging derivation:

```text
exomonad-unstable-2026-05-25-vendor-staging.drv
```

The failure was not an ExoMonad Rust compile error. crates.io rejected the
default `python-requests` user agent used by nixpkgs'
`fetch-cargo-vendor-util`.

The local fix in `pkgs/exomonad.nix` mirrors the existing workaround in
`pkgs/codex.nix`: copy `fetch-cargo-vendor-util` into a temporary bin directory
for this derivation, patch it to send a `User-Agent:
nixpkgs-fetch-cargo-vendor` header, and put that patched helper first on
`PATH` through `depsExtraArgs.preBuild`.

## Stale exomonad-wasm Fixed-Output Hash

After the cargo vendor stage was fixed, `exomonad-wasm` failed with a separate
fixed-output hash mismatch:

```text
specified: sha256-irmA8or9ox5OxkzF9ODa83/EnWbOtI4Wo4G4z7PzM8c=
got:       sha256-nUyqmDM0X0XGBiRx0YkOIGlUpXE/PEYAtP1Toeutko8=
```

The recorded `outputHash` in `pkgs/exomonad-wasm.nix` was updated to the
reported `got` hash:

```nix
outputHash = "sha256-nUyqmDM0X0XGBiRx0YkOIGlUpXE/PEYAtP1Toeutko8=";
```

## Verification

The package build succeeded:

```bash
nix --extra-experimental-features 'nix-command flakes' build .#exomonad --no-link
```

The full Framework toplevel also built successfully:

```bash
nix --extra-experimental-features 'nix-command flakes' build \
  --print-out-paths \
  '/etc/nixos#nixosConfigurations."framework".config.system.build.toplevel' \
  --no-link
```

Result:

```text
/nix/store/vrrfmcjz2zvhrhl2ixrg97cfqyxpki15-nixos-system-framework-26.05.20260418.b12141e
```

Unrelated evaluation warnings seen during verification:

- `greetd.tuigreet` was renamed to `tuigreet`
- `xorg.libxcb` was renamed to `libxcb`
- `nixfmt-rfc-style` should be replaced with `pkgs.nixfmt`
- framework profile warns about using both `enableKeybinds` and `includes.enable`
