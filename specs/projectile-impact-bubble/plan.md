# Plan — Projectile impact bubble

#### Status: base behavior and shoot-through popping implemented; Roblox Studio validation pending

Resolve the hit and award the struck Roblox player **+5 once per shot** on the server, independently of the bubble. The bubble inflates on contact, reaches full size within **1.2 seconds** and pops **10 seconds after contact** unless another flying gum shot crosses it first. A shot can pop every impact bubble it crosses without stopping.

## Current paths and decisions

- **Collision:** `src/server/main.server.lua:UpdateProjectiles` calls `Physics:SimulateProjectile` in `src/server/gameplay/physics.lua`. The swept ray excludes only the current projectile and sticks on its first result only if that part has `CanCollide`. The exact point is `RaycastResult.Position`, not the visible offset applied by `Projectile:StickToSurface`. Neither `Projectile:CheckCollision` nor the `GameController` projectile stubs run this loop.
- **Existing score:** After physics, `Targeting:CheckTargetHit` finds the nearest undefeated spawned target strictly within 5 studs of the sampled projectile position. `Targeting:CalculateScore` supplies the existing floored score; the server defeats the target and broadcasts `Hit(position, score)`. Every receiving client adds it to `ClientState.CurrentScore` and updates the HUD. Preserve this path, including on the same update as a surface stop. It is not a victim-specific award channel.
- **Points destination — session:** Use a server-owned `leaderstats.Score` `IntValue` so Roblox displays it in the player list. Start at zero on join; don't reset on respawn or level change, persist it, or add it to existing score paths. Don't overwrite or adopt an existing `leaderstats.Score` if a place already defines one; warn on the conflict.
- **Player contact eligibility — existing:** Only the existing `CanCollide`-accepted ray contact can award points. Resolve its part through character ancestry with `Players:GetPlayerFromCharacter` and verify the current character. Self-contacts don't award points. Noncollidable first results still fly through and can mask geometry behind them. Do not change shooter filtering, infer a victim from proximity, or use cosmetic target intersections for player scoring.

## Data modelling

| Model | Fields | Type | Notes |
| --- | --- | --- | --- |
| Simulation step | Origin, traversed displacement, accepted surface hit | `Vector3`, `Vector3`, `RaycastResult?` | Optional metadata; preserve `SimulateProjectile`'s first return and existing movement. |
| Confirmed impact | World point, contact time, struck part; resolved player if eligible | `Vector3`, `number`, `BasePart?`, `Player?` | Snapshot before target destruction. Use measured ray entry, not a projected endpoint or target centre. |
| Runtime shot | Shooter user ID, player award committed, visual claimed | `number`, `boolean`, `boolean` | Shooter identity comes from the server fire handler. Separate once-per-shot guards; neither depends on `Stuck`, `IsActive` or the other guard. |
| Victim points | Session `Score` plus named `5`-point delta | Server-owned `IntValue` | Add to its current value without touching prior score systems. No yield between checking the shot guard and committing the increment. |
| Impact visual | Start/full size, contact time, owned part and animation resources | Server-local | Track live effects for pop checks; never register as a gameplay target. |

## Files to create

| File | Tests | Purpose |
| --- | --- | --- |
| `src/server/bubble-wobble.lua` | 1, 9 | Share wobble parameters and size math; no instance lookup or tween ownership. |
| `src/server/gameplay/impact-contact.lua` | 2–6 | Read the traversed step, select the earliest cosmetic contact and classify eligible Roblox-player contacts. |
| `src/server/gameplay/impact-bubble.lua` | 7–10 | Create, animate and clean up the isolated cosmetic. |
| `src/server/player/session-score.lua` | 5, 6, 10 | Own the session-only score and additive victim award. |
| `specs/projectile-impact-bubble/behavior.lua` | Focused mocks | Exercise contact rules, session award, wobble, teardown, and score independence in the live server loop without Studio. |

## Files to edit

| File | Tests | Change |
| --- | --- | --- |
| `src/server/gameplay/physics.lua` | 2–6 | Expose the traversed step and accepted hit without changing ray filters, motion or stop position. |
| `src/server/main.server.lua` | 2–8, 10 | Capture server shooter identity, resolve the victim award in the live loop, and emit at most one cosmetic after gameplay resolution. |
| `src/server/gameplay/projectile.lua` | 2, 5–8, 10 | Keep per-shot guards and hide the visible splat/trail while preserving the stopped representation. |

Leave `targeting.lua`, `target-spawner.lua`, legacy `Hit` payload and client score handling unchanged. Don't update the unused shared projectile type just to hold server runtime state.

## Files to refactor

| File | Tests | Change |
| --- | --- | --- |
| `src/server/dome-wobble.server.lua` | 1, 9 | Use the shared size math. Preserve the current dome lookup, anchoring guards, appearance and infinite reversing tween; do not reintroduce sheen. |

## Test scenarios (TDD order)

Run the focused mock suite from the repo root with `lua specs/projectile-impact-bubble/behavior.lua` (standard Lua 5.2+). For engine validation, run `rojo serve` locally and connect the Roblox Studio Rojo plugin to localhost. Use a disposable server test script or server Command Bar with fixed steps and isolated geometry. Use Studio's local server with two clients for player ownership and existing HUD/replication checks. Measure timing from the server contact timestamp, not from the first rendered client frame.

1. **Dome parity:** Sample before and after extraction: X/Z `0.99/1.01` initially, `1.01/0.99` after `1.2 s`, back at `2.4 s`, with continued Sine InOut alternation; Y and appearance stay unchanged.
2. **Thin wall and first surface:** Sweep across two thin collidable walls in one step. The near wall's ray entry wins (within `0.01` stud); stop, offset, zero velocity, stuck state and weld match baseline. Compare a moving surface, a clear step with wind/gravity and the existing minimum-ray fallback.
3. **Target contact and order:** Sweep off-centre through a live target's queryable `TargetPart` or `Head`; use ray entry even if the endpoint is beyond the part. The nearest eligible intersection wins regardless of target-list order; no target beyond an accepted stop. Equivalent surface and target reports yield one visual. Defeated/missing targets and ignored non-target geometry do not become candidates. A swept NPC target contact alone does not defeat, score or stop the shot.
4. **Legacy scoring parity:** End a step just inside the NPC target's `<5`-stud radius without touching it; repeat at exactly `5` studs and with a wall stop inside the radius. Compare nearest target, accuracy, distance input, floored score, defeat, retirement, `Hit` count/payload, both HUDs and level completion against baseline. No bubble for proximity alone and no victim award in any of these cases.
5. **Victim only, once per shot:** Seed confirmed balances (e.g. shooter A `40`, victim B `70`). A's shot crosses B's eligible character part between updates; assert B `75`, A `40` before any visual work. Replay the same shot's hit (multiple reports/parts and later updates) with no further change, then fire a distinct shot at the same point and assert B `80`, A `40`. Repeat with roles reversed and test a player stop near a spawned target: the victim gets exactly `+5` and any legacy target score proceeds separately. Test accessory ancestry and add boundary cases for the resolved noncollidable/self-hit decisions.
6. **No award without confirmed player contact:** Assert no victim-balance delta for a scenery hit, NPC direct hit, player near-miss, player behind a confirmed wall stop, ignored geometry, or an untouched shot expiring by age (`>30 s`) or world-origin magnitude (`>1000` studs). Confirm an NPC rig is not a player and a stale character model isn't the current character. Baseline the noncollidable first-result masking case; do not invent a wall impact. Repeated cosmetic reports or stuck updates never restart the bubble; independent shots at the same coordinate each get their own. Compare retirement with adjacent shots and coincident hit/expiry.
7. **Visual thresholds:** In a dome-free place, a small pink bubble starts at measured contact with `Transparency == 0.5` throughout. Full inflation envelope by `tContact + 1.2 s`, alternating horizontal wobble; still visible just before the 10-second deadline, gone on the first scheduled cleanup at or after `tContact + 10 s` (within one heartbeat in a controlled fixture). No lingering splat/trail. A destroyed struck target doesn't remove the bubble; nonterminal contact doesn't hide the flight visual.
8. **Inert to other objects:** Walk a player and move an unanchored part through the bubble; no blocking, touch events or early pop. An ordinary world raycast ignores the effect. Both local clients see the visual without duplicate legacy feedback.
9. **Independent lifetimes:** Stagger overlapping impacts across phases of the dome cycle; its phase, extrema, appearance and continuous loop match scenario 1 through creation and cleanup.
10. **Failure and teardown:** Inject a visual failure before creation and after the part exists. In both cases a confirmed victim still receives exactly `+5` once; shooter and legacy outcomes are unchanged. Try early external removal, a burst of shots, and stopping the level loop on a last-target hit. All owned parts, animation resources and references are cleaned up without retries or overdue effects.
11. **Shoot-through popping:** Sweep a single shot through an inflating bubble and a fully inflated bubble in the same update, then into another bubble on a later update. All three pop without changing the shot's motion, spawning extra bubbles or awarding points. Put a bubble beyond a stopping wall and another just off the path; neither pops. Compare the wall impact and any score with a shot through empty space. Confirm the bubble created by the shot is not popped by its own step and two shots crossing the same bubble clean it up only once.

## Steps

- **S1 — Extract wobble math (`bubble-wobble.lua`, `dome-wobble.server.lua`).** Share the 1% alternating X/Z size factors with unchanged Y and the `1.2 s` Sine InOut half-cycle. The dome retains its own tween and initial phase. Write and run scenario 1 before/after.
- **S2 — Expose and classify swept contacts (`physics.lua`, `impact-contact.lua`).** Keep existing integration and stick logic. Return the step ending at the accepted surface point or unchanged next position. Compare the accepted surface result with direct intersections of live `CurrentTargets` geometry on that segment for visual selection; use surface first on an equal-distance tie. Classify eligible player contacts separately from cosmetic selection. Never use the `<5`-stud proximity check as confirmation or recast to manufacture a solid stop. Write scenarios 2–4 and characterize the character cases in 5–6.
- **S3 — Commit the victim award (`main.server.lua`, `projectile.lua`, confirmed points owner).** After the decisions above, wire the server-owned contact to a single guarded, additive write for the struck `Player`; anonymous contacts do not consume the award. Commit before cosmetic work. Do not use the cosmetic claim to suppress an otherwise eligible award or client claims to identify the victim. Preserve legacy post-physics target checks, sample position, defeat, broadcast and cleanup ordering, including after a stick. Write the score cases in 5–6 and verify with a no-op renderer before integration.
- **S4 — Build the finite cosmetic (`impact-bubble.lua`).** Combine inflation and shared wobble with one size writer. Configure an anchored part with `CanCollide`, `CanTouch` and `CanQuery` false before parenting. Follow a moving surface at the captured local point without welding assemblies; freeze at the last known world point if geometry disappears. Check the 10-second deadline on Heartbeat independent of the level loop and animation completion. Arm an instance-removal backstop and make teardown idempotent on expiry, errors and external removal. Write isolated cases from 7–10.
- **S5 — Connect one bubble and replace the splat (`main.server.lua`, `projectile.lua`).** Snapshot the point before legacy scoring can destroy the struck target. Isolate cosmetic selection/rendering failures from both score paths; claim the visual before trying to spawn it and never retry or restart its timer. Suppress the visible splat and trail even if the bubble fails, retaining the underlying stop/weld/query behavior. Run all integrated checks, including visual failure on an awarded shot and a subsequent shot through the effect.
- **S6 — Pop bubbles along a flying shot's path (`impact-bubble.lua`, `main.server.lua`, `behavior.lua`).** Use the traversed step, clipped at any accepted surface stop, to test against each live bubble's current position and size. Check before creating a new impact bubble for that step; keep bubbles out of the world raycast. Reuse the existing teardown for pops and remove each effect from tracking on every cleanup path. Leave movement, scoring, and ordinary impact resolution unchanged. Add scenario 11 to the mock suite and verify removal on both clients in Studio.

## Waves

- [x] Wave 1 — Behavior-neutral groundwork: dome wobble math and swept contacts.
- [x] Wave 2 — Independent award and visual slices: session scoring and isolated bubble.
- [x] Wave 3 — Impact integration and splat replacement.
- [x] Wave 4 — Shoot-through popping.
- [ ] Manual two-client Roblox Studio checks above.

## Risks

- Don't broaden the `CanCollide` gate or recast through rejected geometry to fix apparent misses. Ordinary avatar parts may not qualify under the existing rules.
- A stopped projectile can still score a legacy NPC hit in the same update. Keep that ordering. If the baseline exposes duplicate retirement indices on hit-plus-expiry, report separately unless the feature worsens it.
- The existing fire remote still accepts client aim and a nearby launch origin and has no server-side rate limit. Score attribution additionally requires the sender's current character, but does not change the launch path. Visuals have a per-impact deadline, not a server-wide concurrency cap. Review fire validation and load limits separately before public deployment.
- Use the current dome behavior as the baseline. Keep the cosmetic independent of the stopped projectile and the dome. No ADR is needed for the planned local changes; revisit scope if the confirmed scoring destination requires new persistence or client contracts.

## Out of scope

- Changes to gum motion, hit eligibility, stop/stick, target defeat, expiry or existing scoring beyond the specified victim award.
- Damage, knockback, additional pop effects, new assets, dome appearance changes or unrelated projectile cleanup.
