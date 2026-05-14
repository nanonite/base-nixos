# Docker Sandboxes Auth Secret

Docker Sandboxes stores login material in an opaque posixage-backed config tree:

```text
~/.config/com.docker.sandboxes
```

Do not store sandbox runtime state from `~/.local/state/sandboxes`; that contains
containerd images, block volumes, logs, and disposable runtime data.

## Capture

After `sbx login` succeeds on the Framework laptop:

```bash
cd /etc/nixos

tar -C ~/.config -czf - com.docker.sandboxes \
  | base64 -w0 \
  | sops set secrets.yaml '["sbx_config_tgz_b64"]' /dev/stdin
```

## Enable

After the secret exists, enable restoration in the host config:

```nix
agentFramework.sbxAuth.enable = true;
```

On rebuild, `sops-nix` decrypts `/run/secrets/sbx_config_tgz_b64`, and the
`sbx-auth` user service restores:

```text
~/.config/com.docker.sandboxes
```

with `0700` directories and `0600` files.

## Verify

```bash
systemctl --user status sbx-auth.service
sbx login
sbx diagnose -o json
```

If `sbx login` still opens a browser, re-run `sbx login`, recapture the tarball,
and rebuild.
