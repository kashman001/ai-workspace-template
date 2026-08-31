<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 13 (2026-08-31): M35 delivered — lineage-gate auto-heal, notify-on-quit, two-doors docs; arc complete

**What got done (all committed & pushed to main, worktree tm-s13-exitux):**
- Implemented exit-ux-plan.md in full, test-first, no design deviations:
  - `launch-next-session.sh` lineage gate splits the one-ahead case:
    no-trace → auto-heal (reclaim number, continue); evidence (records
    since seqf mtime / commits / dirty work item) → exit 3 with diagnosis +
    Reconstruct guidance + seq-sync alternative. Other mismatches die
    verbatim as before.
  - `session-loop.sh`: `top_ledger_seq()` helper + ledger-aware `notify`
    on the deliberate-quit path (recorded quit vs "quit WITHOUT a rollover
    or checkpoint" vs generic).
  - Docs: "How a session ends: two doors" in work-directory-conventions.md;
    context-budget.md gate + quit-notify paragraphs; CONTEXT.md pointer.
- Tests: T23e-j reworked (evidence keeps refusal), T24a-h added (heal
  dry/real, record/commit/dirty evidence — git cases in an isolated mini
  workspace), N1-N3 added. Two existing D5b cases adapted (quit now
  notifies): D5b-d asserts no STALL message instead of empty log; D5b-g's
  slow hook fast-paths "chain ended" so its timing margins still measure
  only the alarm reap. Suites: launcher 221/0 (was 207), loop 76/0 (was
  68); check-workspace-structure.sh clean.
- Backlog: M35 filed Resolved (archive Medium section); scorecard 76
  resolved, dated 2026-08-31.

**State:** arc complete; backlog 6 open / 76 resolved. No follow-ups from
this session. Context WARN fired during final verification; closed out
normally (checkpoint door).

# Session Handoff — 12 (2026-08-31): exit-UX design approved + written ahead; implementation rolls to session 13

**Summary:** Conversation session (started ad-hoc — seq-sync `raised` 11→12).
Analyzed session-end handling (what happens on exit without rollover): 9
scenarios enumerated, 3 UX gaps found (empty session poisons next launch;
work-without-rollover fails silently/misleadingly; nothing funnels to the
two end-of-session doors). User approved a 3-part fix + tests; context WARN
fired after design/discovery, so implementation rolls over.

**Shipped this session (nothing to main yet — design only):**
- `work/template-maintenance/exit-ux-plan.md` — the complete approved
  design + test plan with verified line anchors. THE artifact; successor
  implements from it without re-deriving.
- Decision note (decisions.md 2026-08-31): heal/diagnose at next launch,
  not at exit; rejected alternatives listed there.

**Key verified facts (details + more in exit-ux-plan.md):**
- Lineage gate: launch-next-session.sh:295-318; counter bump :488-490
  (AFTER gate, BEFORE mode=off exit ~:668). `note()` :67, DRY :75.
- seq-sync CAN lower (action "lowered"). Only cmd_record appends
  measurement-ledger entries — register does not (empty session ⇒ zero
  entries ⇒ heal is safe). `.session-seq` + context-ledger gitignored.
- session-loop quit branch ~:302; keep "deliberate quit" say line verbatim
  (tests L2b/C4f/L3c assert on it); notify() at :79.
- Existing tests: T23e-j must be REWORKED (they assert the old blanket-die
  on the one-ahead case); T23m/o/q/r unaffected (non-one-ahead paths).

**State:** main = d42bab7, clean except untracked exit-ux-plan.md (this
rollover commits it). No worktrees opened. Backlog 6 open / 75 resolved —
exit-ux card to be FILED by successor when delivering (not filed yet).

**Suggested skills next:** tdd (red first, per plan's slices);
superpowers:verification-before-completion before claiming suites green.

# Session Handoff — 11 (2026-08-29): L43 delivered — ledger archives fixed, lineage-restart marker shipped; arc complete

**What got done (all committed & pushed to main):**
- Re-filed the four misfiled blocks (11, 10, 9, 16) in
  `work/automatic-session-rollover/handoff-archive.md` into newest-first
  position — whole blocks moved, content untouched.
- context-decay posture settled: taught `scripts/check-ledger.py` an explicit
  `<!-- ledger-lineage-restart: … -->` marker (restarts the NUMBER chain at
  the block below; dates still check across the seam) and placed one, with a
  human-readable two-lineage explanation, at the seam in
  `work/context-decay/handoff-archive.md`. Renumbering rejected — see
  decisions.md 2026-08-29 L43 note.
- Marker documented in `docs/work-directory-conventions.md` → "Lineage
  restart (rare)"; mutation suite extended to 12/12 (restart-without-marker
  and marker-hidden-date-regression both caught).
- Repo-wide `scripts/check-ledger.py` exits 0 — first time since M32 made the
  gate honest. Backlog: L43 → archive with Fixed: note; 6 open / 75 resolved.

**State at close:** main carries the fix + this close commit; user's checkout
pulled current. Worktree `tm-s11-l43` disposable. The L43 arc (M31→M34, L41–L43)
is fully drained; no queued mission — session 12 picks from the backlog's 6
open cards.

