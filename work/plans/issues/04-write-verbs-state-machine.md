# 04 — Write verbs and the state machine: `add / start / done / drop / block / note / verify`

**What to build:** The transitions live in one place: `start` moves a frontier node to doing and stamps the session; `done` runs the node's check (if any), refuses on failure, and writes done with a Log line — `--by human` for hitl nodes; `block <reason>` writes blocked with the reason as the latest Log line; `drop`; `add` creates a node file from flags; `note` appends to plan.md → Not yet specified; `verify` runs the check without changing status. `loop: N` is enforced: the Nth failed check turns the node blocked.

**Blocked by:** 02, 03

**Status:** done

**Spec:** S4, S8, S18, S19, S20

- [x] Illegal transitions refused with exit 1 (done on a failing check, start off-frontier without `--force`, done written by anything but this verb is out of contract and documented as such)
- [x] `done --by human` on a hitl node logs the actor; `done` on a hitl node without it is refused
- [x] Loop cap test: check fails N times → status blocked, reason logged
- [x] `note` never touches node files or the board
