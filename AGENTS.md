# Bubble Gum Sniper Harness

Flow (agents): `bgs-spec` → `bgs-plan` → `bgs-build` (→ `bgs-refactor`, `bgs-review`, `bgs-security`) → `bgs-pr`.
Artifacts live in `specs/<feature>/` (`spec.md`, `plan.md`).

## Engineering principles

- **Chesterton's Fence**: Don't delete or rewrite code you don't understand. Check git blame, comments, and tests for why it exists first. If it's still unclear, ask.
- **Hyrum's Law**: Treat every observable behaviour of a public API, CLI, schema, or output format as something a caller depends on. Don't change it unless the task requires it, and flag the change if you do.
- **Goodhart's Law**: The goal is working code, not passing checks. Never weaken, skip, or delete tests, lint rules, or type checks to get green. Fix the cause or report it.
- **Gall's Law**: Build the simplest version that works end to end, then extend it. Don't scaffold a large design up front.
- **Second-System Effect / YAGNI**: Don't add abstractions, config options, or generality the task doesn't need.
- **Kernighan's Law**: Prefer obvious code over clever code. The next reader may be another agent with less context.
- **Knuth**: Don't optimise without a measured problem.
- **Ninety-Ninety Rule**: Don't call a task done until edge cases, error paths, and tests are handled. Say explicitly what you didn't cover.
- **Conway's Law**: Respect existing module and package boundaries. Don't reach across them to make a change easier.

## Writing principles

- **Brevity is king**: Keep things short, precise.
- **A picture tells a thousand words**: Visual learning is important. Use diagrams when it makes sense.
- **Consistency is key**: Use the same word for the same thing: Don’t alternate between “tenant,” “customer,” and “organisation” for variety if they mean different things in the product.
- **Name the actor**: Write “The watcher deletes the file after HTTP 2xx,” not “The file is deleted after success.”
- **Write for the next action**: If the reader needs to do something, give the exact command, decision, or check. If nothing is needed, stop.
- **Lead with the answer**: Put the outcome, recommendation, or blocker first. Give the background after.
- **Show, don’t tell**: Give a concrete example when prose leaves room for interpretation. Use a sample payload for an API contract or a diagram for a handoff.

## Code principles

- **Baild on bad**: Validate at the boundary, before side effects. Return a clear error rather than silently continuing or substituting a default.
- **Name values that carry meaning**: Use named constants for policy values like timeouts and limits, and enums or equivalent types for closed sets of states.
- **Test behaviour, not implementation**: Test expected _behaviour_, not the code that runs it.
