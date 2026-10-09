<!--
File: docs/runbooks/glossary-migration.md
Purpose: Move an older project's domain glossary from CONTEXT.md's
         `## Language` section into a root GLOSSARY.md, with
         scripts/migrate-glossary.sh. Runtime-neutral: any agent or a human.
See: docs/runbooks/README.md
-->

# Glossary Migration

Projects made from older versions of this template (or the old
`init-project-ai-infra`) keep their domain glossary inside `CONTEXT.md`. The
template now keeps it in a root `GLOSSARY.md`, and the `domain-modeling`,
`grill-with-docs` and `improve-codebase-architecture` skills read and write
that file. Until a project is migrated, those skills miss its terms.

## When to use it

The sign: the project's `CONTEXT.md` has a `## Language` section with real
terms in it (bold term, dash, definition), and there is no `GLOSSARY.md` at
the root. If `## Language` only says the glossary lives in `GLOSSARY.md`, the
project is already migrated.

**Ask the user before running it on a real project.** It creates a branch
and a commit in their repo.

## Run it

From this template's checkout (or a copy of the script):

```bash
scripts/migrate-glossary.sh /path/to/project
```

It refuses, changing nothing, when:

- tracked files have uncommitted changes (untracked files are fine);
- the repo has no commits yet, or `CONTEXT.md` is not committed;
- a `GLOSSARY.md` already exists while `CONTEXT.md` still holds terms —
  merge those by hand instead;
- a `migrate/glossary` branch already exists.

It does nothing (exit 0) when there is no `## Language` section, or the
section already points at `GLOSSARY.md`. Running it twice is safe.

## What it does

1. Creates and switches to branch `migrate/glossary` in the project.
2. Moves the `## Language` body, verbatim, into a new `GLOSSARY.md` with a
   title and a short intro.
3. Replaces the body in `CONTEXT.md` with a pointer to `GLOSSARY.md`. The
   heading stays, and `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` still link to it.
4. Rewrites clear references in tracked `.md` files (not `work/` or `repos/`)
   — for example "`CONTEXT.md` → `## Language`" or "`CONTEXT.md`'s glossary"
   — to `GLOSSARY.md`.
5. Commits on the branch, then prints any other mentions to check by hand.

## Review, merge, or back out

The script prints these with the original branch name filled in:

```bash
git diff main..migrate/glossary                                     # review
git checkout main && git merge migrate/glossary && git branch -d migrate/glossary
git checkout main && git branch -D migrate/glossary                 # back out
```

Look at the "check by hand" list before merging. If the project vendors old
copies of the skills that still name `CONTEXT.md` as the glossary, refresh
them (`scripts/sync-vendored-skills.sh` in projects that have it) rather than
editing them.
