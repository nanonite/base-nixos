{ lib, config, pkgs, ... }:

# ── secrets.nix — encrypted secrets via sops-nix ──────────────────────────────
#
# Decrypts secrets.yaml at boot into /run/secrets/ using an age keypair.
# A systemd user service injects the secrets into the user session environment
# so GUI apps (launched via niri, not a login shell) see them too.
#
# Setup (one-time, on the target machine):
#   1. mkdir -p /etc/sops/age
#   2. age-keygen -o /etc/sops/age/keys.txt
#   3. sops --encrypt --age <public-key> secrets.yaml > secrets.yaml.enc
#   4. mv secrets.yaml.enc secrets.yaml

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.keyFile = "/etc/sops/age/keys.txt";
    secrets = {
      openrouter_api_key = {
        owner = "framework";
        mode = "0400";
      };
      opencode_api_key = {
        owner = "framework";
        mode = "0400";
      };
    } // lib.optionalAttrs config.agentFramework.codexAuth.enable {
      codex_auth_json = {
        owner = "framework";
        mode = "0400";
      };
    };
  };

  # Inject OPENROUTER_API_KEY into the systemd user session (used by sandbox
  # configs in agent-sandbox/ and picked up by any terminal child process).
  systemd.user.services.sops-env = {
    description = "Import sops secrets into the systemd user environment";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "sops-env-import" ''
        ${pkgs.systemd}/bin/systemctl --user set-environment \
          OPENROUTER_API_KEY=$(cat /run/secrets/openrouter_api_key)
      '';
    };
  };

  # Write the opencode Go API key directly into auth.json so opencode picks it
  # up on every launch without needing any environment variable or manual /connect.
  systemd.user.services.opencode-auth = {
    description = "Write opencode Go API key to auth.json";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "write-opencode-auth" ''
        mkdir -p "$HOME/.local/share/opencode"
        KEY=$(cat /run/secrets/opencode_api_key)
        printf '{"opencode-go":{"type":"api","key":"%s"}}\n' "$KEY" \
          > "$HOME/.local/share/opencode/auth.json"
        chmod 600 "$HOME/.local/share/opencode/auth.json"
      '';
    };
  };

  # Codex web sign-in stores OAuth-style session material in ~/.codex/auth.json.
  # Do not try to derive an API key from it; replicate the whole auth JSON as a
  # sops secret named codex_auth_json when you want a fresh machine to inherit it.
  systemd.user.services.codex-auth = lib.mkIf config.agentFramework.codexAuth.enable {
    description = "Write Codex auth.json from sops when available";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "write-codex-auth" ''
        SECRET=/run/secrets/codex_auth_json
        if [ ! -s "$SECRET" ]; then
          exit 0
        fi

        mkdir -p "$HOME/.codex"
        cp "$SECRET" "$HOME/.codex/auth.json"
        chmod 600 "$HOME/.codex/auth.json"
      '';
    };
  };

}
