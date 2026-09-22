
## [gen 1] 2026-09-21 — plan written

- Finished: targeted reads (ticket, phase 4/5/7 plans, findings' ADR table + phase-8 paragraph, design-v2 summary, ADR format, the doc, the skill, every mirror reader and test pin, settings.json, gitignore, env). Plan file `work/template-improvement-review/plans/phase-8.md` written with 10 decisions (ADR set = new 0010/0011/0012; 0007/0008 superseded; 0004/0005/0006/0009 amended).
- Finding: the "three change-log entries still saying Open" do not exist on stage4 or main (`grep -n '\bOpen\b' docs/context-budget.md` empty; stage-1 re-evaluation F8 already retracted it). Nothing to close; recorded as decision 7.
- Next: commit the plan; mirror removal test-first (readers to the record, then delete the writes and `--emit`'s path).
- Open: none.

## [gen 1] — mirrors removed, config, doc, skill done

- Finished (commits on s4-phase-8): 12ba7d8 mirror removal (readers on the record, writes deleted, --emit bare + `cmd:` line, --loop-reason -> launch.reason; six suites red-then-green); f685889 settings.json clear-seed entry removed, register prints the /clear seed (P6f/P6g), .gitignore + env comments; 8c3d6d9 docs/context-budget.md rewritten + scripts/tests/test-doc-consistency.sh (12 verbs, 43 codes, both ways, green); skill rewritten (this commit).
- Next: CONTEXT.md, operational-knowledge (+ the two (f) lines), one-line fixes in four secondary docs, then ADRs 0010/0011/0012 + amendments + index; full suite run; evidence.
- Open: none.

## [gen 1] — final

- Finished: 7 commits on s4-phase-8 (f381eb0 plan; 12ba7d8 mirrors removed; f685889 settings/injector/gitignore/env; 8c3d6d9 doc + doc-consistency test; 7512cf2 skill; 4621ae7 docs + ADRs 0010/0011/0012 + amendments + index; e84ac10 plan evidence). Tree clean. Every suite rc=0 (23 `scripts/tests/*.sh` + test-check-ledger.py), logs in the scratch dir; doc-consistency test: 12 verbs, 43 codes, both directions empty.
- Ticket 09 checkboxes: doc-consistency test — done; skill on existing verbs/codes — done; ADRs (promoted, counter ADRs superseded, /clear item closed on probe A) — done; ignore file — done; env defaults + suites green — done. The "three Open change-log entries" do not exist (stage-1 re-evaluation F8 retracted the claim) — recorded, not fabricated.
- Concerns (plan file, "Concerns for the parent"): --emit takes no path (cutover lands launcher+supervisor together); the /clear injector (register prints the pending prompt on stdout) is unverified against a real Claude /clear — one attended try on the cutover, fallback named; launch.reason is a small schema addition; attach-session.sh and the statusline still read .active-session (out of scope, follow-up); vendor configs keep the shims.
- Open: none for this phase.
