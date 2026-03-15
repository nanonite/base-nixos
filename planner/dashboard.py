"""
dashboard.py — Marimo observability dashboard for the agentic coding platform

Reads from:
  1. JIRA API (via go-jira / requests) — task status, assignments, blockers
  2. ./benchmark-results/ directory — agent output metrics (benchmark mode)

Launch:
  marimo run planner/dashboard.py          # read-only, auto-refresh
  marimo edit planner/dashboard.py         # interactive editing

Panels:
  - Task tree: Epic → Stories → Sub-tasks, status, assigned agent
  - Conflict detector: Stories touching same files (prevents agent collisions)
  - Agent workload: active task count per agent
  - Benchmark comparison: quality / speed / cost side-by-side (benchmark mode)
  - Architecture health: file ownership map, coupling metrics
"""

import marimo as mo
import os
import json
import subprocess
from pathlib import Path
from datetime import datetime

import pandas as pd
import altair as alt

app = mo.App(width="full")


# ── Config ────────────────────────────────────────────────────────────────────

@app.cell
def config():
    JIRA_ENDPOINT = os.getenv("JIRA_ENDPOINT", "https://yourorg.atlassian.net")
    JIRA_PROJECT  = os.getenv("JIRA_PROJECT",  "MYPROJ")
    JIRA_TOKEN    = os.getenv("JIRA_API_TOKEN", "")
    BENCHMARK_DIR = Path(os.getenv("BENCHMARK_RESULTS_DIR", "./benchmark-results"))
    WORKSPACE_DIR = Path(os.getenv("WORKSPACE_DIR", "."))
    return JIRA_ENDPOINT, JIRA_PROJECT, JIRA_TOKEN, BENCHMARK_DIR, WORKSPACE_DIR


# ── JIRA data fetching ────────────────────────────────────────────────────────

@app.cell
def fetch_jira_issues(JIRA_ENDPOINT, JIRA_PROJECT, JIRA_TOKEN):
    """Fetch all issues for the project via go-jira CLI (avoids Python JIRA lib deps)."""
    import shutil

    if not shutil.which("jira"):
        mo.callout(
            mo.md("**go-jira not found.** Install via `pkgs.go-jira` or run `nix develop`."),
            kind="warn",
        )
        return pd.DataFrame()

    try:
        result = subprocess.run(
            ["jira", "issue", "list", "--project", JIRA_PROJECT, "--output", "json"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            mo.callout(mo.md(f"JIRA error: `{result.stderr}`"), kind="danger")
            return pd.DataFrame()

        raw = json.loads(result.stdout)
        issues = [
            {
                "key":      i.get("key"),
                "summary":  i.get("fields", {}).get("summary", ""),
                "type":     i.get("fields", {}).get("issuetype", {}).get("name", ""),
                "status":   i.get("fields", {}).get("status", {}).get("name", ""),
                "assignee": (i.get("fields", {}).get("assignee") or {}).get("displayName", "unassigned"),
                "agent_id": i.get("fields", {}).get("customfield_10001", ""),
                "worktree": i.get("fields", {}).get("customfield_10003", ""),
                "updated":  i.get("fields", {}).get("updated", ""),
            }
            for i in raw.get("issues", [])
        ]
        return pd.DataFrame(issues)
    except Exception as e:
        mo.callout(mo.md(f"Failed to fetch JIRA issues: `{e}`"), kind="danger")
        return pd.DataFrame()


# ── Task tree ─────────────────────────────────────────────────────────────────

@app.cell
def task_tree_panel(fetch_jira_issues):
    df = fetch_jira_issues
    if df.empty:
        return mo.callout(mo.md("No JIRA issues found or JIRA not configured."), kind="warn")

    mo.vstack([
        mo.md("## Task Tree"),
        mo.ui.table(
            df[["key", "type", "summary", "status", "assignee", "worktree"]],
            selection=None,
        ),
    ])


# ── Agent workload ────────────────────────────────────────────────────────────

@app.cell
def agent_workload_panel(fetch_jira_issues):
    df = fetch_jira_issues
    if df.empty:
        return mo.md("No data.")

    active = df[df["status"].isin(["In Progress", "In Review"])]
    workload = active.groupby("agent_id").size().reset_index(name="active_tasks")

    chart = (
        alt.Chart(workload)
        .mark_bar()
        .encode(
            x=alt.X("agent_id:N", title="Agent"),
            y=alt.Y("active_tasks:Q", title="Active Tasks"),
            color=alt.Color("agent_id:N", legend=None),
            tooltip=["agent_id", "active_tasks"],
        )
        .properties(title="Agent Workload", width=400, height=200)
    )

    mo.vstack([
        mo.md("## Agent Workload"),
        mo.ui.altair_chart(chart),
    ])


# ── Conflict detector ─────────────────────────────────────────────────────────

@app.cell
def conflict_detector_panel(fetch_jira_issues, WORKSPACE_DIR):
    """Highlight Stories whose worktrees touch overlapping files."""
    df = fetch_jira_issues
    active_stories = df[
        (df["type"] == "Story") &
        (df["status"] == "In Progress") &
        (df["worktree"].str.len() > 0)
    ]

    if active_stories.empty:
        return mo.callout(mo.md("No active Stories with worktrees — no conflicts to detect."), kind="success")

    # Check each worktree for changed files
    conflicts = []
    worktree_files: dict[str, set] = {}

    for _, row in active_stories.iterrows():
        wt_path = WORKSPACE_DIR / "worktrees" / row["worktree"]
        if not wt_path.exists():
            continue
        try:
            result = subprocess.run(
                ["git", "diff", "--name-only", "HEAD"],
                capture_output=True, text=True, cwd=wt_path, timeout=5
            )
            files = set(result.stdout.strip().splitlines())
            worktree_files[row["key"]] = files
        except Exception:
            pass

    # Find overlapping files between worktrees
    keys = list(worktree_files.keys())
    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            overlap = worktree_files[keys[i]] & worktree_files[keys[j]]
            if overlap:
                conflicts.append({
                    "story_a": keys[i],
                    "story_b": keys[j],
                    "files":   ", ".join(sorted(overlap)),
                })

    if not conflicts:
        return mo.callout(mo.md("No file conflicts detected between active worktrees."), kind="success")

    return mo.vstack([
        mo.callout(
            mo.md(f"**{len(conflicts)} conflict(s) detected** — agents are touching the same files."),
            kind="danger",
        ),
        mo.ui.table(pd.DataFrame(conflicts), selection=None),
    ])


# ── Benchmark comparison ──────────────────────────────────────────────────────

@app.cell
def benchmark_panel(BENCHMARK_DIR):
    if not BENCHMARK_DIR.exists():
        return mo.callout(
            mo.md("No benchmark results yet. Run: `BENCHMARK_MODE=1 mb up --config agent-sandbox/jcard-benchmark.toml`"),
            kind="info",
        )

    rows = []
    for agent_dir in sorted(BENCHMARK_DIR.iterdir()):
        if not agent_dir.is_dir():
            continue
        metrics_file = agent_dir / "metrics.json"
        if not metrics_file.exists():
            continue
        with metrics_file.open() as f:
            m = json.load(f)
        rows.append({
            "agent":         agent_dir.name,
            "wall_time_s":   m.get("wall_time_s", 0),
            "lines_changed": m.get("lines_changed", 0),
            "test_pass_rate": m.get("test_pass_rate", 0.0),
            # token fields added once token-monitor is integrated:
            "input_tokens":  m.get("input_tokens", "—"),
            "output_tokens": m.get("output_tokens", "—"),
        })

    if not rows:
        return mo.callout(mo.md("Benchmark directory exists but no metrics.json files found."), kind="warn")

    df = pd.DataFrame(rows)

    time_chart = (
        alt.Chart(df)
        .mark_bar()
        .encode(
            x="agent:N",
            y=alt.Y("wall_time_s:Q", title="Wall time (s)"),
            color="agent:N",
            tooltip=["agent", "wall_time_s"],
        )
        .properties(title="Wall-clock Time", width=250, height=200)
    )

    quality_chart = (
        alt.Chart(df)
        .mark_bar()
        .encode(
            x="agent:N",
            y=alt.Y("test_pass_rate:Q", title="Test pass rate", scale=alt.Scale(domain=[0, 1])),
            color="agent:N",
            tooltip=["agent", "test_pass_rate"],
        )
        .properties(title="Test Pass Rate", width=250, height=200)
    )

    return mo.vstack([
        mo.md("## Benchmark Comparison"),
        mo.hstack([mo.ui.altair_chart(time_chart), mo.ui.altair_chart(quality_chart)]),
        mo.ui.table(df, selection=None),
    ])


# ── Architecture health ───────────────────────────────────────────────────────

@app.cell
def architecture_health_panel(WORKSPACE_DIR):
    """File ownership map and hotspot detection via git log."""
    try:
        result = subprocess.run(
            ["git", "log", "--name-only", "--format=", "--since=30.days", "--diff-filter=M"],
            capture_output=True, text=True, cwd=WORKSPACE_DIR, timeout=10
        )
        files = [f for f in result.stdout.strip().splitlines() if f]
        from collections import Counter
        hotspots = Counter(files).most_common(20)
        df = pd.DataFrame(hotspots, columns=["file", "change_count"])

        chart = (
            alt.Chart(df)
            .mark_bar()
            .encode(
                x=alt.X("change_count:Q", title="Changes (30d)"),
                y=alt.Y("file:N", sort="-x", title="File"),
                tooltip=["file", "change_count"],
            )
            .properties(title="Hotspot Files (last 30 days)", width=500, height=350)
        )

        return mo.vstack([
            mo.md("## Architecture Health — Hotspots"),
            mo.ui.altair_chart(chart),
        ])
    except Exception as e:
        return mo.callout(mo.md(f"Could not compute hotspots: `{e}`"), kind="warn")


# ── Header ────────────────────────────────────────────────────────────────────

@app.cell
def header():
    return mo.vstack([
        mo.md(f"# Agentic Coding Platform Dashboard"),
        mo.md(f"*Last refreshed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*"),
        mo.md("---"),
    ])


if __name__ == "__main__":
    app.run()
