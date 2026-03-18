# Technical Setup: Input Map and Collision Matrix

Dokumen ini jadi sumber acuan untuk setup kontrol dan collision di proyek Resonance.

## 1. Input Map (MVP)

Scope MVP: keyboard + mouse.

### Action list dan default binding

| Action | Default Binding | Keterangan |
| --- | --- | --- |
| move_left | A, Arrow Left | Gerak kiri |
| move_right | D, Arrow Right | Gerak kanan |
| move_up | W, Arrow Up | Gerak atas |
| move_down | S, Arrow Down | Gerak bawah |
| action_attack | Mouse Left Click | Basic attack |
| action_dash | Shift | Dash |
| action_vestige_1 | 1 | Slot skill Vestige 1 |
| action_vestige_2 | 2 | Slot skill Vestige 2 |
| ui_up | Arrow Up | Navigasi UI |
| ui_down | Arrow Down | Navigasi UI |
| ui_left | Arrow Left | Navigasi UI |
| ui_right | Arrow Right | Navigasi UI |
| ui_accept | Enter, Space | Konfirmasi UI |
| ui_cancel | Escape | Batalkan UI |
| ui_menu | M | Buka menu |
| ui_pause | P, Escape | Pause |
| debug_toggle_hitboxes | F1 | Debug editor/dev |
| debug_spawn_vestige | F2 | Debug editor/dev |

## 2. Collision Layers (2D Physics)

Layer name di Project Settings:

1. Player
2. Enemy
3. ProjectilePlayer
4. ProjectileEnemy
5. Hitbox
6. Hurtbox
7. Pickup
8. EnvironmentAndTrigger

### Bit constants

- PLAYER = 1 << 0
- ENEMY = 1 << 1
- PROJECTILE_PLAYER = 1 << 2
- PROJECTILE_ENEMY = 1 << 3
- HITBOX = 1 << 4
- HURTBOX = 1 << 5
- PICKUP = 1 << 6
- ENVIRONMENT_AND_TRIGGER = 1 << 7

## 3. Collision Mask Matrix

| Entity | collision_layer | collision_mask |
| --- | --- | --- |
| PlayerBody | PLAYER | ENEMY \| PROJECTILE_ENEMY \| PICKUP \| ENVIRONMENT_AND_TRIGGER |
| EnemyBody | ENEMY | PLAYER \| PROJECTILE_PLAYER \| HITBOX \| ENVIRONMENT_AND_TRIGGER |
| PlayerProjectile | PROJECTILE_PLAYER | ENEMY \| HURTBOX \| ENVIRONMENT_AND_TRIGGER |
| EnemyProjectile | PROJECTILE_ENEMY | PLAYER \| HURTBOX \| ENVIRONMENT_AND_TRIGGER |
| PlayerHitbox | HITBOX | ENEMY \| HURTBOX |
| PlayerHurtbox | HURTBOX | PROJECTILE_ENEMY \| ENVIRONMENT_AND_TRIGGER |
| EnemyHurtbox | HURTBOX | PROJECTILE_PLAYER \| HITBOX |
| Pickup | PICKUP | PLAYER |
| TriggerArea | ENVIRONMENT_AND_TRIGGER | PLAYER |

## 4. Friendly Fire Rule

- Friendly fire projectile musuh ke musuh: nonaktif.
- Projectile player tidak mengenai player sendiri.

## 5. Runtime Helpers

- Action constants: scripts/autoload/game_input.gd
- Layer and mask constants: scripts/autoload/physics_layers.gd

Contoh penggunaan:

```gdscript
var input_vector := GameInput.movement_vector()

$PlayerBody.collision_layer = PhysicsLayers.PLAYER
$PlayerBody.collision_mask = PhysicsLayers.MASK_PLAYER_BODY
```

## 6. Verifikasi Cepat

1. Buka Project Settings > Input Map, pastikan semua action ada.
2. Buka Project Settings > Layer Names > 2D Physics, pastikan 8 layer sudah bernama.
3. Jalankan project lalu test input: move, attack, dash, vestige_1, vestige_2.
4. Aktifkan Visible Collision Shapes dan cek behavior layer-mask sesuai tabel.
