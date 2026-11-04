class_name Teks
extends RefCounted

# Teks Bahasa Indonesia untuk pesan terminal. Nanti dipindah ke data/locale/id.json
# saat sistem lokalisasi dipasang di Game; sampai saat itu tabel ini sumbernya.

const ID := {
    "err.tidak_ada": "Tidak ada berkas atau direktori",
    "err.izin": "Izin ditolak",
    "err.direktori": "Itu adalah direktori",
    "err.bukan_direktori": "Bukan direktori",
    "err.tidak_ditemukan": "perintah tidak ditemukan",
    "err.butuh_argumen": "argumen diperlukan",
    "err.sudah_ada": "Berkas sudah ada",
    "err.hanya_home": "Izin ditolak: hanya bisa membuat di direktori pribadi",
    "err.tidak_ada_pola": "pola tidak ditemukan",
    "err.opsi": "opsi tidak dikenal",
    "err.tidak_ada_induk": "Direktori induk tidak ada",
    "err.tidak_dikenal_fs": "Lingkungan ini belum siap",
    "info.dibuat": "dibuat",
    "help.judul": "Perintah yang tersedia:",
    "man.tidak_ada": "Tidak ada entri manual untuk",
    "isi.kosong": "(isi belum tersedia)",
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
}

static func t(kunci: String, parameter: Dictionary = {}) -> String:
    var teks := String(ID.get(kunci, kunci))
    for k in parameter:
        teks = teks.replace("{" + String(k) + "}", str(parameter[k]))
    return teks
