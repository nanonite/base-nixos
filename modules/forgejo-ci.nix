{ lib, pkgs, config, ... }:

let
  cfg = config.agentFramework.forgejoCi;
  ensureNetwork = pkgs.writeShellScript "ensure-forgejo-ci-network" ''
    if ! ${pkgs.docker}/bin/docker network inspect forgejo-ci >/dev/null 2>&1; then
      ${pkgs.docker}/bin/docker network create forgejo-ci
    fi
  '';

  runnerEntrypoint = pkgs.writeShellScript "forgejo-runner-entrypoint" ''
    set -eu

    CONFIG_PATH="''${FORGEJO_RUNNER_CONFIG:-/data/runner-config.yml}"
    INSTANCE_URL="''${FORGEJO_INSTANCE_URL:-http://forgejo:3000}"
    RUNNER_NAME="''${FORGEJO_RUNNER_NAME:-framework-runner}"
    JOB_NETWORK="''${FORGEJO_JOB_NETWORK:-forgejo-ci}"
    CACHE_HOST="''${FORGEJO_CACHE_HOST:-forgejo-runner}"
    ACT_TMPFS_OPTION="--tmpfs /var/run/act"

    if [ ! -f "$CONFIG_PATH" ]; then
      forgejo-runner generate-config > "$CONFIG_PATH"
    fi

    tmp="$(mktemp)"
    awk \
      -v network="$JOB_NETWORK" \
      -v cache_host="$CACHE_HOST" \
      -v options="$ACT_TMPFS_OPTION" '
        BEGIN { in_container = 0; in_cache = 0; seen_container = 0; seen_cache = 0 }
        /^container:/ {
          print
          print "  network: " network
          print "  options: \"" options "\""
          in_container = 1
          in_cache = 0
          seen_container = 1
          next
        }
        /^cache:/ {
          print
          print "  host: " cache_host
          in_container = 0
          in_cache = 1
          seen_cache = 1
          next
        }
        /^[^[:space:]]/ {
          in_container = 0
          in_cache = 0
        }
        in_container && /^  (network|options):/ { next }
        in_cache && /^  host:/ { next }
        { print }
        END {
          if (!seen_container) {
            print ""
            print "container:"
            print "  network: " network
            print "  options: \"" options "\""
          }
          if (!seen_cache) {
            print ""
            print "cache:"
            print "  host: " cache_host
          }
        }
      ' "$CONFIG_PATH" > "$tmp"
    mv "$tmp" "$CONFIG_PATH"

    if [ ! -f /data/.runner ] && [ -n "''${FORGEJO_RUNNER_TOKEN:-}" ]; then
      forgejo-runner register \
        --no-interactive \
        --instance "$INSTANCE_URL" \
        --token "$FORGEJO_RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --config "$CONFIG_PATH"
    fi

    exec forgejo-runner daemon --config "$CONFIG_PATH"
  '';
in
{
  options.agentFramework.forgejoCi = {
    enable = lib.mkEnableOption "local Forgejo plus Forgejo Actions runner for ExoMonad";

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/forgejo-ci";
      description = "Persistent state directory for Forgejo and its local runner.";
    };

    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind Forgejo HTTP and SSH ports.";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Host port for the Forgejo web UI and API.";
    };

    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 2222;
      description = "Host port for Forgejo SSH git access.";
    };

    runnerEnvFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/forgejo-ci/runner.env";
      description = "Local env file containing FORGEJO_RUNNER_TOKEN for first runner registration.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker.enable = true;
      oci-containers = {
        backend = "docker";
        containers = {
          forgejo = {
            image = "codeberg.org/forgejo/forgejo:15";
            ports = [
              "${cfg.hostAddress}:${toString cfg.httpPort}:3000"
              "${cfg.hostAddress}:${toString cfg.sshPort}:22"
            ];
            volumes = [
              "${cfg.stateDir}/forgejo-data:/data"
            ];
            environment = {
              USER_UID = "1000";
              USER_GID = "1000";
              FORGEJO__server__DOMAIN = "localhost";
              FORGEJO__server__HTTP_PORT = "3000";
              FORGEJO__server__SSH_DOMAIN = "localhost";
              FORGEJO__server__SSH_PORT = toString cfg.sshPort;
              FORGEJO__actions__ENABLED = "true";
              FORGEJO__actions__DEFAULT_ACTIONS_URL = "http://forgejo:3000";
              FORGEJO__log__LEVEL = "Info";
            };
            extraOptions = [
              "--network=forgejo-ci"
              "--network-alias=forgejo"
              "--health-cmd=curl -f http://localhost:3000/api/healthz || exit 1"
              "--health-interval=10s"
              "--health-timeout=5s"
              "--health-retries=10"
            ];
          };

          forgejo-dind = {
            image = "docker:dind";
            cmd = [ "dockerd" "-H" "tcp://0.0.0.0:2375" "--tls=false" ];
            extraOptions = [
              "--privileged"
              "--network=forgejo-ci"
              "--network-alias=docker-in-docker"
            ];
          };

          forgejo-runner = {
            image = "data.forgejo.org/forgejo/runner:12";
            user = "1000:1000";
            volumes = [
              "${cfg.stateDir}/runner-data:/data"
              "${runnerEntrypoint}:/runner-entrypoint.sh:ro"
            ];
            environment = {
              DOCKER_HOST = "tcp://docker-in-docker:2375";
              FORGEJO_INSTANCE_URL = "http://forgejo:3000";
              FORGEJO_JOB_NETWORK = "forgejo-ci";
              FORGEJO_CACHE_HOST = "forgejo-runner";
              FORGEJO_RUNNER_NAME = "framework-runner";
            };
            environmentFiles = [ cfg.runnerEnvFile ];
            cmd = [ "/bin/sh" "/runner-entrypoint.sh" ];
            extraOptions = [
              "--network=forgejo-ci"
              "--network-alias=forgejo-runner"
            ];
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 root root - -"
      "d ${cfg.stateDir}/forgejo-data 0750 1000 1000 - -"
      "d ${cfg.stateDir}/runner-data 0750 1000 1000 - -"
    ];

    systemd.services.forgejo-ci-network = {
      description = "Docker network for local Forgejo CI";
      wantedBy = [ "multi-user.target" ];
      before = [
        "docker-forgejo.service"
        "docker-forgejo-dind.service"
        "docker-forgejo-runner.service"
      ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${ensureNetwork}";
      };
    };

    systemd.services.docker-forgejo = {
      after = [ "forgejo-ci-network.service" ];
      requires = [ "forgejo-ci-network.service" ];
    };

    systemd.services.docker-forgejo-dind = {
      after = [ "forgejo-ci-network.service" ];
      requires = [ "forgejo-ci-network.service" ];
    };

    systemd.services.docker-forgejo-runner = {
      after = [
        "forgejo-ci-network.service"
        "docker-forgejo.service"
        "docker-forgejo-dind.service"
      ];
      requires = [
        "forgejo-ci-network.service"
        "docker-forgejo.service"
        "docker-forgejo-dind.service"
      ];
      unitConfig.ConditionPathExists = cfg.runnerEnvFile;
    };
  };
}
