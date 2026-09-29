---
id: 04-reconcile-w1
title: Join wave 1
status: todo
kind: reconcile
wave: 1
blocked_by: [01-confirm-threshold, 02-score-check-helpers, 03-relevance-experiment]
sessions: []
---

## Goal

Join wave 1: the three independent slices — threshold confirmation (01), the two helpers (02), the relevance experiment (03). Read the tenth and eleventh decision notes; if 01 moved the threshold, confirm 02's tests and fixtures follow and that ticket 11/12's "≥ 0.5" wording in this plan is updated to the confirmed value (a `note` + node-file edit, local replan). Flip tickets 08–10 to `resolved`. Procedure: `skills/plans/SKILL.md` → "Run a reconcile node".

## Acceptance

- [ ] Verified on disk: every blocker's ticked box re-checked (file opened, command run, test output read); `plan.sh verify` re-run per node
- [ ] Decisions recorded: each settled fork a Tier-2 note in `decisions.md`; discoveries as `plan.sh note`; cost of every paid batch in the wave summed in this Log
- [ ] Replan applied within authority (`replan: local`), `plan.sh check` silent

## Log
