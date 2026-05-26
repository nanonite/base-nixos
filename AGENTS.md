# AGENTS.md

Repository-wide instructions for coding agents working in `/etc/nixos`.

## Codex Packaging

- `pkgs/codex.nix` is a local override of nixpkgs `codex`, pinned to an explicit upstream Rust release tag.
- Before changing the version, verify the latest upstream release on `openai/codex` and record the exact `rust-vX.Y.Z` tag you are pinning.
- When updating `pkgs/codex.nix`, diff it against the current nixpkgs `pkgs/by-name/co/codex/package.nix` and preserve the upstream build shape unless there is a documented reason not to.
- In particular, keep the build constrained to the CLI package with:
  - `cargoBuildFlags = [ "--package" "codex-cli" ];`
  - `cargoCheckFlags = [ "--package" "codex-cli" ];`
- Keep the nixpkgs-style `Cargo.toml` patch that removes upstream `lto = "fat"` and `codegen-units = 1` for local Nix builds. Do not reintroduce full-workspace/fat-LTO builds unless you have verified they are required and safe for this machine.
- After any `codex` version bump, refresh `src.hash` and `cargoHash` and verify the derivation evaluates cleanly before recommending a rebuild.

## NixOS Config

- Prefer current option names over deprecated aliases. For audio on this system, use `services.pulseaudio`, not `hardware.pulseaudio`.
- Treat warnings during `nixos-rebuild` as config debt to remove, even when they are not the immediate build failure.

## Edit Safety

- This repo may contain user changes unrelated to the current task. Do not revert them unless explicitly asked.
- Prefer small, targeted patches over broad refactors in host configuration files.
