# 04 — CLI widened to three question types, `jev` skill, vendored TypeSafe skill, always-on rule

**What to build:** An agent in any runtime reads one short rule in the workspace context, runs `scripts/jev.sh --help`, and can ask a Choice, Score, or Noul question correctly without loading anything else; when it wants the detail, the `jev` skill is one load away, with TypeSafe's own agent skill vendored beside it. The CLI refuses a request that breaks the published limits before sending it and reports vendor errors as their own exit code.

**Blocked by:** 01 — Gate, `jev.sh` CLI (Choice), and the offline test.

**Status:** ready-for-agent

**Spec:** S5, S7, S17, S18

- [ ] `scripts/jev.sh --help` documents the three question types with one worked example each, the exit codes, the key resolution order, and the limits; no skill needs loading to use it
- [ ] Score and Noul questions pass through and print their typed answers (Score: score + confidence; Noul: probability, no confidence)
- [ ] Client-side refusal (exit 2, before any request) for more than 255 Choice options or an estimated state-plus-longest-question over 32k tokens; a non-200 response exits 4 with the status and the first 300 bytes of the body on stderr
- [ ] `skills/jev/SKILL.md` (demand-loaded, runtime-neutral) carries the request shape, the `other` pattern, threshold guidance, the limits, cost, and the no-key contract; TypeSafe's SKILL.md is vendored beside it from `typesafe-ai/skills` at commit `65a39f3` (v0.5.7) with a provenance comment and license, and listed in `skills/vendored-skills.md`
- [ ] One bullet under `CONTEXT.md` → "Service Access", under 100 tokens: closed options, many items, safe fallback, correctness confirmed elsewhere → use the CLI; never for prose or extraction; no key → the current way
- [ ] `scripts/tests/test-jev.sh` covers Score and Noul against the stub and the two client-side refusals
