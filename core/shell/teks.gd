class_name Teks
extends RefCounted

# Teks Bahasa Indonesia untuk pesan terminal. Nanti dipindah ke data/locale/id.json
# saat sistem lokalisasi dipasang di Game; sampai saat itu tabel ini sumbernya.

const ID := {
    "err.tidak_ada": "Tidak ada berkas atau direktori",
    "bash.sintaks": "sintaks tidak lengkap dekat '>'",
    "bash.redirect_banyak": "terlalu banyak tujuan redirect",
    "bash.kosong": "perintah kosong sebelum '>'",
    "err.izin": "Izin ditolak",
    "err.direktori": "Itu adalah direktori",
    "err.bukan_direktori": "Bukan direktori",
    "err.tidak_ditemukan": "perintah tidak ditemukan",
    "err.butuh_argumen": "argumen diperlukan",
    "err.sudah_ada": "Berkas sudah ada",
    "err.hanya_home": "Izin ditolak: hanya bisa membuat di direktori pribadi",
    "err.tidak_ada_pola": "pola tidak ditemukan",
    "err.butuh_decoder": "Izin ditolak. Dibutuhkan: Crypt Decoder.",
    "err.butuh_decoder_tingkat": "Izin ditolak. Dibutuhkan: Crypt Decoder tingkat {tingkat}.",
    "err.tidak_terenkripsi": "berkas tidak terenkripsi",
    "err.satu_berkas": "hanya satu berkas per perintah",
    "analyze.tanpa_hash": "Tidak ada hash yang dapat dianalisis di berkas ini.",
    "err.opsi": "opsi tidak dikenal",
    "err.tidak_ada_induk": "Direktori induk tidak ada",
    "err.tidak_dikenal_fs": "Lingkungan ini belum siap",
    "info.dibuat": "dibuat",
    "help.judul": "Perintah yang tersedia:",
    "man.tidak_ada": "Tidak ada entri manual untuk",
    "isi.kosong": "(isi belum tersedia)",
}

# Terjemahan English untuk pesan bergaya Linux. Pesan khusus permainan tetap Bahasa Indonesia.
const EN := {
    "err.tidak_ada": "No such file or directory",
    "err.izin": "Permission denied",
    "err.direktori": "Is a directory",
    "err.bukan_direktori": "Not a directory",
    "err.tidak_ditemukan": "command not found",
    "err.butuh_argumen": "missing operand",
    "err.sudah_ada": "File exists",
    "err.hanya_home": "Permission denied: can only create inside the home directory",
    "err.tidak_ada_pola": "pattern not found",
    "err.satu_berkas": "only one file per command",
    "err.opsi": "invalid option",
    "err.tidak_ada_induk": "No such file or directory",
    "man.tidak_ada": "No manual entry for",
    "bash.sintaks": "syntax error near unexpected token '>'",
    "bash.redirect_banyak": "ambiguous redirect",
    "bash.kosong": "syntax error: missing command before '>'",
}

const MAN := {
    "pwd": "pwd: cetak direktori kerja saat ini.",
    "ls": "ls [-a] [-l] [path]: daftar isi direktori. -a menampilkan berkas tersembunyi, -l format rinci.",
    "cd": "cd [path]: pindah direktori. Tanpa argumen ke direktori pribadi. cd .. naik satu tingkat.",
    "cat": "cat <berkas>...: tampilkan isi berkas.",
    "mkdir": "mkdir [-p] <nama>: buat direktori. -p membuat direktori induk sekaligus.",
    "touch": "touch <berkas>: buat berkas kosong.",
    "grep": "grep [-i] [-n] [-r] <pola> <berkas...>: cari baris yang cocok. -i abaikan huruf besar kecil, -n nomor baris, -r rekursif.",
    "find": "find <path> [-name <pola>] [-type f|d]: cari berkas atau direktori.",
    "echo": "echo <teks>: cetak teks.",
    "clear": "clear: bersihkan layar. Riwayat tetap.",
    "whoami": "whoami: cetak nama pengguna.",
    "history": "history: tampilkan riwayat perintah.",
    "man": "man <perintah>: tampilkan halaman manual singkat.",
    "help": "help: tampilkan daftar perintah.",
    "ping": "ping [-c N] <host>: uji konektivitas ke node jaringan. -c menentukan jumlah paket (1-10).",
    "nmap": "nmap [-p port,...] <host>: periksa port dan layanan pada node jaringan.",
    "scan": "scan <IP>: identifikasi perangkat di alamat IP tersebut: nama, IP, dan status.",
    "ssh": "ssh [user@]<host>: masuk ke node jarak jauh jika akses tersedia. Ketik exit untuk keluar.",
    "exit": "exit: keluar dari sesi SSH dan kembali ke terminal lokal.",
    "decode": "decode <berkas>: buka berkas terenkripsi. Membutuhkan Crypt Decoder.",
    "analyze": "analyze <berkas>: periksa jenis hash dan salt pada berkas. Membutuhkan Password Analyzer.",
    "bm": "bm [penjual | info <id> | beli <id>]: lihat penjual Black Market, katalog, detail item, atau membeli tool.",
    "wallet": "wallet: tampilkan saldo kredit dan reputasi per grup.",
    "tools": "tools: tampilkan tool yang dimiliki, tingkat, dan sumbernya.",
    "inspeksi": "inspeksi <host>: baca log transfer node yang sudah dipindai nmap. Membutuhkan Packet Inspector.",
    "trace": "trace <host>: tampilkan jalur koneksi dari node. Membutuhkan Signal Tracer.",
}

static func t(kunci: String, parameter: Dictionary = {}) -> String:
    var tabel := EN if Bahasa.kode == "en" and EN.has(kunci) else ID
    var teks := String(tabel.get(kunci, kunci))
    for k in parameter:
        teks = teks.replace("{" + String(k) + "}", str(parameter[k]))
    return teks
