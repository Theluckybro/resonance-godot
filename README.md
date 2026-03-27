# Resonance

Resonance is a 2D top-down action roguelite built with Godot, featuring a unique system where players absorb monster abilities (Vestiges) and equip them as active skills.

## Project Status

**In Development (Early Prototype) – snapshot March 2026**

This project is actively developed. Core combat is already playable, but content, balancing, UI, and polish are still in progress.

## Gameplay Overview

Resonance is designed as an arena-based roguelite with a concise gameplay loop:

1. Battle waves of enemies in a closed arena.
2. Collect Vestige orbs dropped by defeated monsters.
3. Equip Vestiges into 3 active skill slots and 1 dash slot.
4. Progress to the next room with increasing threats.
5. Repeat until the run ends (victory/defeat).

## Design Pillars

- Fast adaptation through dynamic Vestige loadouts.
- Responsive, readable top-down combat.
- Room-based progression for replayability.
- Realistic production scope for MVP delivery.

## MVP Scope

- 1 playable character.
- 3 core enemy roles for the initial prototype.
- 1 dungeon biome.
- 8–12 room variations.
- 6–8 Vestige abilities (active + dash).
- 1 complete run loop with clear win/lose conditions.

## Tech Stack

- Engine: Godot 4.x
- Genre: 2D Top-Down Action RPG / Roguelite
- Target platforms: PC (Windows, Linux)
- Visual style: Pixel art

## Documentation

- Main GDD: [docs/GDD_Resonance.md](docs/GDD_Resonance.md)
- Asset production checklist: [docs/ASSET_CHECKLIST_MVP.md](docs/ASSET_CHECKLIST_MVP.md)
- Technical setup (input & collision): [docs/TECH_SETUP_INPUT_COLLISION.md](docs/TECH_SETUP_INPUT_COLLISION.md)
- Project portfolio draft: [docs/PORTFOLIO_RESONANCE.md](docs/PORTFOLIO_RESONANCE_EN.md)

## Current Progress

- Core scenes available (Player, Enemy, Room).
- Core combat implemented: movement, dash, basic attack, hit-damage flow.
- Enemy archetype presets documented in [data/enemies/EnemyArchetypePresets.json](data/enemies/EnemyArchetypePresets.json).
- Basic Vestige pickup integrated.
- Production progress tracked in [docs/ASSET_CHECKLIST_MVP.md](docs/ASSET_CHECKLIST_MVP.md).

## Folder Structure (Summary)

```text
Resonance/
|- assets/
|- data/
|- docs/
|- scenes/
|- scripts/
`- tests/
```

## Notes

- Empty folders are kept with `.gitkeep` for Git tracking.
- The repository structure is designed for easy scaling and future feature iteration.
