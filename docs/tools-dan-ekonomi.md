# Tools, Ekonomi, dan Reputasi — Revisi Desain (menunggu persetujuan)

Status: REVISI. Melengkapi docs/GDD.md dan docs/terminal-linux.md. Tujuh keputusan terminal di docs/terminal-linux.md bagian 9 belum dijawab dan tidak diubah di sini.
Belum ada coding. Semua aktivitas berjalan di simulator internal Godot. Tidak ada eksekusi sistem, akses jaringan, atau tool sungguhan.

## 1. Prinsip
- Setiap tool punya fungsi nyata di gameplay: mengubah perintah yang tersedia, output, atau cara puzzle bekerja.
- Pemain tidak memiliki semua tool sejak awal.
- Ada tiga jalur memperoleh tool: grup, Black Market, dan misi. Tool tertentu hanya bisa lewat satu jalur.
- Tool tidak menjalankan kode asli. Efeknya didefinisikan sebagai data dan dievaluasi oleh core simulator.

## 2. Tools (contoh awal)
Setiap tool punya id, nama, kategori, tingkat (versi 1–3), dan efek.

| Tool | Kategori | Fungsi di gameplay | Efek per tingkat |
|---|---|---|---|
| Network Scanner | Pemindaian | Perintah `nmap` menampilkan lebih banyak port dan layanan | T1: port umum. T2: port tambahan. T3: layanan dan versi |
| Password Analyzer | Autentikasi | Memberi petunjuk tambahan pada puzzle pola (misal jumlah simbol benar per slot) | T1: satu petunjuk per puzzle. T2: dua. T3: petunjuk tanpa syarat berkas |
| Packet Inspector | Lalu lintas | Perintah baru `inspeksi <host>` (simulasi) menampilkan log transfer node | T1: log terbaru. T2: log lengkap. T3: log terhapus yang tersisa |
| Signal Tracer | Pelacakan | Menampilkan jalur koneksi antar node yang belum terlihat di peta | T1: satu hop. T2: dua hop. T3: seluruh jaringan misi |
| Crypt Decoder | Berkas | Membuka berkas terenkripsi (`cat` memerlukan tool ini untuk berkas bertanda terkunci) | T1: satu jenis enkripsi. T2: dua. T3: tiga |
| Firewall Bypass | Akses | Mengurangi jumlah lapisan puzzle yang harus diselesaikan di satu node | T1: satu lapisan dilewati. T2: sisa lapisan dibuka dengan satu percobaan. T3: node tingkat 3 bisa dimasuki |

Catatan: Firewall Bypass hanya mengubah aturan permainan di dalam simulator. Tidak ada teknik nyata yang digambarkan.

## 3. Status kepemilikan
Setiap entri tool di inventaris pemain punya:
- `id`, `tingkat`, `sumber` (grup, black_market, misi, penemuan, hadiah_kontak).
- `status`: `terkunci` (ditampilkan sebagai kandidat, belum dimiliki), `dimiliki`, `dinonaktifkan` (misal efek sementara dari misi).
- `rusak` tidak diterapkan di tahap ini.

Tool yang `terkunci` tidak muncul di `help`, dan perintah yang bergantung padanya menghasilkan error standar: `bash: inspeksi: perintah tidak ditemukan`. Ini konsisten dengan terminal Linux.

## 4. Versi dan peningkatan tingkat
- Tingkat 1 didapat saat tool dimiliki.
- Tingkat 2 dan 3 dibuka dengan uang virtual dan syarat reputasi grup, atau dengan menyelesaikan misi khusus.
- Peningkatan mengubah efek di tabel bagian 2. Tidak ada tool baru yang muncul dari peningkatan.

## 5. Uang virtual
- Mata uang: kredit (simbol `Kr`). Saldo ditampilkan di prompt atau status bar, dengan pilihan tampilan lewat `help`/`status` (keputusan di bagian 9).
- Sumber: hadiah misi, penjualan berkas bernilai (berkas yang dianalisis), dan imbalan grup.
- Pengeluaran: pembelian di Black Market, peningkatan tingkat tool, dan biaya layanan (misal biaya akses node tertentu, opsional).
- Saldo tidak pernah negatif. Pembelian yang melebihi saldo ditolak dengan pesan dari kunci lokalisasi.

## 6. Reputasi grup
- Nilai reputasi 0–100 untuk satu grup fiktif (dan dapat ditambah grup lain nanti).
- Naik dari: menyelesaikan misi grup, menyerahkan bukti yang diverifikasi, dan menyelesaikan puzzle tanpa petunjuk (bonus kecil).
- Turun dari: membocorkan bukti ke pihak yang salah (keputusan pilihan cerita), dan gagal misi grup berulang.
- Ambang reputasi membuka: tool tingkat 2–3, misi eksklusif, dan item di Black Market.
- Keanggotaan grup: dimulai dari misi pembuka. Jika pemain tidak bergabung, tool grup tetap terkunci, tetapi jalur Black Market dan misi tetap berjalan.

## 7. Black Market (fiktif)
- Toko di dalam game, dibuka dari misi dan dari kontak tertentu. Akses lewat perintah khusus yang disimulasikan seperti forum: `bm` (lihat daftar), `bm beli <id>`, `bm info <id>` (sintaks disetujui nanti di bagian 9).
- Setiap item punya: id, kategori, kelangkaan (umum, langka, sangat langka), harga, dan syarat (reputasi minimal atau flag cerita).
- Stok item bisa habis atau muncul ulang berdasarkan flag misi. Tidak ada waktu nyata yang memaksa pembelian.
- Item Black Market bisa berupa tool, pembaruan tingkat, atau berkas informasi.

## 8. Sistem unlock tools
Setiap tool memiliki satu atau lebih jalur unlock:
- `misi`: flag misi tertentu aktif.
- `grup`: reputasi minimal dan keanggotaan.
- `black_market`: item tersedia dan saldo cukup.
- `penemuan`: berkas khusus ditemukan di node dan dibaca.
- `hadiah_kontak`: kontak memberi tool setelah syarat tertentu.

Unlock dicek saat state berubah, dan hasilnya tercatat sebagai flag atau entri inventaris. Tool yang sudah dimiliki tidak bisa dimiliki dua kali (peningkatan tingkat dilakukan lewat jalur terpisah).

## 9. Integrasi dengan terminal Linux
- `help` menampilkan hanya tool yang dimiliki dan perintah yang aktif.
- Tool menambah perintah atau opsi, misalnya `nmap -sV` (opsi versi layanan) hanya aktif jika Network Scanner tingkat tertentu dimiliki.
- Perintah baru tool tetap mengikuti sintaks Linux (nama, opsi `-x`, argumen), tanpa sistem perintah karangan.
- Inventaris dapat dibuka dengan perintah `tools` (daftar tool dimiliki, tingkat, dan status), sebagai perintah simulasi.
- Berkas yang membutuhkan tool hanya bisa dibuka jika tool dimiliki. Contoh: `cat rahasia.enc` ditolak dengan pesan `Izin ditolak. Dibutuhkan: Crypt Decoder.`
- Setiap perubahan inventaris diproses di `core/` (`inventory.gd`, `economy.gd`, `reputation.gd`, `black_market.gd`), sehingga terminal hanya menampilkan hasilnya.

## 10. Perubahan arsitektur (core)
- `core/tools/tool_defs.gd`: daftar tool sebagai data (id, tingkat, efek).
- `core/tools/inventory.gd`: kepemilikan, status, dan tingkat.
- `core/economy/economy.gd`: saldo kredit, transaksi, dan validasi saldo.
- `core/economy/reputation.gd`: nilai reputasi per grup dan ambang.
- `core/economy/black_market.gd`: daftar item, stok, syarat, dan pembelian.
- `core/unlock/unlock_rules.gd`: evaluasi jalur unlock dari flag dan state.
- `core/shell/command_registry.gd` menerima perintah tambahan dari tool yang dimiliki.
- Save menambah: inventaris (id, tingkat, status), saldo, reputasi per grup, dan stok Black Market yang sudah berubah.

## 11. Pengujian
- Unit test: tingkat tool, validasi saldo, ambang reputasi, dan evaluasi unlock.
- Tes integrasi: tool yang belum dimiliki tidak mengaktifkan perintahnya, pembelian mengurangi saldo, misi menambah tool sesuai data.

## 12. Keputusan yang perlu Anda tinjau (di luar tujuh keputusan terminal)
1. Nilai awal kredit dan harga tiap tingkat tool. Saya usulkan angka kasar, disetujui nanti di data.
2. Reputasi: rentang 0–100 dengan ambang 25, 50, 75, atau ambang lain?
3. Keanggotaan grup wajib untuk misi utama, atau hanya untuk misi eksklusif?
4. Black Market: cukup satu toko, atau ada beberapa penjual dengan reputasi berbeda?
5. Tool dinonaktifkan oleh efek misi (contoh: "terdeteksi") boleh ada di tahap ini, atau ditunda?
6. Tampilan saldo: di prompt, di status bar, atau hanya lewat perintah khusus?

Tujuh keputusan terminal sebelumnya tetap menunggu jawaban Anda. Setelah Anda menjawab keduanya, saya perbarui semua dokumen sekaligus dan mulai coding.
