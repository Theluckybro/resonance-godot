# Game Design Document (GDD)
## Project: Resonance

## 1. Ringkasan Eksekutif
- Genre: 2D Top-Down Action RPG Roguelite (arena-based)
- Visual Style: Pixel art (proporsi 16-bit klasik atau chibi)
- Platform: PC (Windows, Linux)
- Engine: Godot Engine 4.x
- Logline: Bertahan hidup di arena labirin yang terus berubah dengan cara menyerap dan menggunakan kemampuan monster yang baru saja dikalahkan.

### Pilar Desain
1. Adaptasi cepat: pemain harus sering mengganti komposisi Vestige sesuai kondisi arena.
2. Combat ringkas dan responsif: kontrol sederhana, keputusan taktis tinggi.
3. Scope realistis: fokus pada konten sedikit tetapi replayable.

## 2. Core Gameplay Loop
Siklus utama permainan:
1. Bertarung: menghadapi wave musuh dalam arena tertutup.
2. Absorpsi: mengambil orb Vestige/Jiwa yang dijatuhkan musuh (drop rate berbasis RNG).
3. Adaptasi: memasang Vestige ke slot skill (maks. 2 slot aktif + 1 slot dash).
4. Progresi: berpindah ke arena berikutnya dengan tingkat kesulitan meningkat.
5. Ulangi: kombinasi musuh, layout, dan pilihan Vestige memaksa strategi baru tiap run.

## 3. Mekanik Utama: Sistem Vestige
Karakter utama memiliki kit dasar minimal:
- Serangan dasar: tebasan/tusukan pedang
- Mobilitas dasar: dash

Kekuatan utama datang dari Vestige monster yang diserap.

### 3.1 Vestige Aktif (Serangan)
- Saat diaktifkan, sprite monster muncul sesaat, menjalankan animasi serangan, memberi damage, lalu menghilang.
- Contoh:
  - Vestige Slime: loncatan AoE di area kecil
  - Vestige Archer Goblin: tembakan proyektil lurus

### 3.2 Vestige Utilitas (Modifikasi Dash)
- Menggantikan dash standar pemain.
- Contoh:
  - Vestige Bat: dash dapat menembus rintangan tipis
  - Vestige Fire Elemental: dash meninggalkan jejak api yang melukai musuh

### 3.3 Aturan Slot dan Batasan (MVP)
- 2 slot Vestige Aktif dan 1 slot Vestige Dash.
- Satu Vestige hanya dapat dipasang pada satu slot.
- Ganti Vestige hanya bisa dilakukan di momen aman (antar-room) untuk menjaga ritme.
- Tiap Vestige memiliki cooldown agar tidak ada spam ability tunggal.

## 4. Level Design dan Skala Arena
Untuk mencegah scope creep:
- Struktur: room-based, bukan open world.
- Referensi pengalaman: Hades / Enter the Gungeon.
- Ukuran arena: 1.0 hingga 1.5 viewport.
- Kamera: minim scrolling agar pemain fokus pada action readability.
- Variasi: 1-2 tileset awal (mis. Dungeon Batu, Dungeon Lumut) dengan layout rintangan/jebakan acak.

### Target Variasi Room (MVP)
- 8-12 pola room total
- 3 tipe fungsi room:
  - Combat room (utama)
  - Transition room (napas singkat)
  - Reward room (pilihan Vestige/upgrade sederhana)

## 5. AI dan Musuh
Arena tertutup membuat navigasi musuh menjadi faktor penting.

### 5.1 Pathfinding
- Gunakan A* (A-Star) dengan NavMesh atau grid-based movement bawaan Godot.
- Tujuan: musuh melee tetap bisa mengejar pemain tanpa tersangkut obstacle.

### 5.2 State Machine Musuh
State dasar:
1. Idle/Patrol: gerak acak atau menunggu.
2. Chase: mengejar pemain lewat rute valid.
3. Attack: berhenti, animasi serang, lalu kembali evaluasi state.

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
