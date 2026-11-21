# Spec - Projectile impact bubble

#### Status: draft

## User story

As a player, I want my gum shot to inflate into a pink bubble where it hits so I can see exactly where it landed.

## Problem

Gum shots currently flatten on surfaces. The impact bubble replaces that visual without changing how shots fly, stop, or stick. A player hit by a gum shot earns 5 points.

## Behaviour

### A confirmed contact produces a bubble at the impact point

**Given** a gum shot is in flight towards a surface or target it can contact  
**When** the shot makes its first confirmed contact, including with a thin surface it crosses between updates  
**Then** one pink bubble starts inflating at the actual contact point, not at the shot's next projected position or the target's centre  
**And** the bubble has Roblox `Transparency` set to `0.5` while visible  
**And** the bubble replaces the flattened splat without changing the shot's stop or stick rules.

### A confirmed player hit awards points to the player who was hit

**Given** the existing surface collision rules accept a gum shot's contact with another player's current character  
**When** the shot resolves that hit  
**Then** the player who was hit gains exactly 5 points for that shot, even if the bubble fails to appear  
**And** the points are added to that player's session-only `Score` on Roblox's player list, without saving them or replacing prior scores  
**And** existing target and HUD scoring remain separate  
**And** repeated reports of the same hit do not award points again.

**Given** a gum shot does not make confirmed contact with another player  
**When** it hits scenery, a non-player target, or the shooter, passes near a player, passes through a character part the existing rules ignore, or expires  
**Then** no player receives this 5-point award.

### The bubble wobbles and disappears

**Given** an impact bubble has appeared  
**When** it inflates and wobbles  
**Then** it reaches full size within 1.2 seconds while using the same gentle, alternating horizontal squash and stretch as `BubbleDome`  
**And** it is removed 10 seconds after contact unless another gum shot pops it sooner, leaving no impact visual behind.

### A single shot cannot produce duplicate bubbles

**Given** a gum shot has already made contact  
**When** the same contact is reported again, a surface and a target report the same impact, or the shot remains stuck across updates  
**Then** no second bubble appears and the first bubble's lifetime does not restart  
**And** a different shot can still produce its own bubble at the same spot.

### A miss or expiry does not produce a bubble

**Given** a gum shot has not made contact  
**When** it passes near a target, passes through geometry ignored by the existing collision rules, or is retired by the existing lifetime or distance limit  
**Then** none of those events creates an impact bubble  
**And** any existing proximity-based scoring still applies without counting proximity alone as contact for the visual.

### A flying gum shot can pop multiple impact bubbles

**Given** one or more impact bubbles are still visible, whether inflating or fully inflated  
**When** another flying gum shot crosses them along its path  
**Then** each crossed bubble pops immediately and is removed  
**And** the shot keeps flying without losing speed or changing direction because of a pop  
**And** popping a bubble does not create another bubble or award points  
**And** bubbles beyond a surface that stops the shot are not popped.

**Given** an impact bubble is visible  
**When** a player or moving object other than a flying gum shot crosses it  
**Then** the bubble does not block movement or pop.

### Sharing the wobble does not change the dome

**Given** `BubbleDome` is running its usual looping wobble  
**When** one or more impact bubbles animate and are removed  
**Then** the dome keeps its existing appearance, wobble amplitude, cadence, and continuous loop without restarting or stopping.

### The impact bubble works without a dome

**Given** a level has no `BubbleDome`  
**When** a gum shot makes contact  
**Then** the impact bubble still appears, wobbles, and disappears.

### A visual failure does not undo the impact

**Given** a gum shot makes confirmed contact  
**When** the impact bubble cannot appear or finish animating  
**Then** the shot still resolves, including any points due for a confirmed player hit, and leaves no lingering impact visual.

## Out of scope

- Changes to projectile motion, hit eligibility, target defeat, shot expiry, or scoring other than the 5-point award to a player who was hit.
- Damage, knockback, or additional effects from the bubble.

## Open questions

- None.
