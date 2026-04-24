{ lib, config, ... }:

# ── secrets.nix — encrypted secrets via sops-nix ──────────────────────────────
#
# Decrypts secrets.yaml at boot into /run/secrets/ using an age keypair.
# Secrets are exported as environment variables via environment.extraInit.
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
      openrouter_api_key = {};
      opencode_api_key = {};
    };
  };

  # Export decrypted secrets as environment variables on every shell login.
  environment.extraInit = ''
    [ -f /run/secrets/openrouter_api_key ] && export OPENROUTER_API_KEY=$(cat /run/secrets/openrouter_api_key)
    [ -f /run/secrets/opencode_api_key ] && export OPENCODE_API_KEY=$(cat /run/secrets/opencode_api_key)
  '';
}
