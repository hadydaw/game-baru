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
    "err.butuh_decoder": "Permission denied. Requires: Crypt Decoder.",
    "err.butuh_decoder_tingkat": "Permission denied. Requires: Crypt Decoder level {tingkat}.",
    "err.tidak_terenkripsi": "file is not encrypted",
    "analyze.tanpa_hash": "No hash can be analyzed in this file.",
    "err.tidak_dikenal_fs": "This environment is not ready yet",
    "info.dibuat": "created",
    "help.judul": "Available commands:",
    "isi.kosong": "(content not available yet)",}

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
    "device": "device [list | detect | rakit [adapter] | hubungkan | putuskan | upgrade antena]: kelola perangkat nirkabel yang dirakit dari komponen.",
    "toko": "toko [beli <id>]: lihat komponen perangkat keras, atau membelinya dengan saldo.",
    "bm": "bm [penjual | info <id> | beli <id>]: lihat penjual Black Market, katalog, detail item, atau membeli tool.",
    "wallet": "wallet: tampilkan saldo kredit dan reputasi per grup.",
    "tools": "tools [search <kata> | info <id> | install <id> | update <id> | list]: tool yang dimiliki dan Tools Repository.",
    "inspeksi": "inspeksi <host>: baca log transfer node yang sudah dipindai nmap. Membutuhkan Packet Inspector.",
    "trace": "trace <host>: tampilkan jalur koneksi dari node. Membutuhkan Signal Tracer.",
    "airodump-ng": "airodump-ng [opsi] <interface>: memindai access point di sekitar lewat interface monitor (wlan0mon). Opsi: -c, -d/--bssid, -t, -N, -u, -w.",
    "airmon-ng": "airmon-ng [start|stop] <interface>: mengaktifkan atau menonaktifkan monitor mode. 'airmon-ng start wlan0' membuat interface wlan0mon.",
    "security": "security: menilai keamanan satu jaringan (security analyze <SSID>) dan memverifikasi aksesnya (security verify).",
    "network-analyzer": "network-analyzer: membaca konfigurasi keamanan satu jaringan dan menilai tingkat risikonya.",
    "password-auditor": "password-auditor: menguji kata sandi jaringan terhadap daftar kandidat umum, dalam simulasi lab.",
    "handshake": "handshake: pertukaran empat pesan saat perangkat terhubung ke jaringan WPA2. Data ini bisa ditangkap untuk diuji.",
    "hasil-handshake": "hasil-handshake: data handshake yang tertangkap belum berisi kata sandi. Kata sandi harus diuji dengan audit.",
    "audit": "audit: menguji kandidat kata sandi satu per satu terhadap data handshake yang sudah tertangkap.",
    "kesimpulan-audit": "kesimpulan-audit: kata sandi lemah cepat ditemukan. Kata sandi panjang dan acak tidak ada dalam daftar umum.",
}

const MAN_EN := {
    "pwd": "pwd: print the current working directory.",
    "ls": "ls [-a] [-l] [path]: list directory contents. -a shows hidden files, -l long format.",
    "cd": "cd [path]: change directory. Without arguments goes to the home directory. cd .. goes up one level.",
    "cat": "cat <file>...: show file contents.",
    "mkdir": "mkdir [-p] <name>: create a directory. -p also creates parent directories.",
    "touch": "touch <file>: create an empty file.",
    "grep": "grep [-i] [-n] [-r] <pattern> <file...>: find matching lines. -i ignore case, -n line numbers, -r recursive.",
    "find": "find <path> [-name <pattern>] [-type f|d]: search for files or directories.",
    "echo": "echo <text>: print text.",
    "clear": "clear: clear the screen. History is kept.",
    "whoami": "whoami: print the user name.",
    "history": "history: show command history.",
    "man": "man <command>: show a short manual page.",
    "help": "help: show the list of commands.",
    "ping": "ping [-c N] <host>: test connectivity to a network node. -c sets the packet count (1-10).",
    "nmap": "nmap [-p port,...] <host>: check ports and services on a network node.",
    "scan": "scan <IP>: identify the device at that IP address: name, IP, and status.",
    "ssh": "ssh [user@]<host>: log in to a remote node if access is available. Type exit to leave.",
    "exit": "exit: leave the SSH session and return to the local terminal.",
    "decode": "decode <file>: open an encrypted file. Requires Crypt Decoder.",
    "analyze": "analyze <file>: check the hash type and salt in a file. Requires Password Analyzer.",
    "device": "device [list | detect | rakit [adapter] | hubungkan | putuskan | upgrade antena]: manage wireless devices built from components.",
    "toko": "toko [beli <id>]: view hardware components, or buy them with your balance.",
    "bm": "bm [penjual | info <id> | beli <id>]: view Black Market sellers, catalog, item details, or buy tools.",
    "wallet": "wallet: show credit balance and reputation per group.",
    "tools": "tools [search <kata> | info <id> | install <id> | update <id> | list]: owned tools and the Tools Repository.",
    "inspeksi": "inspeksi <host>: read the transfer log of a node scanned with nmap. Requires Packet Inspector.",
    "trace": "trace <host>: show the connection path from a node. Requires Signal Tracer.",
    "airodump-ng": "airodump-ng [options] <interface>: scans nearby access points on the monitor interface (wlan0mon). Options: -c, -d/--bssid, -t, -N, -u, -w.",
    "airmon-ng": "airmon-ng [start|stop] <interface>: enables or disables monitor mode. 'airmon-ng start wlan0' creates the wlan0mon interface.",
    "security": "security: analyze one network (security analyze <SSID>) and verify access to it (security verify).",
    "network-analyzer": "network-analyzer: reads one network's security settings and rates its risk level.",
    "password-auditor": "password-auditor: tests a network's password against a list of common candidates, inside the lab simulation.",
    "handshake": "handshake: the four-message exchange when a device connects to a WPA2 network. This data can be captured for testing.",
    "hasil-handshake": "hasil-handshake: captured handshake data does not contain the password. The password must be tested with an audit.",
    "audit": "audit: tests password candidates one by one against captured handshake data.",
    "kesimpulan-audit": "kesimpulan-audit: weak passwords are found quickly. Long, random passwords are not in common lists.",
}

static func man(nama: String) -> String:
    var id := String(MAN.get(nama, ""))
    var en := String(MAN_EN.get(nama, id))
    return Bahasa.dua(id, en)



static func t(kunci: String, parameter: Dictionary = {}) -> String:
    var id := String(ID.get(kunci, kunci))
    var en := String(EN.get(kunci, id))
    for k in parameter:
        id = id.replace("{" + String(k) + "}", str(parameter[k]))
        en = en.replace("{" + String(k) + "}", str(parameter[k]))
    return Bahasa.dua(id, en)
