# 10 — Session numbering: one source of truth

**Opened:** 2026-08-06 (session 29, user-requested). **Status:** OPEN.

## Problem

Three independent session-number sources drifted apart, confusing the user
(live incident, session 29):

1. `work/<proj>/.session-seq` — machine-local counter, launcher-maintained;
   feeds the bootstrap prompt's "session #N" and claude `--name`.
2. `handoff.md` ledger block titles — agent-written prose ("session 28: …").
3. Worktree/branch names — agent-chosen (`session-29-issue-01-build`).

Observed drift: the session launched by prompt "#28" was ledger-#29 (seq
trails ledger by one). Likely origin: a session launched without
`launch-next-session.sh` (hand-pasted prompt, no seq increment) or a late/
wrong seed of `.session-seq`; unconfirmed — check `git log` on handoff.md
titles vs seq history if it matters.

## Decision to make (with the user)

Pick ONE source; make the others derive from it. Leanings to stress-test:

- **Lean: `.session-seq` is canonical.** Sessions take their number from
  their own bootstrap prompt (which the launcher derives from seq) and use
  it verbatim in ledger block titles and worktree names — never re-derive
  from ledger prose. Ledger/seq disagreement = repair the ledger note, seq
  wins.
- Enforcement candidates (keep minimal, pick what's cheap): a line in the
  work-directory conventions + session-rollover skill ("your number = the
  prompt's number"); optionally `register` warning when the newest handoff
  block title ≠ prompt number (parse cost vs. value — may be YAGNI).
- Rejected-alternative candidates: committing `.session-seq` (machine-local
  by design — clones/multi-machine would fight); deriving the prompt number
  by parsing `handoff.md` prose (fragile).
- Repair now: realign seq (user one-liner from session-29 handoff sets it
  to 29; if the successor launches before that runs, its prompt says #29
  while it is ledger-#30 — reconcile once, then the rule prevents
  recurrence). Record the decision per `decision-log` (Tier 2; promote if
  it changes committed conventions).

## Done when

- One canonical source decided + recorded (decisions.md, and convention doc
  if committed behavior changed); ledger/seq/worktree naming realigned; the
  rollover skill/launcher docs state the rule.
