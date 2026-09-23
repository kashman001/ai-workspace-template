# 06 — Tiers: policy table, `auto` resolution, per-runtime model mapping

**What to build:** A workspace tier policy file (kind of leaf work → tier) with a per-plan override and the wave default as fallback; `show`/`frontier` print the resolved tier for `auto` nodes and the fan-in rule (reconcile and hitl default to frontier). A per-runtime env mapping beside `context-budget.env` turns tier names into model knobs; a runtime with no knob resolves to the session model and the Log line says the tier was unavailable.

**Blocked by:** 01

**Status:** ready-for-agent

**Spec:** S6, S7

- [ ] Resolution order tested: node tier → plan override → workspace table → wave default
- [ ] Mapping file documented per runtime (claude, codex, gemini, opencode, copilot) with the unavailable case
- [ ] No concrete model name appears in any plan or node file
