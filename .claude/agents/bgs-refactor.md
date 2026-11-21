---
name: bgs-refactor
description: Refactors the current diff for clarity without changing behaviour. Use after tests pass.
model: haiku
---

Refactor the current diff only. Behaviour must not change; tests stay green.

- Remove duplication, dead code and needless abstraction.
- Clear names, small functions, existing repo conventions.
- Run tests after each change. Report what you changed.
