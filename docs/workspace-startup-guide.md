# Agent Framework — New Workspace Startup Guide

## Context

All agent tools are installed system-wide on the Framework laptop.
This guide covers how to wire them together from a fresh `git clone` through active task delegation.

The stack: **chainlink** (task DB) → **exomonad** (orchestrator/MCP) → **masterblaster** (sandbox VM) → agents running inside mixtape with **axon** (deep reasoning), **tilth** (code nav), **context-mode** (context indexer).

---

## Roles of Each Tool

| Tool | Role | Key Command |
|---|---|---|
| `chainlink` | Local SQLite issue tracker (lives in workspace) | `chainlink create`, `chainlink session start` |
| `mb` | Sandbox lifecycle (pull image, launch VM, SSH) | `mb pull`, `mb up`, `mb ssh` |
| `exomonad` | MCP orchestrator — exposes `fork_wave`, `spawn_gemini`, etc. to Opus planner | `exomonad init` |
| `axon` | Recursive reasoning engine (MCP or CLI) | `axon serve`, `axon query` |
| `context-mode` | Context window indexer — FTS5 over files/git/tasks | MCP server, `ctx stats` |
| `tilth` | AST-aware code search/read (MCP) | `tilth_search`, `tilth_read` via MCP |
| `go-jira` | Sync to external JIRA (optional) | `jira issue list` |
| `ast-grep` | Structural code search | `ast-grep run` |
| `bun` | JS/TS runtime for agent-generated scripts | `bun run`, `bun <script.ts>` |

---

## Step-by-Step: Starting a New Workspace

### Step 1 — Clone and enter workspace

```bash
git clone <workspace-repo> ~/workspaces/<project>
cd ~/workspaces/<project>
```

---

### Step 2 — Initialize chainlink (local task DB)

If the repo already has a `.chainlink/` directory with issues, it's ready.
For a fresh workspace:

```bash
chainlink create -p high -l feature "First task description"
chainlink list          # verify issues exist
chainlink session start # begin a tracked work session
```

Key config: `.chainlink/rules/global.md` — coding standards chainlink enforces.
Tracking mode: `.chainlink/hook-config.json` — set `tracking_mode` to `strict|normal|relaxed`.

To import issues from another format:
```bash
chainlink import <file>
```

---

### Step 3 — Pull the base mixtape image

```bash
# Sync the NixOS config first (has provision.sh and jcard template)
cd /etc/nixos && git pull

# Pull the base stereOS image (one-time per machine)
mb pull coder-x86:latest
mb list    # confirm image is present
```

---

### Step 4 — Write a jcard.toml for this workspace

A template lives in the NixOS config repo:

```bash
cp /etc/nixos/mixtape/jcard.toml ./jcard.toml
```

Key fields to fill in:
```toml
[mixtape]
image = "agent-workbench:latest"

[resources]
cpus   = 4
memory = "8G"
disk   = "20G"

[network]
mode = "bridged"   # or "isolated" for air-gapped agents

[[mounts]]
host  = "/home/goya/workspaces/<project>"
guest = "/workspace"

[secrets]
ANTHROPIC_API_KEY = { env = "ANTHROPIC_API_KEY" }
GEMINI_API_KEY    = { env = "GEMINI_API_KEY" }
```

---

### Step 5 — Initialize exomonad (orchestrator + MCP registry)

`exomonad init` creates a tmux session with the planner in one window and registers MCP tools
(`fork_wave`, `spawn_gemini`, `file_pr`, `merge_pr`, `shutdown`) in `.mcp.json`:

```bash
exomonad init
```

This creates:
- `.mcp.json` — MCP tool registry (auto-read by Claude Code)
- `.exo/server.sock` — background orchestration server
- A tmux session with a TL (Tech Lead) window

Switch into the tmux session:
```bash
tmux attach -t exomonad   # or whatever name it picks
```

---

### Step 6 — Launch sandbox and provision tools

```bash
mb up --config jcard.toml      # starts VM from base image
mb status                       # confirm sandbox is running

# First launch only — installs axon, tilth, context-mode, chainlink
mb ssh -- bash /nix-workspace/mixtape/provision.sh

mb ssh                          # shell in to verify
```

To launch multiple sandboxes (e.g., one Claude agent, one Gemini agent):
```bash
mb up --config jcard-claude.toml
mb up --config jcard-gemini.toml
mb list
```

---

### Step 7 — Start the Opus planner session

Inside the exomonad tmux TL window, invoke Claude with the MCP tools registered:

```bash
claude   # Claude Code picks up .mcp.json automatically
```

The planner now has access to:
- `fork_wave` — spawn parallel Claude agents in isolated git worktrees
- `spawn_gemini` — deploy Gemini agents
- `file_pr` / `merge_pr` — PR management
- `notify_parent` — signal back to parent agent

Axon (deep reasoning) can be added as an MCP server too:
```bash
axon serve   # exposes recursive reasoning to Claude via MCP
```

---

### Step 8 — Delegate tasks

Inside the Claude (Opus) planner session, describe the work. The planner will:

1. Read chainlink issues: `chainlink list --json`
2. Break work into parallel workstreams
3. Call `fork_wave` to spawn agent(s), each getting an issue ID and worktree path
4. Each spawned agent runs inside its own sandbox with tilth for code nav

Example planner prompt:
```
Read the open chainlink issues. Assign CHAIN-1 and CHAIN-2 to parallel agents.
Each agent should work in its own git worktree and file a PR when done.
```

---

### Step 9 — Monitor progress

```bash
mb status                    # which sandboxes are running
chainlink list               # issue state
mb ssh <sandbox-name>        # inspect a specific agent's environment
chainlink list --json | jq   # programmatic status
```

If an agent files a PR:
```bash
git log --oneline --all     # see worktree branches
gh pr list                  # if using GitHub
```

---

### Step 10 — End the session

```bash
chainlink session end --notes "completed CHAIN-1, CHAIN-2 in review"
mb down                     # stop sandboxes (keeps data)
mb destroy                  # or fully remove VMs when done
```

Session notes are stored in `.chainlink/` and surfaced next time via `ctx stats`.

---

## context-mode Integration

context-mode is an MCP server that indexes workspace state (files, git ops, task changes) into
SQLite FTS5 for compaction-resilient context retrieval.

Register it per-workspace in `.claude/settings.json`:
```json
{
  "mcpServers": {
    "context-mode": { "command": "context-mode", "args": [] }
  }
}
```

Verify inside a session: `ctx doctor` (all checks should show `[x]`).

---

## Quick Reference Cheatsheet

```bash
# New workspace
cd /etc/nixos && git pull
git clone <repo> && cd <repo>
chainlink session start
mb pull coder-x86:latest
cp /etc/nixos/mixtape/jcard.toml ./jcard.toml   # edit it
exomonad init
mb up --config jcard.toml
claude                  # start planner in exomonad tmux window

# Monitoring
mb status && chainlink list
mb ssh <name>

# Teardown
chainlink session end --notes "..."
mb down && mb destroy
```
