<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 23 (2026-09-22): post-commit verification: every suite green after 9bac406/aa25002; leftover old-script files deleted on the human's yes; closed through the stop door

**Summary.** Attended, one agent. `register` → `seq=23 via=project
(refreshed)` (M39 fix confirmed live: the stop-door close of 22 minted 23,
no addendum needed). Ran all 23 `scripts/tests/test-*.sh` suites and
`test-check-ledger.py` (13/13): no failure, so nothing traced to the two
commits. `import-session-seq.sh --status`: every item fresh or new, exit 0.
Asked the human about the leftovers; on "delete all" removed the six
untracked `.rollover-options` (automatic-session-rollover, context-decay,
devex-review, sdlc-ai-mapping, template-maintenance, usage-scenarios) and
the gitignored `work/template-maintenance/.session-loop.log` (last written
Sep 3). `--status` now shows `leftovers=-` on all 12 items. Session 21
block archived. Closed via `close`.

**Findings.**
- The session 22 launcher said seven `.rollover-options` and that `--status`
  lists `.session-loop.log`; in fact six existed, and `--status` never
  reports the log (it is gitignored and the current `session-loop.sh` still
  writes the same file, so it is not an old-script marker). Counting error
  in the launcher, not a script defect.

**Decisions.** None new.

**Open / next.** Nothing in this item. Outside scope, unchanged:
`attach-session.sh` and `statusline-context-budget.sh` still read
`.active-session`; no template version marker exists.

# Session Handoff — 22 (2026-09-22): addendum: human redirected after the close; six items imported, import script kept with a `--status` classifier, ticket 10 done

**Summary.** After the stop-door close the human asked (attended) to run
the import on all six items and to keep the import script: downstream
workspaces pulling the new scripts carry old-counter work items too. Done:
`import-session-seq.sh` on automatic-session-rollover (32), context-decay
(7), devex-review (8), learn-agentic-workflows (3), template-maintenance
(16), usage-scenarios (6); a second run is `noop`. Old counters backed up
to the scratchpad and deleted per the doc ("the counter is then deleted").
The human also asked the script to tell three shapes apart — never ran
`session-loop.sh`, ran the old one, ran the current one — so `--status
[<project>]` was added (states fresh / old / imported / new / conflict /
unreadable, `loop=` for which generation of the loop ran, `leftovers=` for
the dead files, exit 1 when anything still needs the import); tests I10;
migration table in `docs/context-budget.md` → "Migrating work items from
the old scripts". Ticket 10 last box rewritten and ticked, status `done`.
Backlog: L47 (resolved, archived); M39 opened, then fixed on the human's
call the same session (`minted`: a stop-door owner yields `seq + 1`, test
R6i–k, one sentence in each doc). No rollover: the record was
already closed; this block is an addendum, not a new number.

**Findings.**
- No template/framework version marker exists anywhere; the only versioned
  thing is the record's `schema: 1`. The migration does not need one (the
  files are self-describing), but downstream upgrades in general would
  benefit from a workspace-level version — the human's call, not opened.
- M39: `bind_record` adopts a dead owner's number whatever door it left by,
  so an attended `register --project` after a stop-door `close` re-binds
  the closed session's number and the ledger check then wants an addendum
  block. The supervisor path mints the next number (`stopped`). Doc line
  "never reused" disagrees with the attended path. Finding only.
- `launch-next-session.sh --emit` refused `ledger_shape` on a `# Session
  Handoff addendum — 22` heading that `check-ledger.py` accepts; the shell
  parser `top_ledger_session` knows only the plain form. Retitled the block
  to `# Session Handoff — 22 (…): addendum: …`. Finding only.
- Three of the six counters were one ahead of their ledger top (the last
  session registered but never wrote its block); the import reproduces that
  session's number, which is the `adopted`/`filled` rule anyway.

**Decisions.** Keep the import script (human). Rejected: retiring it per
the original ticket 10 wording — downstream workspaces need it.

**Learnings:**
- The doc-consistency suite extracts `reason=`/`action="` tokens from every
  script; new key=value output must avoid those two keys or be documented.

**Open / next.** Nothing in this item. Leftover old files (`.rollover-options`
in seven items, `.session-loop.log` in template-maintenance) are untracked
noise nothing reads; `--status` lists them. M39 and the `.active-session`
readers are outside this item.

# Session Handoff — 22 (2026-09-22): post-cap restart; retire-import follow-up checked and found blocked (six items still on the old counter); closed through the stop door

**Summary.** No agents; hands-off session started by the human via
`session-loop.sh template-improvement-review --reset-cap`. `register` →
`seq=22 via=project (refreshed)`, 59K at register. Checked the one open
follow-up's precondition (ticket 10, last box): every live item with a
`.session-seq` must be imported before `import-session-seq.sh` is retired.
Six are not — none has a `session-state.json`: automatic-session-rollover
(old 32), context-decay (7), devex-review (8), learn-agentic-workflows (3),
template-maintenance (16), usage-scenarios (6). The launcher's list named
sdlc-ai-mapping instead of learn-agentic-workflows; sdlc-ai-mapping carries
only `.rollover-options`, no counter. Nothing retired; ticket 10 stays
`ready-for-agent` with one box open. Ledger block 20 archived; tracker
"Now" and launcher corrected. Ended with `record` then
`context-budget.sh close` (stop door), no rollover.

**Findings.** None new. The stale item name in the launcher was a
transcription slip in session 21, not a script fault.

**Decisions.** None new.

**Learnings:**
- The import precondition is cheap to verify: `ls work/*/.session-seq` plus
  a check for a sibling `session-state.json` per item.

**Open / next.** Same as before: retire `scripts/import-session-seq.sh`,
`scripts/tests/test-import-session-seq.sh`, and its "Reason codes" row in
`docs/context-budget.md` once the six items above are imported (the human
or their own sessions run `scripts/import-session-seq.sh <project>` on
each). Outside scope: `attach-session.sh` and
`statusline-context-budget.sh` still read `.active-session`.

