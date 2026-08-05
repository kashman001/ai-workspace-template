<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-05 (follow-up: claude-handoff comparison; launch-next-session.sh mission queued; STOP rollover)

**Trigger:** user-requested rollover; budget hit STOP (150K) as it started.
Same session as the hardening execution below, continued interactively.

**What happened after the hardening close-out:**
- Compared upstream `claude-handoff` (in-progress bucket, clone `8b36d4f`,
  18 lines) against `session-rollover` — the comparison the recon note had
  skipped. Verdict: its three content rules already landed via the inlined
  hand-off contract (hardening item 5); its prompt-only background-handoff
  mechanism stays rejected; the one adopted concept is launch acceleration.
- User approved building `scripts/launch-next-session.sh` (multi-runtime,
  vendor specifics confined to the script per CLI-first). Full mission spec +
  verdict + implementation notes queued in `next-session.md`, pushed
  (`01a851c`) — read that, not this, for what to build.
- **Open question, paused mid-answer:** how to start the implementing session
  — a `claude --bg` background demo of the concept vs interactive
  implementation. The user chose "roll over and continue the discussion".
  Resume that question before implementing.
- No code written this segment; only launcher/ledger bookkeeping mutated.

---

# Session Handoff — 2026-08-05 (skill-hardening plan EXECUTED; all 8 items shipped)

**Trigger:** mission complete — the full `skill-hardening-plan.md` executed and
pushed to `main`; work-unit boundary at ~110K tokens (OK).

**What shipped (three commits on `main`; see `git log` for shas):**
1. Items 1–7 — skill fixes: checkpoint's promotion scan now also sweeps
   `work/*/map.md` Decisions-so-far (cross-ref in decision-log); onboard-repo's
   budget cadence moved above its steps; convention pointers unified on
   `CONTEXT.md` (rlm, issue-tracker.md); create-work-item optional files gained
   `spec.md`/`map.md`/`issues/`; runnable Verification sections added to
   checkpoint / create-work-item / session-rollover / decision-log; identical
   "Which boundary skill?" first-yes-wins block in checkpoint +
   session-rollover; global-`handoff` prerequisite replaced by an inlined
   3-rule hand-off contract in both; `disable-model-invocation: true` on
   create-work-item / onboard-repo / rlm; ADR bar restated as the three-way
   AND test in decision-log + `docs/adr/README.md` with a "don't log this"
   counter-example.
2. Item 8 — vendored `skills/writing-for-agents/` (SKILL.md +
   SKILL-MECHANICS.md + agents/openai.yaml) at pin `8b36d4f`, provenance
   comment mirroring wayfinder's; diff vs upstream verified comment-only.
   Wired: CONTEXT.md bullet (+ checkpoint bullet updated for the arbitration/
   contract changes), recommended-tooling §3 blockquote now covers both
   vendored skills.
3. Item 9 — backlog changelog row for the whole batch; Tier-2 note for the
   inline-handoff-contract decision appended to `decisions.md`; this ledger/
   launcher rollover.

**Verification done:** per-item greps from the plan; diff-vs-upstream for the
vendored skill; `bash -n scripts/*.sh` clean; each edited SKILL.md re-read
top-to-bottom (one drift caught: checkpoint Outputs still naming the handoff
skill's default location — fixed).

---
