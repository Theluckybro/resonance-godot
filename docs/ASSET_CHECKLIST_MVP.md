# Asset Production Checklist

Dokumen ini dipakai sebagai checklist produksi awal untuk MVP project Resonance.

## Skala Prioritas

- `P0` = wajib untuk prototype playable
- `P1` = wajib untuk MVP yang layak diuji
- `P2` = bagus untuk polish, bisa menyusul

## Checklist Asset Produksi

### 1. Visual Character dan Combat

- [ ] Finalisasi ukuran sprite player dan grid pixel art
- [ ] Buat sprite sheet player `idle`
- [ ] Buat sprite sheet player `run`
- [ ] Buat sprite sheet player `basic_attack`
- [ ] Buat sprite sheet player `dash`
- [ ] Buat sprite sheet player `hit`
- [ ] Buat sprite sheet player `death`
- [ ] Buat efek tebasan pedang
- [ ] Buat efek dash trail dasar
- [ ] Buat efek hit spark umum
- [ ] Buat efek damage flash untuk player dan enemy

### 2. Visual Enemy

- [ ] Desain enemy melee cepat
- [ ] Buat animasi enemy melee cepat `idle`
- [ ] Buat animasi enemy melee cepat `move`
- [ ] Buat animasi enemy melee cepat `attack`
- [ ] Buat animasi enemy melee cepat `hit`
- [ ] Buat animasi enemy melee cepat `death`
- [ ] Desain enemy melee berat
- [ ] Buat animasi enemy melee berat `idle`
- [ ] Buat animasi enemy melee berat `move`
- [ ] Buat animasi enemy melee berat `attack`
- [ ] Buat animasi enemy melee berat `hit`
- [ ] Buat animasi enemy melee berat `death`
- [ ] Desain enemy ranged
- [ ] Buat animasi enemy ranged `idle`
- [ ] Buat animasi enemy ranged `move`
- [ ] Buat animasi enemy ranged `attack`
- [ ] Buat animasi enemy ranged `hit`
- [ ] Buat animasi enemy ranged `death`
- [ ] Buat sprite proyektil enemy ranged

### 3. Visual Echo dan Ability

- [ ] Tentukan daftar 6-8 Echo MVP
- [ ] Buat ikon untuk semua Echo MVP
- [ ] Buat sprite orb pickup Echo
- [ ] Buat efek absorb Echo
- [ ] Buat efek cast untuk Echo aktif tipe melee
- [ ] Buat efek cast untuk Echo aktif tipe projectile
- [ ] Buat efek dash Echo tipe blink atau phase
- [ ] Buat efek dash Echo tipe fire trail
- [ ] Buat indikator cooldown di HUD

### 4. Environment dan Room

- [ ] Finalisasi tema biome dungeon pertama
- [ ] Buat tileset lantai utama
- [ ] Buat tileset dinding utama
- [ ] Buat tileset sudut dan transisi dinding
- [ ] Buat tileset pintu masuk atau keluar room
- [ ] Buat obstacle kecil
- [ ] Buat obstacle besar
- [ ] Buat hazard lantai seperti duri atau api
- [ ] Buat dekorasi dungeon ringan
- [ ] Buat marker portal atau reward pedestal
- [ ] Buat 8-12 layout room dasar

### 5. UI dan UX

- [ ] Pilih font utama UI
- [ ] Buat health bar player
- [ ] Buat 2 slot Echo aktif
- [ ] Buat 1 slot Echo dash
- [ ] Buat overlay cooldown skill
- [ ] Buat indikator room clear
- [ ] Buat panel pause menu
- [ ] Buat panel game over
- [ ] Buat panel victory atau end-of-run
- [ ] Buat tombol UI dasar

### 6. Audio

- [ ] Pilih referensi style audio dan musik
- [ ] Siapkan 1 loop musik combat
- [ ] Siapkan 1 loop musik menu
- [ ] Siapkan 1 stinger reward atau room clear
- [ ] Siapkan SFX basic attack player
- [ ] Siapkan SFX dash player
- [ ] Siapkan SFX player kena hit
- [ ] Siapkan SFX enemy melee attack
- [ ] Siapkan SFX enemy ranged attack
- [ ] Siapkan SFX projectile hit
- [ ] Siapkan SFX enemy death
- [ ] Siapkan SFX absorb Echo
- [ ] Siapkan SFX equip Echo
- [ ] Siapkan SFX activate Echo
- [ ] Siapkan SFX UI hover dan click

### 7. Design dan Data

- [ ] Buat daftar nama semua enemy MVP
- [ ] Buat sheet statistik enemy MVP
- [ ] Buat sheet statistik Echo MVP
- [ ] Buat tabel damage, cooldown, dan scaling
- [ ] Buat daftar 8-12 layout room
- [ ] Buat referensi art direction
- [ ] Buat referensi audio direction
- [ ] Buat daftar fitur yang ditunda setelah MVP

### 8. Setup Teknis dan Produksi

- [ ] Kunci versi Godot yang dipakai tim
- [ ] Tetapkan resolusi target dan pixel scale
- [ ] Siapkan input map keyboard
- [ ] Siapkan scene dasar `Player`
- [ ] Siapkan scene dasar `EnemyBase`
- [ ] Siapkan scene dasar `Room`
- [ ] Siapkan scene dasar `HUD`
- [ ] Siapkan struktur data untuk Echo
- [ ] Tetapkan collision layer dan mask
- [ ] Siapkan `autoload` inti jika diperlukan
- [ ] Siapkan export preset Windows
- [ ] Siapkan export preset Linux
- [ ] Tetapkan aturan naming file dan folder
- [ ] Siapkan board task untuk milestone prototype dan MVP

## Tabel Kebutuhan Asset MVP

| Kategori | Asset | Jumlah MVP | Prioritas | Catatan |
| --- | --- | ---: | --- | --- |
| Character | Sprite sheet player | 1 set | P0 | Minimal berisi idle, run, attack, dash, hit, death |
| Character | Efek slash player | 1 | P0 | Untuk basic attack readability |
| Character | Efek dash trail dasar | 1 | P0 | Bisa sangat sederhana |
| Character | Efek hit spark umum | 1 | P0 | Dipakai ulang untuk banyak serangan |
| Enemy | Enemy melee cepat | 1 archetype | P0 | Wajib untuk pressure dekat |
| Enemy | Enemy melee berat | 1 archetype | P1 | Menambah variasi timing dan threat |
| Enemy | Enemy ranged | 1 archetype | P0 | Wajib untuk zoning |
| Enemy | Sprite proyektil ranged | 1 | P0 | Bisa reuse palette musuh |
| Enemy | Animasi per enemy | 5 per enemy | P0 | Idle, move, attack, hit, death |
| Echo | Echo aktif | 4 | P1 | Kombinasi serangan jarak dekat dan jarak jauh |
| Echo | Echo dash modifier | 2-4 | P1 | Minimal 2 untuk variasi movement |
| Echo | Ikon Echo | 6-8 | P1 | Satu ikon per Echo |
| Echo | Orb pickup Echo | 1 | P0 | Recolor bisa dipakai untuk variasi |
| Echo | Efek absorb Echo | 1 | P0 | Penting untuk feedback loot |
| Echo | Efek cast Echo melee | 1 | P1 | Bisa dipakai ulang untuk beberapa Echo |
| Echo | Efek cast Echo projectile | 1 | P1 | Bisa dipakai ulang untuk beberapa Echo |
| Echo | Efek dash fire trail | 1 | P1 | Untuk utility Echo contoh |
| Echo | Efek blink atau phase | 1 | P1 | Untuk dash menembus obstacle tipis |
| Environment | Tileset lantai dungeon | 1 set | P0 | Dasar biome pertama |
| Environment | Tileset dinding dungeon | 1 set | P0 | Termasuk sudut dan variasi minimal |
| Environment | Obstacle kecil | 3-5 | P1 | Batu, peti, pilar kecil |
| Environment | Obstacle besar | 2-3 | P1 | Pilar besar, puing, blok |
| Environment | Hazard lantai | 1-2 | P1 | Duri, api, atau racun |
| Environment | Dekorasi ringan | 5-8 | P2 | Tulang, lumut, retakan, obor |
| Room | Layout room combat | 6-8 | P0 | Inti run |
| Room | Layout room transition | 1-2 | P1 | Napas antar combat |
| Room | Layout room reward | 1-2 | P1 | Tempat pilihan upgrade atau Echo |
| Room | Portal, door, atau reward pedestal | 2-3 | P1 | Asset interaksi ruang |
| UI | Health bar player | 1 | P0 | HUD minimum |
| UI | Slot Echo aktif | 2 | P0 | Dua slot skill utama |
| UI | Slot Echo dash | 1 | P0 | Slot utility movement |
| UI | Overlay cooldown | 1 system | P0 | Bisa berupa radial atau fill sederhana |
| UI | Panel pause | 1 | P1 | Untuk flow bermain dasar |
| UI | Panel game over | 1 | P1 | Untuk loop selesai |
| UI | Panel victory atau run end | 1 | P1 | Jika run punya end condition |
| UI | Tombol UI dasar | 1 set | P1 | Normal, hover, pressed |
| UI | Font utama | 1 | P0 | Harus terbaca jelas |
| Audio | Musik combat | 1 loop | P1 | Cukup satu untuk MVP |
| Audio | Musik menu | 1 loop | P2 | Bisa menyusul jika perlu |
| Audio | Stinger reward atau room clear | 1 | P2 | Optional awal |
| Audio | SFX basic attack | 1 | P0 | Feedback utama combat |
| Audio | SFX dash | 1 | P0 | Feedback movement |
| Audio | SFX hit player | 1 | P0 | Kejelasan damage diterima |
| Audio | SFX enemy melee attack | 1 | P1 | Bisa reuse antar enemy melee |
| Audio | SFX enemy ranged attack | 1 | P0 | Penting untuk telegraph |
| Audio | SFX projectile hit | 1 | P0 | Bisa dipakai umum |
| Audio | SFX enemy death | 1-3 | P1 | Variasi kecil cukup |
| Audio | SFX absorb Echo | 1 | P0 | Inti identitas sistem Echo |
| Audio | SFX equip atau activate Echo | 2 | P1 | Equip dan cast |
| Audio | SFX UI hover dan click | 2 | P2 | Boleh tahap belakangan |
| Design Data | Sheet statistik enemy | 1 dokumen | P0 | Basis balancing dan AI |
| Design Data | Sheet statistik Echo | 1 dokumen | P0 | Basis balancing skill |
| Design Data | Sheet layout room | 1 dokumen | P0 | Room count dan isi spawn |
| Design Data | Art direction board | 1 dokumen | P1 | Menjaga konsistensi visual |
| Design Data | Audio direction board | 1 dokumen | P2 | Bisa ringkas di awal |
| Technical | Input map | 1 konfigurasi | P0 | Wajib sebelum testing feel |
| Technical | Collision matrix | 1 konfigurasi | P0 | Cegah bug interaksi |
| Technical | Export preset Windows | 1 konfigurasi | P1 | Untuk build uji utama |
| Technical | Export preset Linux | 1 konfigurasi | P2 | Bisa sesudah Windows stabil |

## Rekomendasi Urutan Produksi

1. Selesaikan semua item `P0` terlebih dulu dengan placeholder jika perlu.
2. Lanjutkan item `P1` untuk mengubah prototype menjadi MVP yang layak diuji.
3. Kerjakan `P2` hanya setelah core loop, performa, dan balancing dasar sudah stabil.

## Catatan Eksekusi

- Untuk prototype pertama, placeholder art lebih penting daripada asset final.
- Jangan produksi semua Echo sekaligus; buat 2 Echo aktif dan 1 Echo dash lebih dulu sebagai jalur validasi sistem.
- Jika bekerja solo, target yang realistis adalah menyelesaikan `P0` dalam 1 sprint, lalu `P1` per kategori.