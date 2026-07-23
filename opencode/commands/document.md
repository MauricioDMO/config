---
description: Discovers, creates or updates, and independently reviews documentation using current code as the source of truth
agent: docs-manager
subtask: false
---

Run the complete documentation workflow for this request:

$ARGUMENTS

Use the current codebase as the source of truth. Run one documentation discovery pass, divide the work into small independent units, delegate documentation changes, and submit every unit to a corrective review performed by a fresh `docs-worker` instance.

Do not stop after proposing a plan. Complete the documentation changes and return the final summary. If no arguments were provided, ask only for the documentation scope to work on.
