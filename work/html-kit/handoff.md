<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-10-15 (session 2: wired for session-loop)

Same conversation as session 1; the record numbered it 2 because it registered
after the s1 block existed (register opens at ledger top + 1). Added the
`work/README.md` row and a per-item `context-budget.env` (`ROLLOVER_RELAUNCH=auto`,
same precedent as jev-integration) so `scripts/session-loop.sh html-kit` can chain
sessions. No kit code written yet; the launcher's START HERE is unchanged in
substance. Staged the successor (s3) for the supervisor, hands-off.

# Session Handoff — 2026-10-15 (session 1: scaffold + prototype kit)

Scaffolded the work item after reviewing the HTML-vs-Markdown benchmark video
and measuring the design share of the repo's HTML files (see README). Test page
chosen: `where-ai-actually-helps.html` (14 slides, 9.8 KB of CSS, one
hand-drawn SVG ring diagram). `sdlc-three-zooms.html` was rejected as the test
case: it is an interactive radial map, the one kind of page where freeform
design earns its cost.
