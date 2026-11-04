# Rancangan Final: Terminal Linux, Filesystem, dan Permission

Status: FINAL, menunggu persetujuan sebelum coding.
Menggantikan docs/terminal-linux.md (keputusan di bagian A sudah diterapkan di sini).

## 1. Prinsip
- Sintaks mengikuti bash: nama perintah, opsi `-x`, opsi gabungan `-la`, argumen, path `/ . .. ~`, kutip tunggal dan ganda.
- Semua eksekusi di simulator internal Godot. Tidak ada `OS.execute`, akses terminal Android, socket, atau jaringan eksternal. Tes memeriksa ini di folder `core/`.
- Format error: `bash: <perintah>: <pesan>`, pesan dalam Bahasa Indonesia. Contoh: `bash: foo: perintah tidak ditemukan`.
- Prompt: `operator@jtn:~$`. Bagian `~` berubah mengikuti direktori kerja (`~/dokumen`, `/var/log`).

## 2. Perintah

### 2.1 Tahap A (dasar)
| Perintah | Perilaku |
|---|---|
| `help` | Daftar perintah aktif (hanya yang tersedia untuk pemain saat ini) |
| `pwd` | Cetak direktori kerja |
| `ls [-a] [-l] [path]` | Daftar isi. `-a` menampilkan berkas `.`. `-l` menampilkan izin, pemilik, grup, ukuran |
| `cd [path]` | Pindah direktori. Tanpa argumen ke `~`. `cd ..` naik satu tingkat, `cd /` ke akar |
| `cat <berkas>...` | Tampilkan isi berkas, bisa beberapa berkas. Ditolak jika tanpa izin baca |
| `mkdir [-p] <nama>` | Buat direktori. `-p` membuat induk sekaligus. Hanya di filesystem pemain |
| `touch <berkas>` | Buat berkas kosong. Hanya di filesystem pemain |
| `clear` | Bersihkan layar. Riwayat tetap |
| `whoami` | Cetak `operator` |
| `history` | Riwayat perintah bernomor |
| `echo <teks>` | Cetak teks |
| `man <perintah>` | Halaman manual singkat dalam Bahasa Indonesia |

### 2.2 Tahap A (pencarian, dikerjakan sejak awal)
| Perintah | Perilaku |
|---|---|
| `grep [-i] [-n] [-r] <pola> <berkas...>` | Cari baris yang cocok. `-i` abaikan huruf besar kecil, `-n` nomor baris, `-r` rekursif di direktori |
| `find <path> [-name <pola>] [-type f\|d]` | Cari berkas dan direktori. Hanya di dalam filesystem yang sedang aktif |

### 2.3 Tahap B (simulasi keamanan)
| Perintah | Perilaku |
|---|---|
| `ping <host>` | Respons dari node yang sudah dikenal. Waktu respons dari data node |
| `nmap [-sV] <host>` | Pemindaian port dan layanan dari data node. `-sV` menampilkan versi, hanya jika Network Scanner tingkat 2 ke atas |
| `ssh <user>@<host>` | Masuk ke node. Node terkunci memunculkan layar puzzle (lihat bagian 6) |
| `exit` | Keluar sesi ssh ke shell pemain |

### 2.4 Perintah dari tools (bagian 3 di docs/final-tools-ekonomi.md)
Perintah tambahan atau opsi yang hanya aktif jika tool dimiliki, misalnya `inspeksi <host>` dan `wallet`. Tidak aktif tanpa tool.

### 2.5 Ditunda
- `sudo`: menunggu sistem permission penuh.
- Pipa `|`, redirect `>`, `&&`: ditunda ke tahap berikutnya.

## 3. Struktur filesystem virtual
- Setiap host (pemain dan setiap node) punya pohon filesystem sendiri di data misi.
- Pemain: `/home/operator` (home), `/var/log`, `/tmp`. Struktur awal diberikan pada setiap misi.
- Node: filesystem sesuai peran node, misalnya `/var/log/transfer`, `/etc/`, `/srv/arsip`.

### 3.1 Format data (contoh)
```json
{
  "/": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
    "home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
      "operator": {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {
        ".catatan": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi_key": "fs.catatan.isi", "ukuran": 214}
      }}
    }}
  }}
}
```

### 3.2 Aturan
- Berkas berawalan `.` tersembunyi dari `ls` tanpa `-a`, dan muncul di `find` dan `grep -r`.
- Izin `rwx` dicek untuk pemilik, grup, dan lainnya. Pemain adalah `operator`, anggota grup `operator`.
- `root` bisa dibaca hanya jika izin mengizinkan atau pemain memiliki akses dari misi (flag). Tidak ada `sudo` di tahap ini.
- `cat` dan `grep` memerlukan `r`. `cd` memerlukan `x` pada direktori. `mkdir` dan `touch` memerlukan `w` pada induk.
- Pesan penolakan: `bash: cat: /etc/rahasia: Izin ditolak`.
- Berkas terenkripsi (`isi_key` tidak tersedia tanpa tool): `bash: cat: arsip.enc: Dibutuhkan Crypt Decoder`. Bentuk pesan ini bagian dari realisme permission.
- Isi berkas memakai `isi_key` dari lokalisasi Bahasa Indonesia.

### 3.3 Penyimpanan
- Save hanya mencatat perubahan terhadap data awal: direktori dan berkas buatan pemain, berkas yang dibaca, dan perubahan izin (dari misi).
- Filesystem host node disimpan sebagai daftar perubahan, bukan pohon penuh.

## 4. Lokalisasi
- Nama perintah, opsi, dan format keluaran Linux tetap.
- Pesan error, `help`, `man`, dan keterangan memakai kunci `id`.
- Isi berkas memakai `isi_key`.

## 5. Arsitektur core (murni)
- `core/shell/parser.gd`: tokenisasi, kutip, opsi gabungan, argumen. Mengembalikan `{nama, opsi, argumen}`.
- `core/shell/command_registry.gd`: daftar perintah dengan handler, sintaks, dan bantuan. Perintah dari tool didaftarkan saat tool dimiliki.
- `core/shell/shell_session.gd`: direktori kerja, riwayat, host aktif, dan keluaran bertipe.
- `core/fs/vfs.gd`: resolve path, list, baca, buat, cek izin.
- `core/fs/permissions.gd`: evaluasi izin `rwx` terhadap pengguna dan grup.
- `core/net/sim_network.gd`: ping, nmap, ssh dari data node.
- `core/puzzle/pattern_puzzle.gd`: sesuai rancangan sebelumnya.
- `core/game_state.gd`: misi, lapisan, flag, dan perubahan filesystem.

## 6. Integrasi puzzle
- `ssh` ke node terkunci menampilkan prompt `Password:`. Layar puzzle pencocokan pola (4 slot, 6 simbol, 6 percobaan per ronde, tanpa penguncian waktu) terbuka.
- Berhasil: sesi ssh terbuka, lapisan tercatat, flag tercatat.
- Petunjuk: tersedia setelah 3 kegagalan dan hanya jika berkas sumber sudah dibaca (lewat `cat` atau `grep`).

## 7. Peta jaringan
- Tetap sebagai antarmuka sekunder. Menampilkan node dan status.
- Ketuk node mengisi `ssh operator@<host>` di terminal. Tidak menggantikan terminal.
