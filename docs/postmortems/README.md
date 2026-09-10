# Postmortems

Committed, permanent record of **how an incident happened** — the timeline, the
contributing factors, and the actions taken so the same class of incident stops
recurring. `docs/operational-knowledge.md` holds the *what to avoid* (one gotcha,
one rule); a postmortem holds the *how it happened* (the narrative that produced
the rule). When a postmortem yields a durable gotcha, copy that gotcha into
`operational-knowledge.md` and link back here from its Lessons section.

## When to write one

Threshold (adopter-tunable — raise or lower it in this file): any incident that
**cost a session of work** (lost state, a burned handoff, a wrong build that had to
be redone) or **reached a user** (a downloader, a teammate, an end user of the
product). Smaller stumbles go straight to `operational-knowledge.md` as a gotcha,
or nowhere.

## Conventions

- **Filename:** `YYYY-MM-DD-<slug>.md`, dated by the day the incident started.
- **Template:** copy `0000-template.md`. It's `0000` so it sorts first and is never
  a real record.
- **Blameless:** name systems, sequences, and missing guardrails — never the person
  who happened to be at the keyboard.

## Workflow

1. **Agent drafts** from the evidence on disk: the work item's ledger
   (`work/<project>/handoff.md`), commits, hook/log output, and the conversation
   timeline. Timestamps in UTC; every claim traceable to one of those sources.
2. **Human reviews** the draft — corrects the timeline, challenges the contributing
   factors, owns the action list — then it is committed.
3. Run `graphify update .` (AST-only, no API cost) so the record joins the graph.

## Where actions go

Until `work/feedback-intake/` ships its convention, route action items as backlog
cards / tracker issues and link them from the Actions section; when that
convention lands, this paragraph gets replaced by a pointer to it.

## Index

<!-- Add a line per postmortem: -->
<!-- - [YYYY-MM-DD: <title>](YYYY-MM-DD-slug.md) -->
