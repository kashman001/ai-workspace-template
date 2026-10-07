# Decisions — context-memory-hardening

Tier-2 notes (see `skills/decision-log/SKILL.md`). Newest last.

## 2026-10-07 — L49 date rule warns, it doesn't fail

`check-workspace-structure.sh` warns on a date-like line in `CONTEXT.md`.
A static date doesn't break the prompt cache; only changing text does.
Rejected: a hard fail, which would block legitimate dated references in
downstream workspaces. Commit `9996954`.

## 2026-10-07 — L49 Claude register line left as is

The `SessionStart` status line carries a per-session `artifact=` path, but it
lands after the first message's git status and prompt, which already vary per
session. Rejected: quieting it, which buys no cache hit and drops a
registration confirmation. Commit `9996954`.

## 2026-10-07 — L50 share denominator is the measured context total

`cache_read_share` = cache-read tokens / the context total the budget already
measures, for every runtime. Rejected: per-runtime input-only ratios, which
would make rows from different runtimes incomparable. Commit `0e489b5`.
