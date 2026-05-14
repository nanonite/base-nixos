# SOPS secrets → opencode API key integration

All implementation lives in `modules/secrets.nix`.

## How it works

sops-nix decrypts `secrets.yaml` at boot into `/run/secrets/` using an age
keypair stored at `/etc/sops/age/keys.txt`.  Two systemd **user** services then
consume the decrypted files:

| Service | What it does |
|---|---|
| `sops-env` | Sets `OPENROUTER_API_KEY` in the systemd user environment so agent sandboxes and terminal children see it |
| `opencode-auth` | Writes `~/.local/share/opencode/auth.json` so opencode picks up the API key on every launch without a `/connect` step |

> **Why not `environment.extraInit`?**  
> GUI apps launched by niri are not login-shell children, so `extraInit` env
> vars are invisible to them.  `systemctl --user set-environment` injects into
> the session manager instead, reaching every process in the session.

## One-time machine setup

```bash
# 1. Create age key (run as root or with sudo)
mkdir -p /etc/sops/age
age-keygen -o /etc/sops/age/keys.txt        # prints the public key

# 2. Encrypt secrets.yaml with that public key
sops --encrypt --age <public-key> secrets.yaml > secrets.yaml.enc
mv secrets.yaml.enc secrets.yaml
```

## `secrets.yaml` structure (plaintext, before encryption)

```yaml
openrouter_api_key: sk-or-...
opencode_api_key: <opencode-go key>
# optional — only needed when agentFramework.codexAuth.enable = true
codex_auth_json: |
  {"accessToken":"...","...":"..."}
```

## NixOS config summary (`modules/secrets.nix`)

```nix
sops = {
  defaultSopsFile = ../secrets.yaml;
  age.keyFile = "/etc/sops/age/keys.txt";
  secrets = {
    openrouter_api_key = { owner = "framework"; mode = "0400"; };
    opencode_api_key   = { owner = "framework"; mode = "0400"; };
  };
};
```

The `opencode-auth` service writes:

```json
{"opencode-go":{"type":"api","key":"<KEY>"}}
```

to `~/.local/share/opencode/auth.json` (chmod 600).

## Adding a new secret

1. Decrypt `secrets.yaml` with `sops secrets.yaml`, add the new key, save.
2. Add the secret name under `sops.secrets` in `secrets.nix` (with owner/mode).
3. Add a `systemd.user.services.*` block to consume it, or extend `sops-env`
   to call `systemctl --user set-environment KEY=$(cat /run/secrets/key)`.
4. `sudo nixos-rebuild switch`.

## Verifying after a rebuild

```bash
# Check env injection
systemctl --user show-environment | grep OPENROUTER

# Check opencode auth file
cat ~/.local/share/opencode/auth.json

# Check service status
systemctl --user status sops-env opencode-auth
```
