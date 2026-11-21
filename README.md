# Bubble Gum Sniper

A vibrant, colorful first-person sniper game for Roblox where you shoot bubble gum at targets from increasingly difficult distances.

## Game Concept

- **Genre:** First-Person Sniper Shooter
- **Mechanic:** Shoot bubble gum projectiles instead of bullets
- **Challenge:** Increasing distance, wind, weather, and visibility
- **Aesthetic:** Bright, neon-colored world with cartoonish, plastic-looking weapons
- **Platform:** Roblox (PC + Mobile)

## Features (MVP)

- **2 Playable Levels** with unique environments and difficulty
- **Sniper Physics:** Wind deflection, gravity, distance-based difficulty
- **Cross-Platform Input:** Mouse/keyboard (PC) + touch/gyro (mobile)
- **Cosmetics Shop:** Scopes, ammunition sizes, camouflage outfits, gun skins
- **Player Progression:** Level unlocks, cosmetic rewards, persistent data
- **Polished Core Gameplay:** Minimal features, maximum refinement

## Development

### Setup

1. Install [Rojo](https://rojo.space) (version 7.2+)
2. Clone this repository
3. Run `rojo serve` in the project root
4. In Roblox Studio, open the **Rojo** plugin and connect to localhost

### Scenery assets

Export Studio models as `.rbxm` or `.rbxmx` files into [assets/](./assets/) and commit them. Rojo syncs them to `Workspace.Assets`. Re-export to the same file after editing a model in Studio. If the original is still in Workspace, remove it once you verify the synced copy so you don't have two copies.

Scenery stays in Workspace across levels. Include solid ground beneath each player spawn defined in [level-data.lua](./src/server/levels/level-data.lua); the game no longer generates spawn platforms.

### Project Structure

```
src/
├── client/          # First-person camera, input, UI
├── server/          # Game loop, sniper mechanics, shop logic
└── shared/          # Constants, type definitions, config
```

### Key Files

- `default.project.json` — Rojo configuration
- `src/shared/constants.lua` — All game balance parameters
- `src/server/main.lua` — Game initialization

## Roadmap

### MVP (Phase 1–7)

- ✓ Project setup
- ⊘ Core sniper mechanics (wind, gravity, projectiles)
- ⊘ Camera & scoping system
- ⊘ 2 playable levels
- ⊘ HUD & UI
- ⊘ Cosmetics shop
- ⊘ Player progression & persistence

### Post-MVP Expansion

- Additional levels (8+ more)
- PvP multiplayer
- Battle pass system
- Daily challenges & events
- Premium cosmetics

## Design Notes

- **Targets:** Celebrity parodies with punny names (e.g., "Melon Fusk", "Kym Kardorkian")
- **Cosmetics:** Thermal scopes, zoom levels, calibubble sizes, neon outfits
- **Difficulty:** Scales via wind multiplier, distance, visibility
- **Monetization:** Soft currency only (MVP)

## License

[MIT NON-AI License](./LICENSE.md).

---

**Last Updated:** August 2026
