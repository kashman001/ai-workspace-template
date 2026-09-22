# Phase 8 — skill, docs, ADRs, ignore file, env defaults, doc-consistency test

Ticket: `work/template-improvement-review/issues/09-phase-8-skill-docs-adrs.md`.
Branch `s4-phase-8` from `stage4` at 5c7edc0. Plus the mirror removal phase 7
handed over (Concern 1), the stage4 `.claude/settings.json` clear-seed entry,
the `--clear` prompt injector (phase 5 decision 4), and two operational lines.

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Readers move to the record: `context-budget.sh supervised` reads `chain.supervisor`; the launcher's `invoked_by_supervisor` reads `chain.supervisor.pid`; `budget_hook_should_exit` and `successor_advisory` read `staged` / `staged.by` | suites red on the rewritten pins, green after |
| 2 | Writes deleted: `.session-loop` (supervisor), `.next-command` + `.session-seq.bump.json` (launcher), the `.rollover-complete` shim (hook-lib), the launcher's legacy `.chain-closed` read; `--emit` takes no path | no pin of any of them left under `scripts/tests/` |
| 3 | `$WT/.claude/settings.json`: the clear-seed `SessionStart` entry removed | `test-probe-twins.sh` (copies the file) green |
| 4 | `--clear` injector: `register` prints `launch.pending.prompt` on stdout when it binds `via=pending` | registry P6 pins it; env/project bindings print nothing |
| 5 | `.gitignore`: the record and its lock, the supervisor log, dispatch records, the two mode markers; every retired line gone | `git status` in a live-ish clone stays clean |
| 6 | `context-budget.env` comments match the design (no `--bg`, no `.active-session`) | `grep` |
| 7 | `scripts/tests/test-doc-consistency.sh`: doc ↔ scripts, both directions, verbs and reason codes | rc 0; each side's extraction documented in the script header and the doc section |
| 8 | Prose: `skills/session-rollover/SKILL.md`, `docs/context-budget.md`, `CONTEXT.md`, `docs/operational-knowledge.md` (+ the two lines of (f)), one-line fixes in `docs/work-directory-conventions.md`, `docs/mcp-setup.md`, `docs/zoom-model.md`, `docs/workspace-structure.md`, `mcp-fragments/README.md` | no retired name left outside `work/` and the ADR history |
| 9 | ADRs 0010/0011/0012 new; 0007/0008 superseded; 0004/0005/0006/0009 amended; index updated | `docs/adr/README.md` index |
| 10 | Every `scripts/tests/*.sh` + `test-check-ledger.py` green | rc lines in Evidence |

## Decisions (Tier 2 candidates; `decisions.md` is off-limits to this agent)

1. **`--emit` takes no path; the staged command lives only in the record, and `--emit` prints it as `cmd: <line>` on stdout** (the same line `--dry-run` prints). The file was `--emit`'s user-visible output and the hook's evidence; both now come from `staged.command` / `staged.by`. The old supervisor on `main` never reads stage4's files, so nothing live breaks. Rejected: keeping an optional `--emit <path>` as a convenience copy (a second copy of the command with no reader is the mirror this phase removes); printing nothing (an agent staging by hand would see only a stderr note).
2. **`supervised` keeps its three exits (0 live / 1 not / 2 ambiguous) and reads `chain.supervisor` with the supervisor's own liveness rule** (pid running and `pid_start` equal). A supervisor block whose pid is dead or restarted is ambiguous, never "not supervised", exactly as the dead-pid marker was. Rejected: collapsing to two exits (the launcher's "refuse on 0 only, warn on 2" contract and the skill's stage-anyway rule depend on the third).
3. **The launcher's bootstrap exemption tests `chain.supervisor.pid == $PPID` and alive, not `pid_start`.** A live strict parent cannot be a recycled pid. Rejected: the full pid+start rule (an extra `ps` for a case that cannot occur).
4. **The turn-end self-kill reads two record facts: `staged != null` and `staged.by == my session id`, under `TF_SESSION_LOOP=1`.** The supervisor consumes `staged` before each run, so a true match can only be this session's own stage — the same bound the file pair gave. The one-release `.rollover-complete` shim is deleted with it (two phases past its window). Rejected: also requiring a live `chain.supervisor` (the launcher's `no_supervisor` gate already refused the stage; a second liveness read in a hook that must never block a turn buys nothing).
5. **The `--clear` injector is `register` itself: when it binds `via=pending` it prints the pending prompt on stdout.** Claude Code adds `SessionStart` hook stdout to the session context (the existing `register` status line already travels that way), the settings entry already runs `register`, and the prompt is nulled with `launch.pending` in the same compare-and-set write, so an unrelated `/clear` later cannot re-seed. Smallest thing that works: no new hook, no file, no vendor JSON. Rejected: a second `SessionStart` entry emitting `hookSpecificOutput.additionalContext` (a hook and a settings entry for one `echo`); the supervisor (never has a pending block, phase 5 decision 4). Gap: whether the cleared Claude session shows the line as context is unverified without a real `/clear`; the stub twin pins the stdout.
6. **The doc-consistency test reads one doc section and two script surfaces.** Doc side: every backticked token under `## Verbs and reason codes` in `docs/context-budget.md` (verb table + code table). Script side: verbs are the `<name>) cmd_…` arms of the dispatch `case` in `context-budget.sh` and `fleet.sh`; codes are every `refuse|broken|verdict <code>`, `reason=|verdict=|page=<code>`, `${x:-<code>}` fallback, `action="<code>"` and `v=quit_…` literal in `scripts/*.sh`, `scripts/hooks/*.sh`, `scripts/lib/*.sh`. Both directions must be empty diffs. Rejected: a machine-readable code list in a data file both sides read (a third copy to drift); grepping the whole doc (prose mentions of `open`, `check` etc. are not codes).
7. **The "three change-log entries still saying Open" do not exist on stage4** — the stage-1 re-evaluation (`evaluation/stage1-reevaluation-vs-main.md`, F8) already found the claim wrong; `grep -n '\bOpen\b'` on stage4's and main's `docs/context-budget.md` finds none. The two `> **Status:** implemented …` change-log blocks are rewritten to the record vocabulary instead. Rejected: inventing three entries to close.
8. **ADR set: three new, four amended, two superseded.** ADR-0010 *One session-state record per work item, three writers* (supersedes 0007 and 0008's mechanism; keeps their canonical-number and assert-not-write rulings by reference). ADR-0011 *Mechanical gates and reason codes*. ADR-0012 *Runtime contract: adapter table, support matrix, fleet isolation*. Amended by a dated note: 0004 (lock → record owner, liveness = pid, no per-project override → per-item env file, `--bg` gone), 0005 (roles/lineage superseded by 0010; child registry moved to `fleet.sh` unchanged), 0006 (the "no shared lib" consequence replaced by `scripts/lib/session-lib.sh`), 0009 (open item closed by probe A — `/clear` rotates the transcript; seed folded into `launch.pending`; `--bg`, `--unstage`, `seq-sync` gone). Rejected: one omnibus ADR (three decisions with three different rejected-alternative sets); leaving 0004/0005 untouched (they would contradict 0010 on the index).
9. **`.gitignore` names each written file explicitly.** `work/*/session-state.json`, `work/*/session-state.json.lock/` (the lib's mkdir lock), `work/*/.session-loop.log`, `work/*/.agent-dispatch/`, `work/*/.hands-off`, `work/*/.interactive`. Rejected: `work/*/session-state.json*` (hides what the lib writes); keeping retired lines "just in case" (a downloader reads the ignore file as the state-file list).
10. **Vendor configs keep the shim paths.** The optional cleanup (phase 6 decision 8) is skipped: repointing `.codex/config.toml` re-prompts codex's hook trust hash for every existing checkout, and the shims are one `exec` line each. Rejected: doing it now for symmetry.

## Evidence

(filled at the end)

## Concerns for the parent

(filled at the end)

## Questions for the user

(none so far)
