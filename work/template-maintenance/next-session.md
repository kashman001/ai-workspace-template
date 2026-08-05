> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

Build **`scripts/launch-next-session.sh`** — a one-command replacement for
manually copy-pasting the rollover bootstrap prompt, user-approved 2026-08-05.
Usage: `launch-next-session.sh <project> [--runtime claude|codex|gemini|opencode]
[--bg]`. It builds the canonical bootstrap prompt ("Read
`work/<project>/next-session.md` and continue from **First actions**.") and
launches the chosen runtime seeded with it — interactive by default, background
with `--bg` where the runtime supports it (`claude --bg --name`). Vendor
specifics live ONLY in this script (CLI-first rule); `session-rollover`'s
closing step gains one runtime-neutral pointer line to it.

Origin: comparison of upstream `claude-handoff` (in-progress bucket, clone
`8b36d4f`, 18 lines) vs our `session-rollover`. Verdict — its three content
rules already landed via the inlined hand-off contract (hardening item 5); its
prompt-only background-handoff *mechanism* stays rejected (loses
disk-as-source-of-truth; Claude-only); the one adopted concept is
launch-acceleration. Record this as a Tier-2 note in `decisions.md` when
implementing (rejected alternatives: adopting claude-handoff wholesale;
inlining vendor commands in the skill).

Implementation notes:
- VERIFY every launch flag against the installed CLI's `--help` — do not trust
  remembered flags. Likely forms: `claude "<p>"` / `claude --bg --name "<n>"
  "<p>"`; `codex "<p>"` / `codex exec "<p>"`; `gemini -i "<p>"` / `gemini -p
  "<p>"`; `opencode run "<p>"` (opencode absent on this machine — mark that
  path best-effort/untested).
- Fail with a clear message if the work dir or launcher file is missing;
  `bash -n` + a `--help`/dry-run check; document in
  `docs/workspace-structure.md` scripts list + backlog changelog row.
- Standing push-to-main approval applies to this work.

## Read these, in order

1. `skills/session-rollover/SKILL.md` — the closing step the script hooks into.
2. `work/template-maintenance/handoff.md` (top block) — what last shipped.

## Do NOT reload

- `skill-hardening-plan.md` — fully executed; provenance only.
- Upstream `claude-handoff` SKILL.md — fully summarized above; nothing else in it.
- `handoff-archive.md` — older session history.

## State snapshot

- Branch `main`, clean and pushed after the skill-hardening commits.
- Vendored skill pins: `wayfinder` and `writing-for-agents` both at upstream
  `8b36d4f` (clone: `~/Developer/references/mattpocock-skills`).
- Installed CLIs on this machine: claude, codex, gemini; opencode absent.

## First actions

1. `scripts/context-budget.sh register`
2. Implement the script per the Mission notes; verify; wire the skill pointer;
   Tier-2 note; commit with `Decision:` trailer; push.
