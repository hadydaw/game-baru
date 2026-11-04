# Rancangan Final: Tools, Ekonomi, Grup, Black Market, dan Integrasi

Status: FINAL, menunggu persetujuan sebelum coding.
Menggantikan docs/tools-dan-ekonomi.md. Keputusan bagian B sudah diterapkan di sini.

## 1. Prinsip realisme
- Setiap tool punya kegunaan, keterbatasan, kebutuhan (prasyarat), dan dampak nyata di gameplay.
- Terminologi cybersecurity dipakai sebagai konsep (port, layanan, paket, log, hash, enkripsi, firewall, kerentanan, forensik). Mekanismenya adalah simulator fiktif, tanpa instruksi nyata.
- Tidak ada perintah yang menyerang sistem nyata. Semua hasil dihitung dari data game.

## 2. Tools (rancangan final)

Setiap tool: tingkat 1–3, harga, prasyarat, kegunaan, keterbatasan, dampak.

### 2.1 Network Scanner
- Kegunaan: `nmap` memindai port dan layanan node.
- T1: port umum (22, 80, 443) dan layanan terdeteksi tanpa versi.
- T2: `nmap -sV` menampilkan versi layanan. Mengungkap kerentanan versi tertentu di catatan vulnerability assessment.
- T3: deteksi firewall dari pola respons; tingkat firewall node ditampilkan.
- Keterbatasan: scan membuat node mencatat aktivitas di log (`/var/log/akses`) kecuali pemain memakai Firewall Bypass atau node tanpa log.
- Dampak: log akses bisa dibaca sebagai bukti forensik.

### 2.2 Password Analyzer
- Kegunaan: memeriksa hash kata sandi yang ditemukan di berkas (`cat`), dan membantu menebak pola puzzle.
- T1: menandai pola yang sering dipakai (sebagai petunjuk, satu per puzzle).
- T2: menunjukkan jumlah simbol benar tanpa posisi.
- T3: petunjuk tanpa syarat berkas.
- Keterbatasan: tidak bisa memecahkan hash yang disalt (berkas bertanda `salt`), hanya memberi petunjuk.

### 2.3 Packet Inspector
- Kegunaan: perintah `inspeksi <host>` membaca log transfer data dari node.
- T1: log terbaru (24 entri terakhir).
- T2: log lengkap, termasuk alamat tujuan tanpa tanda.
- T3: log yang sudah dihapus tetapi masih tersisa di cache.
- Keterbatasan: hanya untuk node yang sudah pernah dipindai `nmap`.
- Dampak: memberi bukti transfer untuk tujuan misi.

### 2.4 Signal Tracer
- Kegunaan: `trace <host>` menampilkan hop koneksi antar node.
- T1: satu hop ke node yang terhubung langsung.
- T2: dua hop.
- T3: seluruh jaringan misi, termasuk node yang belum terlihat.
- Keterbatasan: setiap trace menambah "jejak" di node tertentu (mekanik tahap berikutnya, ditunda).

### 2.5 Crypt Decoder
- Kegunaan: membuka berkas terenkripsi (`cat` mengembalikan pesan Dibutuhkan Crypt Decoder tanpa tool).
- T1: enkripsi tipe A (kunci statis).
- T2: tipe A dan B (kunci dari berkas lain di node).
- T3: tipe A, B, dan C (kunci dari petunjuk puzzle).
- Keterbatasan: satu berkas per perintah `decode <berkas>`.

### 2.6 Firewall Bypass
- Kegunaan: mengurangi lapisan puzzle yang harus diselesaikan di satu node. Ini aturan permainan, bukan teknik nyata.
- T1: satu lapisan dilewati pada node tingkat 1–2.
- T2: lapisan sisa dibuka dengan satu percobaan.
- T3: node tingkat 3 bisa dimasuki.
- Keterbatasan: setiap penggunaan meninggalkan entri di log node (sama seperti scan). Tidak bisa dipakai di node dengan log dinonaktifkan.
- Dampak: mempercepat misi, tetapi meninggalkan bukti.

### 2.7 Dampak ke simulasi
Setiap tool memodifikasi aturan simulator (hasil `nmap`, isi `inspeksi`, lapisan puzzle), bukan menjalankan kode. Tool dinyatakan sebagai data di `core/tools/tool_defs.gd`.

## 3. Perintah dari tools
- Tool aktif menambah perintah atau opsi: `inspeksi`, `trace`, `decode`, `analyze`, dan opsi `nmap -sV`.
- Perintah tidak aktif tanpa tool menghasilkan `bash: <perintah>: perintah tidak ditemukan`.
- `help` hanya menampilkan perintah yang aktif.

## 4. Ekonomi
- Saldo awal: 500 Kr.
- Harga tools:
  - Tingkat 1: 200–500 Kr.
  - Tingkat 2: 600–1.200 Kr.
  - Tingkat 3: 1.500–3.000 Kr.
- Sumber uang: hadiah misi, penjualan berkas yang sudah dianalisis (berkas bernilai di Black Market), imbalan grup.
- Pengeluaran: pembelian Black Market, peningkatan tingkat, biaya akses node tertentu.
- Saldo tidak pernah negatif. Pembelian yang melebihi saldo ditolak.
- Tampil di status bar, dan detail lewat perintah `wallet`.

## 5. Grup dan reputasi
- Grup fiktif awal: satu grup (nama ditetapkan di data), dengan dua grup tambahan di tahap berikutnya.
- Reputasi 0–100.
- Ambang:
  - 25: akses anggota (konten eksklusif tingkat dasar).
  - 50: akses menengah (tool tingkat 2, misi menengah).
  - 75: akses elite (tool tingkat 3, misi elite).
- Naik: menyelesaikan misi grup, menyerahkan bukti yang diverifikasi, puzzle tanpa petunjuk (bonus kecil).
- Turun: membocorkan bukti (keputusan cerita), gagal misi grup berulang.
- Keanggotaan tidak wajib untuk cerita utama. Keanggotaan membuka konten eksklusif, dan bergabung dimulai dari misi pembuka grup.

## 6. Black Market (beberapa penjual)
- Penjual punya spesialisasi, stok, dan ambang reputasi yang berbeda.
  - Penjual A (umum): tools tingkat 1, harga dasar, stok banyak.
  - Penjual B (spesialis berkas): Crypt Decoder dan Password Analyzer, stok terbatas.
  - Penjual C (jaringan): Signal Tracer dan Packet Inspector, membutuhkan reputasi 50.
  - Penjual D (elite): tools tingkat 3, reputasi 75, stok sangat terbatas.
- Kelangkaan: umum, langka, sangat langka (memengaruhi stok awal dan pemulihan stok).
- Perintah di terminal: `bm` (daftar penjual), `bm <penjual>` (katalog), `bm beli <id>`, `bm info <id>`. Sintaks ini mengikuti pola perintah Linux.
- Stok pulih berdasarkan flag misi, bukan waktu nyata.

## 7. Unlock tools
Jalur unlock per tool: misi (flag), grup (reputasi dan keanggotaan), Black Market (item tersedia dan saldo cukup), penemuan (berkas khusus dibaca di node), hadiah kontak (syarat kontak terpenuhi).
- Tool yang sudah dimiliki tidak bisa dimiliki dua kali. Peningkatan tingkat lewat jalur terpisah.
- Unlock dicek saat state berubah.

## 8. Integrasi dengan misi dan puzzle
- Misi menyediakan tujuan yang bisa dicek dari state: berkas dibaca, host dipindai, transfer dilacak, lapisan terbuka, tool digunakan.
- Puzzle pencocokan pola tetap dipakai sebagai lapisan keamanan. Tool memberi petunjuk (Password Analyzer) atau mengurangi lapisan (Firewall Bypass).
- Berkas terenkripsi memerlukan Crypt Decoder. Berkas bukti penting bisa dimiliki lewat Black Market, berkas penemuan, atau hadiah kontak.
- Grup memberi misi eksklusif yang menghasilkan tool tingkat lebih tinggi dan reputasi.

## 9. Struktur core tambahan
- `core/tools/tool_defs.gd`: definisi tool sebagai data.
- `core/tools/inventory.gd`: kepemilikan, tingkat, status.
- `core/economy/economy.gd`: saldo, transaksi, validasi.
- `core/economy/reputation.gd`: reputasi per grup dan ambang.
- `core/economy/black_market.gd`: penjual, katalog, stok, pembelian.
- `core/unlock/unlock_rules.gd`: evaluasi jalur unlock.
- `core/shell/command_registry.gd`: menerima perintah tambahan dari tool yang dimiliki.

## 10. Pengujian
- Unit: tingkat tool, validasi saldo, ambang reputasi, evaluasi unlock, izin file.
- Integrasi: perintah tool tidak aktif tanpa kepemilikan, pembelian mengurangi saldo, misi menambah tool sesuai data.
- Keamanan: tes memastikan tidak ada pemanggilan OS atau jaringan di `core/`.

## 11. Keputusan yang masih perlu Anda tinjau
Tidak ada. Semua keputusan sudah diterapkan sesuai jawaban Anda. Setelah Anda menyetujui dua dokumen final ini, saya mulai coding tahap A (terminal dasar dan filesystem), lalu tahap B, lalu tools dan ekonomi.
