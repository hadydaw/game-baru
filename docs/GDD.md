# JARINGAN TERBUKA NUSANTARA — Game Design Document

Versi: 0.1 (konsep disetujui, belum diimplementasi)
Platform: Android native (Godot 4.6.3, GDScript). Tanpa WebView.
Bahasa utama: Bahasa Indonesia. Struktur lokalisasi disiapkan agar Bahasa Inggris bisa ditambahkan.

## 1. Ringkasan
Genre: simulasi hacking, puzzle, petualangan, story-driven.
Gaya: thriller serius, misteri, investigasi digital, konspirasi.
Premis: Pemain adalah peneliti keamanan independen. Ia menyusuri jaringan fiktif untuk mengungkap konspirasi yang melibatkan data warga. Semua interaksi dilakukan lewat terminal.

## 2. Pilar desain
- Terminal adalah antarmuka utama. Semua aksi lewat perintah teks yang disederhanakan.
- Peta jaringan sebagai ruang eksplorasi. Node adalah komputer fiktif yang bisa dimasuki.
- Puzzle berbasis logika. Tidak ada waktu tekan atau ketikan cepat.
- Fiktif sepenuhnya. Nama perangkat, perintah, dan protokol karangan. Tidak memuat teknik nyata yang bisa dipakai di dunia luar.
- Orisinal. Tidak memakai aset, cerita, kode, atau desain dari game lain.

## 3. Loop inti
1. Terima misi dari kontak di terminal.
2. Pindai jaringan dan temukan node target di peta.
3. Masuk ke node, pecahkan lapisan keamanannya lewat puzzle.
4. Ambil bukti atau data, lalu simpan sebagai berkas.
5. Analisis bukti di papan investigasi, lalu buka misi berikutnya.

## 4. Ruang lingkup tahap 1 (disetujui)
- Satu misi pendek dengan tiga node.
- Satu jenis puzzle: pencocokan pola.
- Terminal dasar: perintah bantuan, daftar, buka node, ambil berkas, keluar.
- Peta jaringan sederhana dengan tiga node.
- Sistem penyimpanan progres: satu slot, auto-simpan.
- Di luar tahap 1: karakter lain, bab cerita panjang, jenis puzzle lain, papan investigasi penuh, ekspor/impor save, Bahasa Inggris.

## 5. Sistem utama
### 5.1 Terminal
- Perintah ditulis pemain atau dipilih dari tombol di layar.
- Output ditampilkan dengan gaya monospace dan gulir.
- Perintah yang tidak dikenal memberi pesan bantuan, bukan error teknis.

### 5.2 Peta jaringan
- Node punya nama, tingkat keamanan (rendah, sedang, tinggi), dan status (terkunci, terbuka, sudah dikuasai).
- Koneksi antarnode ditampilkan sebagai garis.
- Pemain menggeser peta, mencubit untuk zoom, dan mengetuk node untuk memilih.

### 5.3 Puzzle pencocokan pola
- Pemain mencocokkan pola simbol sesuai petunjuk di berkas atau node.
- Ada batas percobaan, dan kegagalan tidak mengunci permanen. Pemain bisa mencoba lagi setelah jeda singkat.
- Interaksi: sentuh dan seret atau ketuk, area sentuh minimal 48 px.

### 5.4 Bukti dan berkas
- Berkas yang diambil masuk ke daftar bukti.
- Setiap berkas punya judul, isi singkat, dan sumber node.

### 5.5 Cerita tahap 1
- Pembuka: kontak meminta pemain memeriksa satu node yang diduga menyimpan data warga.
- Konflik: data di node itu menunjukkan pola yang tidak wajar, dan ada nama yang tidak dikenal.
- Akhir tahap: satu bukti mengarah ke misi berikutnya. Akhir ini belum final dan bisa diubah.

## 6. Kontrol touchscreen
- Keyboard virtual muncul hanya saat diperlukan, dengan tombol perintah cepat di atasnya.
- Mendukung potret dan lanskap. Tata letak terminal menyesuaikan lebar layar.
- Area sentuh minimal 48 px. Tidak ada aksi yang bergantung pada gerakan cepat.

## 7. Penyimpanan
- Satu file JSON di penyimpanan aplikasi, dengan field versi skema untuk migrasi.
- Auto-simpan setelah selesai misi dan saat aplikasi masuk latar belakang.
- Tahap 1: satu slot. Ekspor dan impor save belum termasuk.

## 8. Arsitektur teknis (usulan)
- `core/`: state murni (node, misi, bukti, progres), tanpa node UI.
- `ui/`: terminal dan peta, memakai Control dan Node2D.
- `puzzle/`: logika puzzle yang bisa diuji tanpa UI.
- `save/`: baca dan tulis JSON, validasi versi.
- `data/`: misi, node, dan teks dialog dalam format JSON.
- `locale/`: teks Bahasa Indonesia dengan kunci, siap untuk Bahasa Inggris.
- `tests/`: unit test untuk core dan puzzle.

## 9. Pertanyaan terbuka (untuk tahap detail)
- Nama tokoh kontak dan latar kota fiktif.
- Gaya visual terminal: warna, font, dan efek.
- Aturan waktu dalam misi: ada batas waktu atau tidak.

## 10. Langkah berikutnya
Rancangan detail sistem (struktur data node, format misi JSON, alur perintah terminal, format save) diajukan untuk ditinjau sebelum coding.

## 11. Ketentuan bahasa (wajib)
1. Bahasa default game adalah Bahasa Indonesia (`id`).
2. Saat pertama kali dibuka, semua UI, terminal, menu, tutorial, dialog, notifikasi, pesan error, puzzle, dan teks sistem tampil dalam Bahasa Indonesia.
3. Bahasa Inggris (`en`) tidak dipakai sebagai fallback utama.
4. Jika terjemahan suatu kunci belum ada untuk bahasa yang dipilih, yang ditampilkan adalah teks Bahasa Indonesia.
5. Struktur lokalisasi disiapkan agar `en` bisa ditambahkan nanti tanpa mengubah kode.
6. Pemain dapat mengganti bahasa secara manual di pengaturan. Tahap 1 hanya menyediakan `id`.


## 12. Revisi terminal (lihat docs/terminal-linux.md)
Sistem perintah karangan (pindai, hubungkan, ambil, buka) digantikan dengan terminal bergaya Linux simulasi. Detail, daftar perintah, dan struktur filesystem ada di docs/terminal-linux.md. Menunggu persetujuan.


## 13. Tools, ekonomi, dan reputasi (lihat docs/tools-dan-ekonomi.md)
Pemain memperoleh tool lewat grup fiktif, Black Market fiktif, atau misi. Ada inventaris, tingkat tool, uang virtual (kredit), reputasi grup, dan sistem unlock. Tool memiliki fungsi nyata di gameplay simulator. Menunggu persetujuan.
