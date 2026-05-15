---
description: Create clean Conventional Commits from current Git changes
---

# Git Commit Organizer

Create clean, reviewable Conventional Commits from the current uncommitted Git changes.

Optional user context:

```text
$ARGUMENTS
```

Use that context as guidance for intent, grouping, exclusions, or message preferences. Do not let it override the actual diff, repository state, or safety rules. If empty, ignore it.

## Priorities

- Group by intent, not by file type, directory, frontend/backend, or edit order.
- Prefer several clear commits over one broad commit, but do not create artificial microcommits.
- Each commit should leave the project in a coherent state when practical.
- Commit automatically when the grouping is clear.
- Ask only when there is meaningful ambiguity or safety risk.

## Commit Messages

Use Conventional Commits in English.

- Use a scope when a meaningful scope is clear.
- Use descriptive titles, not vague ones.
- Add a body only when the reason, tradeoff, migration, compatibility issue, or behavior change is not obvious from the title.

Examples:

- `feat(auth): add password reset flow`
- `fix(invoices): prevent duplicate invoice generation`
- `refactor(api): simplify pagination handling`
- `chore(deps): add zod for schema validation`
- `docs(readme): clarify local setup steps`

Avoid:

- `update files`
- `fix stuff`
- `changes`
- `wip`

## Fast Inspection Workflow

Start with cheap commands:

```bash
git status --short
git diff --stat
git diff --name-status
git diff --cached --stat
git diff --cached --name-status
git log --oneline -8
```

Use full diffs selectively:

- Read `git diff -- <path>` only for files or groups needed to understand intent.
- Read `git diff --cached -- <path>` only for staged content you are about to commit.
- Avoid dumping the entire repository diff unless the change set is small or grouping cannot be understood otherwise.

The actual diff is the source of truth. Do not decide groups from filenames alone.

## Grouping Rules

Keep together:

- a feature and the refactor required only for that feature
- a feature and its tests or directly related documentation
- a bug fix and the test that proves it
- file moves or renames required by the same logical change
- small formatting changes limited to files already touched by the same logical change

Separate:

- distinct bug fixes
- independent refactors
- dependency changes from the feature that uses them
- unrelated documentation changes
- unrelated config or tooling changes
- broad formatting-only changes, as `style(...): format ...`

Dependency additions, removals, or version changes normally get their own `chore(deps): ...` commit. Include the lockfile only when it belongs to that dependency change.

## Staging And Committing

For each clear group:

1. Stage only the exact files that belong to that commit.
2. If one file contains multiple intentions, split only when it is safe and can be done non-interactively.
3. Verify staged content before committing:

```bash
git diff --cached --stat
git diff --cached --name-status
git diff --cached -- <relevant-paths>
```

4. Create the commit with the chosen Conventional Commit message.
5. Continue until all clear groups are committed.

Prefer non-interactive staging commands such as:

- `git add <file>`
- `git restore --staged <file>`
- `git apply --cached <patch-file>` when precise hunk staging is necessary

Do not use `git add .` blindly when multiple logical groups exist. Avoid interactive staging commands such as `git add -p`.

## Safety Rules

Do not commit files that may contain secrets.

Treat these as suspicious unless clearly justified by the diff or user context:

- `.env` files or credentials
- logs or temporary files
- build output
- generated files
- large binaries
- editor artifacts
- unexplained config files
- lockfile changes without a matching dependency change

If a suspicious file is not clearly part of the intended commit, leave it uncommitted and mention it. Ask the user only if committing it is necessary to complete a clear group.

## When To Ask

Ask a concise question only when:

- a suspicious file may or may not belong
- one change has multiple plausible intents
- unrelated changes are mixed and cannot be safely separated
- the correct scope or purpose cannot be inferred

## Final Output

After finishing, show:

```bash
git status --short
git log --oneline -n <number_of_new_commits>
```

Then summarize:

- commits created
- files left uncommitted
- files intentionally excluded
- suspicious or ambiguous changes noticed
