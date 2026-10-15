# Catchup prompt — Clear Session Loop (paste into a new agent session)

We're resuming clear-session-loop. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: launcher step 4 of 6 (research → verify → **spec** → HTML → pause).
`research.md` is done and verified; verdict **PARTIAL**. Write `spec.md` for the
go half only: `research.md` §7 **A** (harden the attended Claude `--clear` path) and
**B** (time-boxed headless spike). §7 **C** items are explicit non-goals. **D**
(several sessions per work item) is out of scope; just mention it as a possible
separate work item.

## First actions

1. `scripts/context-budget.sh register --project clear-session-loop` (skip if the
   SessionStart hook already bound this item).
2. Open a dispatch record:
   `scripts/fleet.sh dispatch-open --project clear-session-loop --task spec --agent-type general-purpose --model fable`.
   Include the printed contract in the child's prompt.
3. **Spec subagent (Agent tool, `model: "fable"`).** It drafts
   `work/clear-session-loop/spec-draft.md` from `research.md` (§2.2, §3, §4, §7 and the
   Verification section are the inputs), in the shape of
   `docs/agents/issue-tracker.md` → "Spec conventions" (stable S-IDs). It must cover:
   design; per-runtime behaviour + fallback (Claude only; the others stay
   fresh-process); hook contracts (SessionStart clear binding, `sessionTitle`
   if it applies interactively, SessionEnd budget, turn-end hook checks the
   record's *current* owner before SIGTERM); launch-record/state changes;
   drain-before-`--clear` rule + refusal code; interactive supervisor accepting a
   `/clear` rollover; optional PreCompact auto-block; the "types nothing" open
   question and how its answer changes docs; spike B protocol with pass/fail
   record; failure modes; test strategy (fixtures, `test-launch-next-session.sh`,
   `test-session-loop.sh`); docs touched; open questions. Only the child writes the
   draft; it must not edit anything else.
4. Close the dispatch (`scripts/fleet.sh dispatch-close … --status <S> --agent-id <id>`).
   Verify the draft's repo claims yourself. Then write `spec.md` (Status: draft)
   and delete `spec-draft.md`.
5. Render HTML twins. Create the helper: extract the `<style>` block between
   `cat > "$HEADER" <<'CSS'` and `CSS` in `scripts/build-guide-html.sh` into a
   scratch `style.html`, then
   `pandoc <in.md> -f gfm -t html5 -s --metadata pagetitle="<title>" -H style.html -o <out.html>`.
   Render `spec.html`. Re-render `research.html` only if `research.md` changed.
6. Commit the work item. Write the ledger block. Then **pause for the user's review**:
   roll over with `--loop-mode interactive`, or checkpoint. Turning the spec into
   a plan is the user's call. No-human-in-the-loop: if nobody is there, finish
   steps 1–5, commit, and stop with the review still open.

## Constraints already decided (do not re-litigate)

- Spec runs in a subagent on the **fable** model (user request).
- PARTIAL → spec covers §7 A + B only (`decisions.md` 2026-10-15).
- Portability: non-Claude runtimes keep the fresh-process path. Say so; don't design `/clear` for them.
- Markdown is the source of truth; HTML twins are reading copies.

## Do NOT reload

- The video, the runtime survey, the backlog inventory: done; they are in `research.md` §1, §5, §6.
- `initialUserMessage` for the TUI: verified `-p`-only; don't revisit.

## State snapshot

- Branch `main`; the work item was committed at the s2 rollover (not pushed; pushing is the user's call).
- `work/README.md` index row updated. Unrelated: `work/html-kit/` belongs to another session; don't touch it.

## Read these first, in order

1. `work/clear-session-loop/README.md`
2. `work/clear-session-loop/handoff.md` (top block)
3. `work/clear-session-loop/research.md` — §7 and Verification first; other sections as the spec needs them
