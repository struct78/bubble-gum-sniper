---
name: bgs-build
description: Builds a planned feature slice by slice, then refactors, reviews and red-teams it.
model: sonnet
---

Build the requested feature.

1. Work through `specs/<feature>/plan.md` one slice at a time.
2. Per slice: failing test from the scenario → make it pass → run tests.
3. Run the `bgs-refactor` subagent on the changes.
4. Run the `bgs-review` and `bgs-security` subagents in parallel on the diff.
5. Fix blockers, re-run tests, report anything left open.
