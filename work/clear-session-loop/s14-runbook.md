# S14 runbook — does a cleared session start on its own? (human steps)

Spec: `spec.md` S14/S15. Two runs are needed. Each run is one real rollover
that **you** started (not `session-loop.sh`), because the launcher refuses
`--clear` under a supervisor (`supervised_stage_only`).

## Quick start

1. `/exit` the current session; if `session-loop.sh` pauses, **Ctrl-C**.
2. Start session #5 without the loop:
   ```sh
   cd ~/Developer/experiments/ai-workspace-template
   claude
   ```
3. Paste:
   ```
   Work item clear-session-loop - rollover session #5. Read `work/clear-session-loop/next-session.md` and continue from **First actions**.
   ```
4. When the launcher prints `NOW PRESS /clear`: type `/clear`, Enter, then
   **type nothing** for 60 s. PASS = it starts on its own (first reads
   `next-session.md`); FAIL = idle → type
   `go — probe run 1: FAIL, idle for 60 s`.
5. At session #6's rollover, repeat step 4 (write `probe run 2`).

Details for each step follow.

## 0. Leave the supervised session (once)

1. In the current session type `/exit`.
2. If `session-loop.sh` then pauses ("press Enter…"), press **Ctrl-C** to end
   the chain. Do not start the next session through it.

## 1. Start session #5 yourself

```sh
cd ~/Developer/experiments/ai-workspace-template
claude
```

Paste:

> Work item clear-session-loop - rollover session #5. Read `work/clear-session-loop/next-session.md` and continue from **First actions**.

The session does a small amount of bookkeeping, then runs
`scripts/launch-next-session.sh clear-session-loop --clear` and tells you to
press `/clear`.

## 2. Probe run 1 — the part only you can do

1. When the launcher prints `NOW PRESS /clear`, type `/clear` and press Enter.
2. **Type nothing.** Note the time and watch for 60 seconds.
3. Write down:
   - **PASS** — the assistant starts working by itself (its first action
     reads `work/clear-session-loop/next-session.md`).
   - **FAIL** — nothing happens for 60 s. Then type `go` and press Enter.
4. If it was FAIL, tell the new session so in your first message
   (e.g. `go — probe run 1: FAIL, idle for 60 s`). If PASS, say nothing; it
   will record the result from its own context.

The cleared session (#6) records run 1 in `probes.md` and continues.

## 3. Probe run 2

At session #6's rollover it runs `--clear` again. Repeat step 2 exactly.
Session #7 records run 2, applies the matching S15 doc change (PASS: a
"verified" note; FAIL: "press `/clear`, then type `go`"), and closes the item.

## If something goes wrong

- Launcher refuses `--clear` with `chain_closed`: quitting under
  `session-loop.sh` (step 0) marks the chain ended, and `--reopen` would start
  the loop again. The session clears the flag itself (`jq '.chain.closed = null'`
  on `session-state.json`) and logs it; nothing for you to do (backlog L91).
- Launcher refuses `--clear` with `supervised_stage_only`: the session was
  started under `session-loop.sh`. Exit and restart it with plain `claude`.
- Launcher refuses `runtime_path_unsupported`: no `claude` process found; the
  session falls back to a normal (fresh-process) rollover. Record the run as
  not done and retry next time.
- You forget and type something right after `/clear`: that run doesn't count;
  repeat at the next rollover.
