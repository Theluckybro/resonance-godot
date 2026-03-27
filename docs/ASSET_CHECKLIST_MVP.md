# Asset Production Checklist

Dokumen ini dipakai sebagai checklist produksi awal untuk MVP project Resonance.

## Skala Prioritas

- `P0` = wajib untuk prototype playable
- `P1` = wajib untuk MVP yang layak diuji
- `P2` = bagus untuk polish, bisa menyusul

## Checklist Asset Produksi

### 1. Visual Character dan Combat

- [x] Finalisasi ukuran sprite player dan grid pixel art [P0]
- [x] Buat sprite sheet player `idle` [P0]
- [x] Buat sprite sheet player `run` [P0]
- [x] Buat sprite sheet player `basic_attack` [P0]
- [x] Buat sprite sheet player `dash` [P0]
- [x] Buat sprite sheet player `hit` [P0]
- [x] Buat sprite sheet player `death` [P0]
- [x] Buat efek tebasan pedang [P0]
- [x] Buat efek dash trail dasar [P0]
- [x] Buat efek hit spark umum [P0]
- [ ] Buat efek damage flash untuk player dan enemy [P1]

### 2. Visual Enemy

- [x] Desain enemy role Duelist [P0]
- [x] Buat animasi enemy role Duelist `idle` [P0]
- [x] Buat animasi enemy role Duelist `move` [P0]
- [x] Buat animasi enemy role Duelist `attack` [P0]
- [x] Buat animasi enemy role Duelist `hit` [P0]
- [x] Buat animasi enemy role Duelist `death` [P0]
- [x] Desain enemy role Bruiser [P1]
- [x] Buat animasi enemy role Bruiser `idle` [P1]
- [x] Buat animasi enemy role Bruiser `move` [P1]
- [x] Buat animasi enemy role Bruiser `attack` [P1]
- [x] Buat animasi enemy role Bruiser `hit` [P1]
- [x] Buat animasi enemy role Bruiser `death` [P1]
- [x] Desain enemy role Skirmisher [P0]
- [x] Buat animasi enemy role Skirmisher `idle` [P0]
- [x] Buat animasi enemy role Skirmisher `move` [P0]
- [x] Buat animasi enemy role Skirmisher `attack` [P0]
- [x] Buat animasi enemy role Skirmisher `hit` [P0]
- [x] Buat animasi enemy role Skirmisher `death` [P0]
- [x] Desain enemy role Artillery [P0]
- [x] Buat animasi enemy role Artillery `idle` [P0]
- [x] Buat animasi enemy role Artillery `move` [P0]
- [x] Buat animasi enemy role Artillery `attack` [P0]
- [x] Buat animasi enemy role Artillery `hit` [P0]
- [x] Buat animasi enemy role Artillery `death` [P0]
- [x] Buat sprite proyektil enemy role Artillery [P0]
- [x] Desain enemy role Controller [P1]
- [x] Buat animasi enemy role Controller `idle` [P1]
- [x] Buat animasi enemy role Controller `move` [P1]
- [x] Buat animasi enemy role Controller `attack` [P1]
- [x] Buat animasi enemy role Controller `hit` [P1]
- [x] Buat animasi enemy role Controller `death` [P1]
- [ ] Buat VFX area control untuk role Controller [P1]

### 3. Visual Vestige dan Ability

- [ ] Tentukan daftar 6-8 Vestige MVP [P1]
- [ ] Buat ikon untuk semua Vestige MVP [P1]
- [x] Buat sprite orb pickup Vestige [P0]
- [ ] Buat efek absorb Vestige [P0]
- [ ] Buat efek cast untuk Vestige aktif tipe melee [P1]
- [ ] Buat efek cast untuk Vestige aktif tipe projectile [P1]
- [ ] Buat efek dash Vestige tipe blink atau phase [P1]
- [ ] Buat efek dash Vestige tipe fire trail [P1]
- [ ] Buat indikator cooldown di HUD [P0]

### 4. Environment dan Room

- [ ] Finalisasi tema biome dungeon pertama [P0]
- [x] Buat tileset lantai utama [P0]
- [x] Buat tileset dinding utama [P0]
- [x] Buat tileset sudut dan transisi dinding [P0]
- [ ] Buat tileset pintu masuk atau keluar room [P1]
- [ ] Buat obstacle kecil [P1]
- [ ] Buat obstacle besar [P1]
- [ ] Buat hazard lantai seperti duri atau api [P1]
- [ ] Buat dekorasi dungeon ringan [P2]
- [ ] Buat marker portal atau reward pedestal [P1]
- [ ] Buat 8-12 layout room dasar [P0]

### 5. UI dan UX

- [x] Pilih font utama UI [P0]
- [x] Buat health bar player [P0]
- [ ] Buat 2 slot Vestige aktif [P0]
- [ ] Buat 1 slot Vestige dash [P0]
- [ ] Buat overlay cooldown skill [P0]
- [ ] Buat indikator room clear [P1]
- [x] Buat panel pause menu [P1]
- [ ] Buat panel game over [P1]
- [ ] Buat panel victory atau end-of-run [P1]
- [x] Buat tombol UI dasar [P1]

### 6. Audio

- [x] Pilih referensi style audio dan musik [P1]
- [x] Siapkan 1 loop musik combat [P1]
- [x] Siapkan 1 loop musik menu [P2]
- [x] Siapkan 1 stinger reward atau room clear [P2]
- [x] Siapkan SFX basic attack player [P0]
- [x] Siapkan SFX dash player [P0]
- [x] Siapkan SFX player kena hit [P0]
- [x] Siapkan SFX enemy melee attack [P1]
- [x] Siapkan SFX enemy ranged attack [P0]
- [x] Siapkan SFX projectile hit [P0]
- [x] Siapkan SFX enemy death [P1]
- [x] Siapkan SFX absorb Vestige [P0]
- [ ] Siapkan SFX equip Vestige [P1]
- [x] Siapkan SFX activate Vestige [P1]
- [ ] Siapkan SFX UI hover dan click [P2]

### 7. Design dan Data

- [x] Buat daftar nama semua enemy MVP [P0]
- [x] Buat sheet statistik enemy MVP [P0]
- [ ] Buat sheet statistik Vestige MVP [P0]
- [ ] Buat tabel damage, cooldown, dan scaling [P0]
- [ ] Buat daftar 8-12 layout room [P0]
- [x] Dokumentasikan referensi art direction di docs/GDD_Resonance.md [P1]
- [x] Dokumentasikan referensi audio direction di docs/GDD_Resonance.md [P2]
- [ ] Buat daftar fitur yang ditunda setelah MVP [P1]

### 8. Setup Teknis dan Produksi

- [ ] Kunci versi Godot yang dipakai tim [P1]
- [x] Tetapkan resolusi target dan pixel scale [P0]
- [x] Siapkan input map keyboard [P0]
- [x] Siapkan scene dasar `Player` [P0]
- [x] Siapkan scene dasar `EnemyBase` [P0]
- [x] Siapkan scene dasar `Room` [P0]
- [x] Siapkan scene dasar `HUD` [P0]
- [x] Siapkan struktur data untuk Vestige [P0]
- [x] Tetapkan collision layer dan mask [P0]
- [x] Siapkan `autoload` inti jika diperlukan [P0]
- [ ] Siapkan export preset Windows [P1]
- [ ] Siapkan export preset Linux [P2]
- [ ] Tetapkan aturan naming file dan folder [P1]
- [ ] Siapkan board task untuk milestone prototype dan MVP [P1]

## Ringkasan Progress Otomatis

Jalankan `./scripts/utils/update_checklist_progress.ps1` setiap kali checklist berubah untuk memperbarui ringkasan ini.

<!-- PROGRESS_SUMMARY_START -->
_Auto-updated: 2026-03-27 11:03_

| Prioritas | Selesai | Total | Progress |
| --- | ---: | ---: | ---: |
| P0 | 52 | 62 | 83.9% |
| P1 | 20 | 42 | 47.6% |
| P2 | 3 | 6 | 50.0% |
| Total | 75 | 110 | 68.2% |
<!-- PROGRESS_SUMMARY_END -->

## Tabel Kebutuhan Asset MVP

| Kategori | Asset | Jumlah MVP | Prioritas | Catatan |
| --- | --- | ---: | --- | --- |
| Character | Sprite sheet player | 1 set | P0 | Minimal berisi idle, run, attack, dash, hit, death |
| Character | Efek slash player | 1 | P0 | Untuk basic attack readability |
| Character | Efek dash trail dasar | 1 | P0 | Bisa sangat sederhana |
| Character | Efek hit spark umum | 1 | P0 | Dipakai ulang untuk banyak serangan |
| Enemy | Enemy role Duelist | 1 archetype | P0 | Wajib untuk pressure dekat |
| Enemy | Enemy role Bruiser | 1 archetype | P1 | Menambah variasi timing dan threat |
| Enemy | Enemy role Skirmisher | 1 archetype | P0 | Menambah flank dan reposition |
| Enemy | Enemy role Artillery | 1 archetype | P0 | Wajib untuk zoning |
| Enemy | Enemy role Controller | 1 archetype | P1 | Menambah area denial sederhana |
| Enemy | Sprite proyektil role Artillery | 1 | P0 | Bisa reuse palette musuh |
| Enemy | Animasi per enemy | 5 per enemy | P0 | Idle, move, attack, hit, death |
| Vestige | Vestige aktif | 4 | P1 | Kombinasi serangan jarak dekat dan jarak jauh |
| Vestige | Vestige dash modifier | 2-4 | P1 | Minimal 2 untuk variasi movement |
| Vestige | Ikon Vestige | 6-8 | P1 | Satu ikon per Vestige |
| Vestige | Orb pickup Vestige | 1 | P0 | Recolor bisa dipakai untuk variasi |
| Vestige | Efek absorb Vestige | 1 | P0 | Penting untuk feedback loot |
| Vestige | Efek cast Vestige melee | 1 | P1 | Bisa dipakai ulang untuk beberapa Vestige |
| Vestige | Efek cast Vestige projectile | 1 | P1 | Bisa dipakai ulang untuk beberapa Vestige |
| Vestige | Efek dash fire trail | 1 | P1 | Untuk utility Vestige contoh |
| Vestige | Efek blink atau phase | 1 | P1 | Untuk dash menembus obstacle tipis |
| Environment | Tileset lantai dungeon | 1 set | P0 | Dasar biome pertama |
| Environment | Tileset dinding dungeon | 1 set | P0 | Termasuk sudut dan variasi minimal |
| Environment | Obstacle kecil | 3-5 | P1 | Batu, peti, pilar kecil |
| Environment | Obstacle besar | 2-3 | P1 | Pilar besar, puing, blok |
| Environment | Hazard lantai | 1-2 | P1 | Duri, api, atau racun |
| Environment | Dekorasi ringan | 5-8 | P2 | Tulang, lumut, retakan, obor |
| Room | Layout room combat | 6-8 | P0 | Inti run |
| Room | Layout room transition | 1-2 | P1 | Napas antar combat |
| Room | Layout room reward | 1-2 | P1 | Tempat pilihan upgrade atau Vestige |
| Room | Portal, door, atau reward pedestal | 2-3 | P1 | Asset interaksi ruang |
| UI | Health bar player | 1 | P0 | HUD minimum |
| UI | Slot Vestige aktif | 2 | P0 | Dua slot skill utama |
| UI | Slot Vestige dash | 1 | P0 | Slot utility movement |
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
| Audio | SFX absorb Vestige | 1 | P0 | Inti identitas sistem Vestige |
| Audio | SFX equip atau activate Vestige | 2 | P1 | Equip dan cast |
| Audio | SFX UI hover dan click | 2 | P2 | Boleh tahap belakangan |
| Design Data | Sheet statistik enemy | 1 dokumen | P0 | Basis balancing dan AI |
| Design Data | Sheet statistik Vestige | 1 dokumen | P0 | Basis balancing skill |
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
- Jangan produksi semua Vestige sekaligus; buat 2 Vestige aktif dan 1 Vestige dash lebih dulu sebagai jalur validasi sistem.
- Jika bekerja solo, target yang realistis adalah menyelesaikan `P0` dalam 1 sprint, lalu `P1` per kategori.