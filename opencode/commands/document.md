---
description: Creates or updates documentation and independently reviews it against the current code
agent: docs-manager
subtask: false
---

Run the documentation workflow for this request:

$ARGUMENTS

Use the current codebase as the source of truth. Skip discovery only when the request names both the documentation files and the related code scope. Otherwise delegate one focused discovery pass to `docs-explorer`.

Split the work into non-overlapping units, delegate writing to fresh `docs-writer` instances, and delegate a corrective review of every completed unit to fresh `docs-reviewer` instances. Run independent units in parallel, never edit documentation yourself, and finish the changes rather than returning only a plan.

If no arguments were provided, ask only for the documentation scope to work on.
