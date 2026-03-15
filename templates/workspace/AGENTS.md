# Agent Task Instructions

## Task ID
<!-- JIRA issue key, e.g. MYPROJ-42 -->

## Scope
<!-- Files and directories this agent is responsible for.
     DO NOT modify files outside this scope without checking with the planner.

     Example:
       src/auth/          — implement the auth module
       tests/auth/        — write tests for your implementation
       Cargo.toml         — add dependencies if needed
-->

## Acceptance Criteria
<!-- What does "done" look like? Be specific.

     Example:
       - All functions in src/auth/ are implemented
       - `cargo nextest run --test-threads 4` passes with 0 failures
       - No clippy warnings: `cargo clippy -- -D warnings`
       - RESULT.md written summarizing what was implemented
-->

## Constraints
<!-- Architecture decisions already made. Do not relitigate these.

     Example:
       - Auth uses JWT (not session cookies) — this is decided, do not change
       - No new external crates without checking with the planner
       - Public API signatures must match the interface in src/auth/mod.rs
-->

## Context
<!-- Additional background the agent needs to understand the task.

     Example:
       - The existing auth stub is in src/auth/mod.rs — extend it
       - The database layer is in src/db/ — use it for user lookup
       - The Gemini agent (agent-b) is handling the API layer in parallel
-->

## How to Report Back

1. Write your implementation to the scope directories above
2. Run tests:
   - Rust: `cargo nextest run`
   - Python: `python -m pytest`
3. Write a summary to `/home/agent/workspace/RESULT.md`:
   ```
   ## Result

   ### What was implemented
   ...

   ### Test results
   ...

   ### Decisions made
   ...

   ### Known limitations / follow-up needed
   ...
   ```
4. If blocked, write to `/home/agent/workspace/BLOCKED.md`:
   ```
   ## Blocked

   ### Blocker description
   ...

   ### What I tried
   ...

   ### What I need to unblock
   ...
   ```
