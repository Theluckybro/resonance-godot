
# Game Design Document (GDD)
## Project: Resonance

> Status: **In Development** (Early Prototype, March 2026)

This document serves as the main design reference for ongoing development. Some implementation details may change as the prototype iterates and playtest feedback is incorporated.

## 1. Executive Summary
- Genre: 2D Top-Down Action RPG Roguelite (arena-based)
- Visual Style: Pixel art (classic 16-bit or chibi proportions)
- Platform: PC (Windows, Linux)
- Engine: Godot Engine 4.x
- Logline: Survive in a shifting labyrinthine arena by absorbing and wielding the abilities of defeated monsters.

### Design Pillars
1. Fast adaptation: players must frequently change Vestige loadouts to match arena conditions.
2. Concise, responsive combat: simple controls, high tactical decision-making.
3. Realistic scope: focus on a small amount of content but high replayability.

## 2. Core Gameplay Loop
Main gameplay cycle:
1. Combat: face waves of enemies in a closed arena.
2. Absorb: collect Vestige/Soul orbs dropped by enemies (RNG-based drop rate).
3. Adapt: equip Vestiges into skill slots (max. 2 active + 1 dash slot).
4. Progress: move to the next arena with increased difficulty.
5. Repeat: enemy combinations, layouts, and Vestige choices force new strategies each run.

## 3. Core Mechanic: Vestige System
The main character has a minimal base kit:
- Basic attack: sword slash/thrust
- Basic mobility: dash

The main power comes from absorbed monster Vestiges.

### 3.1 Active Vestiges (Attack)
- When activated, the monster sprite appears briefly, performs an attack animation, deals damage, then disappears.
- Examples:
  - Slime Vestige: small AoE leap attack
  - Goblin Archer Vestige: straight projectile shot

### 3.2 Utility Vestiges (Dash Modifiers)
- Replace the player's standard dash.
- Examples:
  - Bat Vestige: dash can phase through thin obstacles
  - Fire Elemental Vestige: dash leaves a damaging fire trail

### 3.3 Slot Rules and Limitations (MVP)
- 2 Active Vestige slots and 1 Dash Vestige slot.
- A Vestige can only be equipped in one slot at a time.
- Vestige swapping is only allowed during safe moments (between rooms) to maintain game rhythm.
- Each Vestige has a cooldown to prevent single-ability spamming.

## 4. Level Design and Arena Scale
To prevent scope creep:
- Structure: room-based, not open world.
- Experience reference: Hades / Enter the Gungeon.
- Arena size: 1.0 to 1.5 viewports.
- Camera: minimal scrolling to keep action readable.
- Variation: 1–2 initial tilesets (e.g., Stone Dungeon, Moss Dungeon) with randomized obstacle/trap layouts.

### Room Variation Targets (MVP)
- 8–12 total room patterns
- 3 room function types:
  - Combat room (main)
  - Transition room (short break)
  - Reward room (simple Vestige/upgrade choice)

## 5. AI and Enemies
Closed arenas make enemy navigation a key factor.

### 5.1 Pathfinding
- Use A* (A-Star) with NavMesh or Godot's built-in grid-based movement.
- Goal: melee enemies can always reach the player without getting stuck on obstacles.

### 5.2 Enemy State Machine
Basic states:
1. Idle/Patrol: random movement or waiting.
2. Chase: pursue the player via valid routes.
3. Attack: stop, perform attack animation, then re-evaluate state.

### 5.3 Komposisi Musuh Fase 1
- 1 Duelist (HP rendah-menengah, pressure tinggi, gap-close cepat)
- 1 Bruiser (HP tinggi, telegraphed attack, damage besar)
- 1 Skirmisher (mobilitas tinggi, flank dan reposition)
- 1 Artillery (menjaga jarak, zoning proyektil)
- 1 Controller (area denial sederhana untuk variasi wave)

## 6. Kebutuhan Aset Visual dan Audio
Sistem Vestige menekan kebutuhan aset karena memakai ulang animasi musuh.

### 6.1 Visual
- Pemain: 1 sprite sheet (Idle, Run, Attack, Dash, Hit, Die)
- Musuh: 5 role awal, masing-masing set animasi dasar
- Environment: 1 tileset utama (lantai, dinding, obstacle, hazard)
- UI: health bar, 3 slot Vestige, indikator cooldown

### 6.2 Audio
- SFX dasar:
  - tebasan, hit, dash, absorb Vestige, kematian musuh
- Musik:
  - 1 loop combat utama
  - 1 loop transisi/menu

## 7. Scope Produksi MVP
Batas produksi versi awal yang harus playable end-to-end:
- 1 karakter playable lengkap
- 5 role musuh aktif
- 1 biome dungeon
- 8-12 variasi room
- 6-8 Vestige total (gabungan aktif + dash)
- 1 siklus run sampai kondisi menang/kalah yang jelas

## 8. Definisi Selesai (Definition of Done) Prototipe
Prototipe dianggap selesai jika:
1. Satu run bisa dimainkan dari awal sampai selesai tanpa blocker.
2. Sistem Vestige bisa drop, di-equip, digunakan, dan diganti tanpa bug kritis.
3. Semua role musuh dapat bernavigasi dan menyerang konsisten.
4. UI inti terbaca jelas saat combat ramai.
5. Performa stabil pada target 60 FPS di PC kelas menengah.

## 9. Risiko dan Mitigasi
- Risiko: scope melebar karena menambah terlalu banyak Vestige/musuh.
  - Mitigasi: kunci jumlah konten pada target MVP sebelum menambah fitur.
- Risiko: AI tersangkut obstacle.
  - Mitigasi: validasi nav setup per room + fallback steering sederhana.
- Risiko: balancing cooldown dan damage tidak konsisten.
  - Mitigasi: gunakan tabel tuning terpusat (resource/config) sejak awal.

## 10. Catatan Teknis Singkat (Godot)
- Gunakan scene modular untuk Player, Enemy, VestigeSkill, dan Room.
- Simpan parameter balancing dalam Resource agar mudah tuning tanpa ubah script inti.
- Prioritaskan gameplay readability dibanding efek visual berlebihan pada fase awal.
