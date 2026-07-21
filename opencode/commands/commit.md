---
description: Create clean Conventional Commits from current Git changes
agent: commit-writer
---

# Fast Git Commit Organizer

Create clean, reviewable Conventional Commits from current Git changes with minimal tool calls.

You are running from the direct `/commit` command. No orchestrator session context is available beyond `$ARGUMENTS`. The initial Git snapshot below is injected before you start; do not repeat it unless more inspection is needed.

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
- Do not use tools other than git commands needed for this task.

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

## Initial Git Snapshot

This snapshot is injected before you start. Output order: status, diff stat, name-status, recent log.

```text
!`git status --short; git diff --stat; git diff --name-status; git log --oneline -8`
```

Use the injected snapshot to decide groups. Run additional git commands only when the snapshot is insufficient or needs refreshing.

Then decide groups from those summaries. Use full diffs only when needed:

- Use `git diff -- <path>` only for files needed to understand intent.
- Use `git diff --cached -- <path>` only before a commit when staged content is unclear.
- Avoid dumping the whole diff unless the change set is small or grouping cannot be understood otherwise.

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
2. If one file contains multiple intentions, split only when safe and non-interactive.
3. Verify staged content cheaply with a single tool call:

```bash
git diff --cached --stat
git diff --cached --name-status
```

4. Use `git diff --cached -- <path>` only if the staged summary is not enough.
5. Create the commit with the chosen Conventional Commit message.
6. Continue until all clear groups are committed.

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

You MUST return a final message. Never finish with an empty response.

After finishing, always run and show with a single tool call:

```bash
git status --short
git log --oneline -n <max(1, number_of_new_commits)>
```

Then summarize using this exact structure, even when no commits were created:

- `Commits created:` list each new commit hash and subject, or `None`
- `Files left uncommitted:` list paths, or `None`
- `Files intentionally excluded:` list paths and reason, or `None`
- `Suspicious or ambiguous changes noticed:` list paths and concern, or `None`

If no commit was created, explicitly state why, for example: no changes, only ambiguous changes, suspicious files excluded, or commit failed with the observed error.
