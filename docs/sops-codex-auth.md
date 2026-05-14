# SOPS secrets -> Codex auth integration

All implementation lives in `modules/secrets.nix`, gated by:

```nix
agentFramework.codexAuth.enable = true;
```

## How Codex differs from opencode

Do not copy the opencode auth format for Codex.

- opencode reads `~/.local/share/opencode/auth.json` with:
  ```json
  {"opencode-go":{"type":"api","key":"..."}}
  ```
- Codex reads `~/.codex/auth.json`.
- The local Codex auth file is a full auth document. In web sign-in mode it
  contains fields such as `auth_mode`, `tokens`, `last_refresh`, and sometimes
  an `OPENAI_API_KEY` object.
- For a first-time Framework laptop install, restore the whole Codex auth file
  from sops. Do not try to extract or synthesize one API key unless you have
  explicitly switched Codex to an API-key auth mode and verified that format.

## Source and Target

- Source machine: any machine/session where `codex` is already signed in and
  `~/.codex/auth.json` exists.
- Target machine: the Framework laptop, where Codex is installed by this Nix
  config for the first time.

## Add the Secret

Run this on the signed-in source machine:

```bash
cd /home/goya/nix-workspace

# Check structure without printing tokens.
jq '{
  auth_mode,
  has_openai_api_key: has("OPENAI_API_KEY"),
  has_tokens: has("tokens"),
  token_fields: (.tokens | keys_unsorted // [])
}' ~/.codex/auth.json

# Store the entire auth file as one encrypted string secret.
sops set secrets.yaml '["codex_auth_json"]' "$(jq -Rs . ~/.codex/auth.json)"
```

The secret is named `codex_auth_json` because sops-nix will decrypt it to:

```text
/run/secrets/codex_auth_json
```

## Enable Restoration

After `codex_auth_json` exists in `secrets.yaml`, enable:

```nix
agentFramework.codexAuth.enable = true;
```

On rebuild, `modules/secrets.nix` declares the sops secret and starts the
`codex-auth` user service. The service writes:

```text
~/.codex/auth.json
```

with mode `0600`.

## Verify on the Framework Laptop

```bash
systemctl --user status codex-auth
test -s ~/.codex/auth.json
codex --version
codex mcp list
```

If Codex reports an expired or invalid sign-in later, sign in again on any
machine, rerun the `sops set ... codex_auth_json ...` command, and rebuild the
Framework laptop.

## Security Notes

- Never commit plaintext `~/.codex/auth.json`.
- Do not print token fields in logs or terminal scrollback.
- Keep `agentFramework.codexAuth.enable = false` until `codex_auth_json` has
  been added to `secrets.yaml`; otherwise sops-nix will expect a missing secret.
