# Draft Portofolio Proyek - Resonance

## Ringkasan Singkat
**Resonance** adalah game 2D top-down action roguelite yang saya kembangkan menggunakan **Godot 4.x**. Nilai utama proyek ini ada pada sistem **Vestige**, yaitu mekanik untuk menyerap kemampuan musuh dan memakainya sebagai skill aktif atau modifikasi dash.

> Status: **In Development** (masih tahap prototipe aktif).

## Informasi Proyek
- Nama proyek: Resonance
- Engine: Godot 4.x
- Platform target: PC (Windows, Linux)
- Genre: 2D Top-Down Action Roguelite
- Visual style: Pixel art
- Target versi saat ini: MVP prototype

## Konsep dan Tujuan
Resonance dirancang untuk menghadirkan combat top-down yang cepat dan adaptif. Pemain tidak hanya mengandalkan serangan dasar, tetapi harus menyesuaikan build selama run melalui Vestige yang didapat dari musuh.

Tujuan pengembangan MVP:
- Membuat core loop yang playable end-to-end.
- Menyediakan sistem skill modular berbasis Vestige.
- Menjaga scope proyek tetap realistis untuk iterasi cepat.

## Core Gameplay Loop
1. Pemain bertarung melawan wave musuh di arena tertutup.
2. Musuh yang dikalahkan menjatuhkan orb Vestige.
3. Vestige dipasang ke 2 slot skill aktif dan 1 slot dash.
4. Pemain lanjut ke room berikutnya dengan tantangan meningkat.
5. Siklus berulang sampai run berakhir.

## Fitur yang Sudah Tersedia (Prototype)
- Baseline scene inti: Player, Enemy, Room.
- Combat dasar: movement, dash, basic attack, dan damage flow.
- Struktur data archetype musuh untuk balancing awal.
- Pickup Vestige dasar.
- Dokumen teknis input map dan collision matrix.

## Kontribusi dan Nilai Teknis
Proyek ini menunjukkan kemampuan saya dalam:
- Menyusun arsitektur proyek game berbasis scene modular di Godot.
- Membangun sistem gameplay iteratif dengan data-driven balancing.
- Menjaga konsistensi struktur folder, dokumentasi, dan workflow produksi aset.
- Mengelola scope MVP agar fitur inti selesai lebih dahulu sebelum polish.

## Dokumentasi Pendukung
- GDD: [GDD_Resonance.md](GDD_Resonance.md)
- Checklist produksi aset: [ASSET_CHECKLIST_MVP.md](ASSET_CHECKLIST_MVP.md)
- Setup teknis input dan collision: [TECH_SETUP_INPUT_COLLISION.md](TECH_SETUP_INPUT_COLLISION.md)

## Roadmap Singkat
Fokus pengembangan berikutnya:
- Penyempurnaan HUD dan UX combat.
- Penambahan variasi room dan encounter.
- Penambahan data Vestige serta balancing cooldown/damage.
- Integrasi audio dan feedback visual yang lebih kuat.

## Catatan untuk Portofolio Admin Lab
Poin yang bisa ditonjolkan saat presentasi:
- Pendekatan engineering pada proyek game, bukan hanya aspek visual.
- Kemampuan dokumentasi teknis untuk kolaborasi tim.
- Praktik scope management dan prioritas produksi.
- Kemampuan iterasi cepat berbasis feedback playtest.

## Penutup
Resonance saat ini masih **in development**, namun sudah memiliki fondasi gameplay dan struktur teknis yang jelas untuk dilanjutkan menuju MVP yang stabil dan layak diuji.
