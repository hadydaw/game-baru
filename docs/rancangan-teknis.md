# Rancangan Teknis — Jaringan Terbuka Nusantara (tahap 1)

Status: menunggu persetujuan. Belum ada implementasi.
Acuan: docs/GDD.md

## 1. Sistem bahasa (ketentuan wajib)
- Locale default: `id`. Semua teks tampil dalam Bahasa Indonesia saat pertama kali dibuka.
- Tidak ada `en` sebagai fallback utama.
- Teks dipanggil lewat kunci (`Locale.t("misi01.pembuka")`). Jika kunci tidak ada di locale aktif, dipakai teks `id`. Jika `id` juga tidak ada, kunci ditampilkan apa adanya dan dicatat di log.
- File: `data/locale/id.json` (wajib), `data/locale/en.json` (nanti).
- Pengaturan bahasa: field `locale` di save dan settings. Tahap 1 hanya memuat `id`. Perubahan bahasa manual dijadwalkan setelah `en` tersedia.
- Pesan error parser, pesan save, dan notifikasi juga memakai kunci lokalisasi.

## 2. Struktur node
Field: `id`, `nama_key`, `tipe` (server/workstation/gateway, label saja), `keamanan` {`tingkat` 1–3, `lapisan` [id puzzle]}, `status` (terkunci/terbuka/dikuasai), `koneksi` [id], `berkas` [id], `posisi` {x, y}.
Aturan: node terlihat setelah node terhubung berstatus terbuka atau dikuasai. Terkunci berarti semua lapisan belum selesai.

## 3. Format misi (JSON)
File: `data/misi/misi_01.json`. Field: `schema`, `id`, `judul_key`, `pembuka_key`, `tujuan` [{id, teks_key, selesai_bila}], `node`, `berkas`, `selesai_bila` {semua | salah_satu}, `dialog_event`, `hadiah` {flag, misi_berikutnya}.
Kondisi yang didukung: `node_terbuka`, `bukti_punya`, `flag`, dan penggabungan AND/OR. Dievaluasi saat state berubah.

## 4. Terminal
- Perintah: `bantuan`, `pindai`, `daftar`, `hubungkan <id>`, `buka <id>`, `ambil <id>`, `bukti`, `petunjuk`, `keluar`.
- Huruf besar/kecil tidak dibedakan. Argumen dipisah spasi, id memakai `-`.
- Output berupa baris bertipe: info, sukses, peringatan, error. Warna mengikuti tipe.
- Input tidak dikenal: pesan dari kunci `terminal.tidak_dikenal` dengan saran `bantuan`.
- Parser adalah fungsi murni yang mengembalikan `{ok, pesan, aksi}`. Perubahan state dilakukan oleh `Game`.
- Tombol cepat di atas keyboard virtual, isinya berubah sesuai konteks.

## 5. Puzzle pencocokan pola (misi 1)
- Pola 4 simbol dari 6 simbol. Simbol boleh berulang. Pola dibuat dari seed di data misi.
- 6 percobaan per lapisan. Umpan balik: ● posisi tepat, ○ simbol ada tetapi posisi salah.
- Berhasil: pola cocok. Node terbuka jika semua lapisan selesai.
- Gagal: 6 percobaan habis, puzzle terkunci 30 detik waktu nyata, lalu percobaan direset. Node tidak terkunci permanen.
- Petunjuk: tersedia setelah 3 kegagalan. Satu petunjuk per perintah, tanpa penalti, diambil dari daftar petunjuk node.
- Interaksi: pilih slot, lalu pilih simbol di palet. Tombol `coba`. Semua tombol minimal 48 px.

## 6. Bukti dan berkas
- `ambil <id>` memindahkan berkas ke daftar bukti. Isi berkas tidak disimpan di save; dimuat ulang dari data misi berdasarkan id.
- Entri bukti: {id, diambil_dari, dibaca, penting}.
- `buka <id>` menampilkan isi dan menandai dibaca. Berkas penting yang dibaca memberi flag cerita.

## 7. Save
- File: `user://save.json`, cadangan `user://save.bak`, sementara `save.tmp`.
- Field: `schema`, `dibuat`, `locale`, `misi`, `node`, `bukti`, `flag`, `terakhir_node`.
- Penulisan atomik: tulis `save.tmp`, salin file lama ke `save.bak`, ganti nama menjadi `save.json`.
- Migrasi bertingkat `migrasi(data)`. Save dengan schema lebih baru tidak dimuat.
- Auto-save: setelah misi selesai, setelah lapisan selesai, dan saat aplikasi ke latar belakang.
- Pemulihan: coba `save.json`, lalu `save.bak`, lalu mulai baru dengan pemberitahuan. Data tidak valid dibuang dan dicatat.

## 8. Arsitektur Godot
Folder: `autoload/` (Game, Locale), `core/` (node_model, mission_state, evidence, command_parser, pattern_puzzle, condition), `save/` (save_service, migrations), `data/misi/`, `data/locale/`, `ui/` (main, terminal, network_map, puzzle_view), `ui/layout/` (layout_controller), `tests/`.
- `core/` adalah RefCounted tanpa akses scene tree, bisa diuji unit.
- `Game` memegang state. UI mengirim aksi ke `Game` dan membaca state lewat signal.
- Alur: input UI → command_parser → Game → state dan save → signal → UI.
- Potret: peta di atas, terminal di bawah. Lanskap: peta di kiri, terminal di kanan. Tata letak memakai Container dan anchor, dipilih oleh layout_controller saat ukuran viewport berubah.
- Pengujian: GUT (gratis, open-source). Perlu persetujuan karena menambah addon.

## 9. Keputusan yang masih menunggu persetujuan
1. Jumlah simbol (6) dan slot (4).
2. Penguncian 30 detik setelah 6 kegagalan.
3. Petunjuk tanpa penalti.
4. Penambahan GUT sekarang atau nanti.
5. Format nama `misi_01` dan kunci `misi01.*`.
