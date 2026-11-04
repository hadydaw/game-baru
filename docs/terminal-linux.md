# Terminal Linux Simulasi — Revisi Desain (menunggu persetujuan)

Status: REVISI. Menggantikan sistem perintah karangan (pindai, hubungkan, ambil, buka) di GDD dan rancangan teknis.
Belum ada coding. Tidak ada perubahan pada konfigurasi Android atau workflow GitHub.

## 1. Prinsip
- Sintaks perintah mengikuti standar Linux (bash): nama perintah, opsi dengan tanda `-`, argumen dipisah spasi, path dengan `/`, `.`, `..`, `~`.
- Semua eksekusi berjalan di simulator internal Godot. Tidak ada `OS.execute`, tidak ada akses terminal Android, tidak ada socket atau koneksi jaringan.
- Output perintah ditulis sebagai data (teks yang sudah disiapkan atau dihitung dari state game), bukan hasil proses sungguhan.
- Pesan dan keterangan dalam Bahasa Indonesia. Nama perintah, opsi, dan format keluaran mengikuti Linux.
- Standar error Linux dipertahankan dalam bentuk: `bash: <perintah>: <pesan>`. Pesan dalam Bahasa Indonesia, contoh: `bash: foo: perintah tidak ditemukan`.

## 2. Daftar perintah

### 2.1 Tahap A (dasar, dikerjakan lebih dulu)
| Perintah | Perilaku |
|---|---|
| `help` | Daftar perintah yang tersedia di konteks saat ini |
| `pwd` | Cetak direktori kerja |
| `ls` | Daftar isi direktori, tanpa berkas tersembunyi |
| `ls -la` | Daftar lengkap termasuk berkas berawalan `.` (tersembunyi) |
| `cd <path>` | Pindah direktori |
| `cd ..` | Kembali ke induk (wajib berfungsi, termasuk dari `/`) |
| `cd /` | Ke akar |
| `cd ~` | Ke direktori home pemain |
| `cat <berkas>` | Tampilkan isi berkas (ditolak jika direktori atau tidak punya izin baca) |
| `mkdir <nama>` | Buat direktori di direktori kerja (hanya di filesystem pemain) |
| `clear` | Bersihkan layar (riwayat tetap) |
| `whoami` | Cetak nama pengguna simulasi |
| `history` | Cetak riwayat perintah bernomor |

Catatan: `ls -la` dan `cat` dipakai untuk menemukan berkas tersembunyi. Berkas tersembunyi tidak muncul di `ls` biasa, ini sesuai Linux.

### 2.2 Tahap B (keamanan, simulasi)
| Perintah | Perilaku |
|---|---|
| `ping <host>` | Simulasi respons dari node yang dikenal di peta. Waktu respons dari data node |
| `nmap <host>` | Simulasi pemindaian: daftar port terbuka dan layanan dari data node. Hanya node yang dikenal |
| `ssh <user>@<host>` | Masuk ke shell simulasi node. Jika node terkunci, memulai puzzle lapisan (lihat bagian 5) |
| `exit` | Keluar dari sesi ssh, kembali ke shell pemain |

Host yang tidak dikenal menghasilkan keluaran dari data, misalnya: `ping: tidak dapat menemukan host "xyz"`.

### 2.3 Di luar cakupan revisi ini
- Program, skrip, atau pipa (`|`, `>`, `&&`). Hanya dipertimbangkan untuk tahap lanjut.
- `sudo`, `chmod`, `rm`, `man`, `grep`, `find`. Keputusan di bagian 9.

## 3. Lingkungan terminal (tampilan dan input)
- Background gelap, font monospace, prompt bergaya Linux: `pemain@kali:~$` (nama pengguna dan host dapat diatur dari data misi).
- Riwayat perintah dengan panah atas dan bawah.
- Sorot sintaks: nama perintah dan argumen dengan warna berbeda, error merah, path biru.
- Tab untuk melengkapi nama berkas dan direktori.
- Keyboard virtual Android dengan baris tambahan: `/ - _ | . ~ Tab Ctrl` dan spasi. Tombol panah tersedia.
- Input manual tetap didukung lewat keyboard fisik atau virtual.

## 4. Filesystem virtual

### 4.1 Struktur data
Filesystem disimpan sebagai pohon data di file misi (`data/misi/misi_01.json`), dengan id stabil per direktori dan berkas.

Contoh:
```json
{
  "/": { "tipe": "dir", "isi": {
    "home": { "tipe": "dir", "isi": {
      "pemain": { "tipe": "dir", "isi": {
        ".catatan": { "tipe": "file", "isi_key": "fs.catatan.isi", "izin": "r" },
        "dokumen": { "tipe": "dir", "isi": {} }
      }}
    }}
  }}
}
```

### 4.2 Aturan
- Berkas berawalan `.` disembunyikan dari `ls` tanpa `-a`.
- Direktori dan berkas punya izin sederhana: `r` (bisa dibaca) atau tidak. `cat` pada berkas tanpa `r` menghasilkan `Izin ditolak`.
- Isi berkas memakai kunci lokalisasi (`isi_key`), jadi tetap Bahasa Indonesia.
- Path dibaca dengan aturan Linux: relatif terhadap direktori kerja, absolut dimulai `/`, `..` naik satu tingkat, `.` direktori sekarang.
- Setiap node jaringan punya filesystem sendiri. Filesystem pemain (`/home/pemain`) terpisah dan tetap di tempat pemain. `ssh` berpindah ke filesystem node.
- `mkdir` dan perubahan lain hanya tersimpan di filesystem pemain, dan ikut disimpan ke save.

### 4.3 Penyimpanan perubahan
- Save menyimpan daftar perubahan terhadap data awal (direktori yang dibuat, berkas yang dibaca), bukan seluruh pohon, agar save kecil dan migrasi mudah.

## 5. Integrasi puzzle dan misi
- Node yang terkunci tidak bisa dimasuki dengan `ssh` sebelum lapisan keamanannya selesai.
- Saat `ssh` ke node terkunci, muncul prompt `Password:`. Pemain diarahkan ke layar puzzle pencocokan pola (4 slot, 6 simbol) yang sudah disetujui. Keberhasilan puzzle membuka sesi ssh.
- Puzzle dan petunjuk tetap sesuai revisi sebelumnya: tanpa penguncian waktu, petunjuk setelah 3 kegagalan, dan hanya jika berkas sumbernya sudah dibaca.
- Tujuan misi dicek dari state: berkas tertentu sudah dibaca, direktori tertentu sudah dikunjungi, perintah tertentu sudah dijalankan (misalnya `nmap` pada node target), dan lapisan sudah terbuka.
- Peta jaringan tetap ada sebagai tampilan visual. Node di peta menampilkan status, dan ketuk node mengisi `ssh <user>@<host>` di terminal. Peta tidak lagi menjadi cara utama bermain.

## 6. Arsitektur yang berubah

### 6.1 Core (murni, tanpa UI, tanpa OS)
- `core/shell/parser.gd`: tokenisasi dengan kutip tunggal dan ganda, opsi `-x` dan `-xy` digabung, argumen, dan spasi berlebih. Mengembalikan `{nama, opsi, argumen}`.
- `core/shell/command_registry.gd`: daftar perintah dengan handler dan metadata (nama, sintaks, bantuan). Perintah baru cukup didaftarkan tanpa mengubah parser.
- `core/shell/shell_session.gd`: direktori kerja, riwayat, host aktif (pemain atau node), dan hasil perintah sebagai daftar baris bertipe.
- `core/fs/vfs.gd`: filesystem virtual (resolve path, list, baca, buat direktori). Tidak tahu tentang UI.
- `core/net/sim_network.gd`: simulasi host (ping, nmap, ssh) dari data node. Tidak membuka socket.
- `core/puzzle/pattern_puzzle.gd`: tetap seperti rancangan sebelumnya.
- `core/game_state.gd`: state misi, lapisan, flag, dan perubahan filesystem.

### 6.2 Autoload dan UI
- `Game`: menghubungkan `ShellSession` dan `GameState`. Input dari UI dikirim ke `Game.jalankan(baris)`.
- `Locale`: tetap seperti sebelumnya.
- UI terminal: `ui/terminal_view.gd` menampilkan keluaran, prompt, riwayat, sorot sintaks, dan baris tombol karakter khusus.
- UI puzzle tetap sebagai layar terpisah yang dipanggil dari `ssh`.

### 6.3 Alur data
```
keyboard virtual / fisik
   ▼
terminal_view ──► Game.jalankan(baris)
                      ▼
                  parser ──► command_registry ──► shell_session
                                                    ├──► vfs (berkas dan direktori)
                                                    ├──► sim_network (ping, nmap, ssh)
                                                    └──► game_state (lapisan, tujuan, flag)
                      ▼
                  keluaran (baris bertipe) ──► terminal_view
```

## 7. Lokalisasi
- Nama perintah, opsi, dan format keluaran Linux tetap apa adanya.
- Pesan dan keterangan (termasuk `help` dan pesan error) memakai kunci lokalisasi `id`.
- Isi berkas memakai `isi_key`.

## 8. Pengujian
- Parser, VFS (termasuk `cd ..` dari `/` dan dari direktori dalam), dan command registry diuji unit (GUT).
- Tes memastikan tidak ada pemanggilan `OS.execute` atau API jaringan di folder `core/`.
- Tes alur misi: ssh ke node terkunci memulai puzzle, puzzle berhasil membuka sesi, tujuan misi tercatat.

## 9. Keputusan yang perlu Anda tinjau
1. Format error: `bash: <perintah>: <pesan>` dengan pesan Bahasa Indonesia. Setuju, atau pesan dibuat sepenuhnya berbahasa Indonesia tanpa prefiks `bash:`?
2. Prompt `pemain@kali:~$`: nama "kali" menyebut merek nyata. Mau diganti nama fiktif, misalnya `pemain@arsip:~$`?
3. Perintah tahap B (`ping`, `nmap`, `ssh`): setuju untuk versi simulasi seperti di bagian 2.2?
4. Tahap A saja dulu untuk implementasi pertama, atau tahap A dan B sekaligus?
5. Perintah tambahan di luar daftar (`grep`, `find`, `man`, `sudo`): masuk tahap berikutnya atau tidak?
6. Tombol keyboard virtual: baris `/ - _ | . ~ Tab Ctrl` sudah sesuai?
7. Peta jaringan: tetap sebagai visual sekunder, atau dihapus sepenuhnya?

Setelah Anda menjawab, saya perbarui GDD dan rancangan teknis sesuai jawaban, lalu mulai coding. Belum ada coding sampai revisi ini disetujui.
