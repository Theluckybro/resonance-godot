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

## 7. Standar Final Pixel Art (Player dan Grid)

Spesifikasi ini dikunci sebagai standar tim untuk MVP saat ini:

- Player frame: 16x32 px.
- Tile grid world: 16x16 px.
- Scaling runtime: integer only.

Konfigurasi engine yang harus dipertahankan:

- window/stretch/mode = viewport
- window/stretch/scale_mode = integer
- textures/canvas_textures/default_texture_filter = Nearest
- 2d/snap/snap_2d_transforms_to_pixel = true
- 2d/snap/snap_2d_vertices_to_pixel = true

## 8. Aturan Ekspor Asset Player Baru

Setiap aset baru player wajib mengikuti aturan berikut:

1. Satu frame karakter harus align ke grid 16x32.
2. Ukuran spritesheet harus kelipatan frame (width kelipatan 16, height kelipatan 32).
3. Hindari offset subpixel saat slicing frame (jangan ada frame yang bergeser pecahan pixel).
4. Simpan file baru ke assets/Sprites/Player/Final16x32 dan biarkan file .import terbuat otomatis oleh Godot.
5. Gunakan filter nearest (tanpa blur) dan jangan override ke linear.

Catatan:

- File PNG lama di assets/Sprites/Player root diperlakukan sebagai legacy/reference.
- Validator akan menolak PNG baru yang disimpan di root assets/Sprites/Player.

## 9. Verifikasi Otomatis Spesifikasi Player

Gunakan script berikut setiap kali ada perubahan aset player atau scene player:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\scripts\utils\validate_player_pixel_spec.ps1
```

Script memverifikasi:

- Setting pixel-art penting di project.godot.
- Semua region frame player di scenes/player/player.tscn tetap 16x32.
- Tidak ada track animasi yang mengubah AnimatedSprite2D position/offset secara acak.
- Semua PNG baru di assets/Sprites/Player/Final16x32 sesuai grid 16x32.
- PNG legacy di assets/Sprites/Player root hanya diperingatkan (warning), bukan dijadikan blocker.

## 10. Playtest Cepat Pixel Readability (1 Menit)

Checklist playtest manual:

1. Jalankan project, masuk ke scene combat.
2. Uji run selama 10-15 detik sambil ubah arah cepat.
3. Uji dash berulang ke 4 arah.
4. Uji attack kiri dan kanan beberapa kali.
5. Aktifkan Visible Collision Shapes dan pastikan kapsul collider tetap pas ke badan player.

Kriteria lulus:

- Tidak ada wobble pixel pada badan player saat run/dash/attack.
- Tidak ada blur pada sprite saat camera bergerak normal.
- Collider player tetap align dan tidak tampak meleset dari visual utama.

## 11. Status Verifikasi Saat Ini

Snapshot 2026-03-19:

- Validasi otomatis spesifikasi player: PASS via scripts/utils/validate_player_pixel_spec.ps1.
- Aset PNG lama di assets/Sprites/Player root diperlakukan legacy dan tidak memblokir standar baru.
- Jalur aset baru sudah dikunci ke assets/Sprites/Player/Final16x32.
- Playtest visual interaktif tetap direkomendasikan saat sesi QA di Godot Editor.
