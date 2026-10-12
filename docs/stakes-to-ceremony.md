# Stakes to ceremony — how much process a change deserves

Not every change needs every skill. Size the change first, then run only the
ceremony its band calls for. Names below are directories under `skills/`;
each runtime invokes them its own way (Claude Code also has `/` shortcuts).
Once the band is known, `ask-matt` gives the detailed route through the
Pocock flow.

## Tell the band

Two questions settle it. **Can it be undone cheaply** (a revert, no data or
users touched)? **Do we know what done looks like** (a test or check you
could write now)? Yes to both → tweak or small. No to the second → big or
fuzzy. No to the first → production / irreversible, whatever the size.

## The table

| Band | Looks like | Ceremony |
|---|---|---|
| **Tweak** | Typo, rename, obvious one-liner, doc fix | Do it, run the checks. No skills. |
| **Small, understood** | One feature or bug, one session, a clear test | `grill-me` to pin the plan (`grill-with-docs` when the repo keeps a glossary), then `tdd`. For a bug that resists a first look, `diagnosing-bugs` in place of `tdd`. |
| **Big or fuzzy** | Several sessions, parallel work, or done is unclear | `to-spec` (+ `to-tickets`), then `plans`; `tdd` per node; `code-review` at every join and reconcile. `wayfinder` when the destination itself is in fog. |
| **Production, security, irreversible** | Migrations, deletes, launches, auth, payments, anything users or data feel | The band above, plus `doubt-driven-development`, `security-and-hardening` and `code-review` on the final diff. As the change calls for it: `blast-radius` (what else breaks), `deprecation-and-migration`, `shipping-and-launch`. |

In doubt, go one band up. Extra ceremony costs an hour; too little costs a
bad deploy.

## Floors at every band

- Run `scripts/run-checks.sh` before calling anything done.
- A choice with a rejected alternative gets a decision note (`decision-log`),
  even for a tweak.
- When a skill repeatedly saves or wastes a session, write it in the work
  item's ledger (`handoff.md`) so the skill gets fixed or pruned; `retro` is
  the tool for turning that note into a change.

## Adopting the skills

For downloaders of this template: do not turn everything on at once.

- **Roll out gradually.** Add a band's skills the first time that band comes
  up, not before.
- **Verification first.** A test suite and `scripts/run-checks.sh` before any
  workflow skill; a workflow skill with no check behind it produces confident
  prose, not working code.
- **Prune what you do not use.** Every model-invoked description is weighed on
  every turn, whether or not it fires. `scripts/check-skill-descriptions.sh`
  bounds the total; stay under it, and make a rarely used skill user-invoked
  rather than carrying its description everywhere.
