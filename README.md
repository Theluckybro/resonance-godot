# Resonance

2D top-down action roguelite in Godot where players absorb and use the abilities of defeated monsters.

## Overview

Resonance is an arena-based action roguelite built around a modular Vestige system. Players fight through compact combat rooms, collect Vestiges dropped by defeated enemies, and equip those Vestiges as active skills or dash modifiers to adapt their build during each run.

## Core Pillars

- Fast adaptation through changing Vestige loadouts
- Tight and readable top-down combat
- Room-based progression with replayable runs
- Realistic production scope for an MVP

## Core Gameplay Loop

1. Fight through waves of enemies in a closed arena.
2. Collect Vestige orbs dropped by defeated monsters.
3. Equip Vestiges into 2 active skill slots and 1 dash slot.
4. Move to the next room with stronger enemy combinations.
5. Repeat until the run ends in victory or defeat.

## MVP Scope

- 1 playable character
- 3 enemy archetypes
- 1 dungeon biome
- 8-12 room variations
- 6-8 total Vestige abilities
- 1 complete run loop with clear win/lose conditions

## Tech Stack

- Engine: Godot 4.x
- Genre: 2D Top-Down Action RPG / Roguelite
- Platform: PC (Windows, Linux)
- Visual Style: Pixel art

## Project Structure

```text
Resonance/
|- assets/
|  |- audio/
|  |  |- music/
|  |  `- sfx/
|  |- fonts/
|  |- sprites/
|  |  |- enemies/
|  |  |- effects/
|  |  |- player/
|  |  `- ui/
|  `- tilesets/
|- data/
|  |- balance/
|  |- vestiges/
|  |- enemies/
|  `- rooms/
|- docs/
|  `- GDD_Resonance.md
|- scenes/
|  |- core/
|  |- enemies/
|  |- player/
|  |- rooms/
|  `- ui/
|- scripts/
|  |- autoload/
|  |- enemies/
|  |- player/
|  |- systems/
|  |- ui/
|  `- utils/
|- tests/
|- .gitignore
|- GDD_Resonance.md
`- README.md
```

## Documentation

- Main design document: [GDD_Resonance.md](GDD_Resonance.md)
- Reference copy: [docs/GDD_Resonance.md](docs/GDD_Resonance.md)
- Production checklist: [docs/ASSET_CHECKLIST_MVP.md](docs/ASSET_CHECKLIST_MVP.md)

## Status

Pre-production / project structure setup.

## Notes

- Empty folders are kept with `.gitkeep` so they can be tracked by Git.
- The repository is structured to support Godot-based development and future asset organization.
