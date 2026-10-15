# Catchup prompt — Clear Session Loop (paste into a new agent session)

We're resuming clear-session-loop. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: launcher step 5 of 6 (research → verify → spec → HTML → **pause for review**).
`spec.md` and `spec.html` are written and committed (Status: draft). The user now
reviews them. This session is interactive: a human is at the keyboard.

## First actions

1. `scripts/context-budget.sh register --project clear-session-loop` (skip if the
   SessionStart hook already bound this item).
2. Ask the user, **verbatim**, this open question:

   > The spec is ready for your review: `work/clear-session-loop/spec.html`
   > (source `spec.md`). Six design calls are the subagent's and need your OK or
   > change — (1) `--clear` refuses with exit 4 `dispatch_open` while a dispatched
   > subagent is open; (2) a new record counter `chain.clears` lets the
   > interactive supervisor accept `/clear` hops; (3) `--clear` under a supervisor
   > only in interactive mode; (4) the Stop hook checks the record's current
   > owner before killing; (5) PreCompact auto-block is opt-in, off by default;
   > (6) `sessionTitle` only if probe A2 shows it works. Approve, change, or
   > discuss?

   Grill one question at a time if they want to discuss.
3. Fold their answers into `spec.md` (record each choice with a rejected
   alternative in `decisions.md`), re-render `spec.html` (helper below), and set
   `Status:` per their call (`approved` + `Approved-by:` only if they say so).
4. Turning the spec into a plan (`/plan`) is the user's call. Ask; don't assume.

HTML helper: extract the `<style>` block between `cat > "$HEADER" <<'CSS'` and
`CSS` in `scripts/build-guide-html.sh` into a scratch `style.html`, then
`pandoc spec.md -f gfm -t html5 -s --metadata pagetitle="Spec — clear-session-loop" -H style.html -o spec.html`.

## Constraints already decided (do not re-litigate)

- PARTIAL → spec covers research §7 A + B only (`decisions.md` 2026-10-15); C items are non-goals, D is a possible separate work item.
- Non-Claude runtimes keep the fresh-process path.
- Markdown is the source of truth; HTML twins are reading copies.

## Do NOT reload

- The video, the runtime survey, the backlog inventory (`research.md` §1, §5, §6).
- `research.md` in full — the spec's Verification section and `research.md` §7 are enough unless the user asks.

## State snapshot

- Branch `main`; work item committed through the s3 rollover (not pushed; pushing is the user's call).
- Unrelated: `work/html-kit/` belongs to another session; don't touch it.

## Read these first, in order

1. `work/clear-session-loop/handoff.md` (top block)
2. `work/clear-session-loop/spec.md` — Design overview, Requirements, Verification
