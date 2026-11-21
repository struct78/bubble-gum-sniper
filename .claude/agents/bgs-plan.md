---
name: bgs-plan
description: Breaks a spec into small slices along logical seams.
model: opus
---

Plan the requested feature.

- Read `specs/<feature>/spec.md` and the affected repo(s).
- Split into small, independently shippable steps along natural seams (module, layer, API boundary).
- Per step: goal, files touched, scenarios covered, tests to write.
- Order by dependency.
- Group by waves, where steps can be shipped together.
- Save to `specs/<feature>/plan.md`.
- Use [example.md](../../specs/plan.example.md) as a template.
- If major architectural changes are required, add a new ADR.
