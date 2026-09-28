# 07 — Say that data leaves the machine, caveat Score, and add an off switch

**What to build:** A keyed user reading `skills/jev/SKILL.md` or `docs/service-access.md` is told, in one sentence each, that with a key the `state` they classify is sent to TypeSafe (vendor compliance posture unverified) and how to keep a corpus local; the skill's type table says 1–5 scales are less reliable than Choice or yes/no; and `JEV_DISABLED=1` makes `scripts/jev.sh` take the no-key branch (exit 3, one stderr line, nothing sent, keychain untouched) so the "keep it local" sentence names a concrete action. Source: `research/video-assessment-2026-09-27.md` candidates #1, #2, #4; opened by the user in session 16 (2026-09-27). One session, one agent, no plan.

**Blocked by:** None — plan 01-gated-integration is closed.

**Status:** resolved — done in session 16 (2026-09-27), same session it was opened; test-jev.sh 140/140 with T20

**Spec:** S8, S15, S18; amends the key-resolution item (one line)

- [x] `skills/jev/SKILL.md`: one data-leaves-the-machine sentence where the request is shaped (with a key, records go to TypeSafe; SOC 2 claim unverified; no personal or confidential records) naming `JEV_DISABLED=1` as the way to keep a corpus local
- [x] `skills/jev/SKILL.md`: the `score` row says scale answers were less reliable than Choice or Noul in the one report we have, prefer a Choice or one Noul per level when it matters
- [x] `docs/service-access.md` → Jev → Notes: one sentence that a key sends classified records to the vendor, one naming `JEV_DISABLED=1`
- [x] `scripts/jev.sh`: `JEV_DISABLED` set to anything but `0`/empty → exit 3 with one stderr line, empty stdout, no request, no keychain read; `--check` also exits 3; `--help` unaffected and documents it under ENVIRONMENT (≤ 80 cols, section order kept)
- [x] `scripts/tests/test-jev.sh`: T20 proves the switch (request and `--check` exit 3, nothing sent, key not on stderr, `JEV_DISABLED=0` is not disabled); suite passes
- [x] `spec.md` key-resolution item gains one line for the switch; `skills/rlm/SKILL.md` knobs mention it (classify() inherits it through the CLI)

**Check:** `bash scripts/tests/test-jev.sh` passes with T20 present.
