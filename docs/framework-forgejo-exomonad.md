# Framework Forgejo + ExoMonad Setup

The Framework host enables `agentFramework.forgejoCi`, which runs the local
Forgejo CI stack through NixOS-managed Docker containers:

- `forgejo` on `http://localhost:3000`
- `forgejo-dind` for Forgejo Actions job containers
- `forgejo-runner` on the named `forgejo-ci` Docker network

The named network matches the current ExoMonad Forgejo workflow and avoids the
fragile Docker bridge IP setup.

## First Boot

Rebuild the Framework config:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#framework
```

Open `http://localhost:3000` and finish the Forgejo install wizard with SQLite.
Create the admin user, then generate a runner registration token at:

```text
http://localhost:3000/-/admin/runners
```

Put the token in the local runner env file:

```bash
sudo install -d -m 0750 /var/lib/forgejo-ci
sudo sh -c 'printf "FORGEJO_RUNNER_TOKEN=%s\n" "<runner-token>" > /var/lib/forgejo-ci/runner.env'
sudo chmod 0600 /var/lib/forgejo-ci/runner.env
sudo systemctl restart docker-forgejo-runner.service
```

## Project Config

Each ExoMonad project still owns its `.exo/config.toml`. Add the local Forgejo
settings there after creating Forgejo personal access tokens:

```toml
forgejo_url = "http://localhost:3000"
forgejo_token = "<author-personal-access-token>"
forgejo_reviewer_token = "<reviewer-personal-access-token>"
forgejo_webhook_secret = "<random-secret>"
forgejo_ssh_port = 2222
```

Use a different Forgejo user/token for `forgejo_reviewer_token`; Forgejo rejects
reviews submitted by the PR author.

## Checks

```bash
systemctl status docker-forgejo.service docker-forgejo-dind.service docker-forgejo-runner.service
docker network inspect forgejo-ci
docker logs forgejo-runner
```

For a project:

```bash
exomonad new
exomonad init
```
