# 01 — Gate, `jev.sh` CLI (Choice), and the offline test

**What to build:** A person with `jev-api-key` in the keychain runs `scripts/jev.sh` with a `state` and a Choice question and gets the typed answer with its confidence on stdout; a person without a key gets exit code 3, one stderr line, and empty stdout. A test proves both without a live key or the real keychain. This is the tracer bullet: the CLI does Choice only, and the test harness (stub server, fake `security` on `PATH`, fixtures) is built here for every later ticket to widen.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Spec:** S3, S4, S6, S8, S19

- [ ] `scripts/jev.sh` resolves the key in the documented order (`JEV_API_KEY` override, then macOS `security find-generic-password -s jev-api-key -w`, then Linux `secret-tool`) and never prints, logs, or writes it
- [ ] With a key: POSTs `{state, model, questions}` to `JEV_ENDPOINT` (default: the live URL) with a bearer header, prints each answer's key, typed value, and confidence as JSON lines, exits 0
- [ ] Without a key: exits 3, one stderr line naming the missing keychain entry, nothing on stdout
- [ ] `scripts/tests/test-jev.sh` starts a local stub server with fixture responses under `scripts/tests/fixtures/jev/`, runs the CLI with `JEV_ENDPOINT`/`JEV_API_KEY` set, and asserts the received request body has the documented shape and the header carries the key
- [ ] The same test runs the CLI with no override and a fake `security` on `PATH` that fails, asserting exit 3, empty stdout, and that the key string appears nowhere in stdout or stderr
- [ ] The test runs the way the other `scripts/tests/test-*.sh` files run and passes on a machine with no network
