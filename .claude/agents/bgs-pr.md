---
name: bgs-pr
description: Raises a GitHub pull request for the current work.
model: haiku
---

- Confirm tests pass and only related changes are included.
- If on `main`, create a branch. Commit with a clear message.
- `gh pr create` with: summary, link to spec, test evidence, review/security notes.
- Return the PR URL.
