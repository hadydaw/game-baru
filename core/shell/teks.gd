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
    "lsusb": "lsusb: daftar perangkat USB yang tersambung ke sistem. Adapter nirkabel ditampilkan dengan ID vendor:produk-nya.",
    "aircrack-ng": "aircrack-ng [-w <kamus>] <target>: uji kunci WPA dari data handshake yang sudah ditangkap dengan daftar kata. Wajib -w. Target harus punya handshake.",
    "hashcat": "hashcat -m 2500 <target> <kamus>: pulihkan kata sandi WPA (mode 2500) dengan daftar kata. Mode hash wajib diisi.",
    "john": "john --wordlist=<kamus> <target>: uji daftar kata pada hash kata sandi. Hasil yang cocok ditampilkan bersama nama target.",
    "wireshark": "wireshark [-r berkas | -i antarmuka]: buka penganalisis paket grafis. -r membuka berkas .simcap atau contoh lab; -i memulai capture simulasi.",
    "tshark": "tshark [-r berkas | -i antarmuka] [-Y filter] [-c N] [-q] [-z io,phs|conv,ip]: analisis paket di Terminal. -D menampilkan antarmuka.",
    "network-analyzer": "network-analyzer <analyze|verify|report> ...: nilai keamanan satu jaringan (analyze), verifikasi kata sandi (verify), atau tulis laporan (report).",
    "password-auditor": "password-auditor <auth|run> <ssid>: tangkap data autentikasi (auth) lalu uji kata sandi terhadap kamus (run).",
    "apt": "apt [-y] <perintah> [paket...]: kelola paket. Perintah: install, remove, purge, autoremove, update, upgrade, list, search, show. -y menjawab ya otomatis.",
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
    "nmap": "nmap [-p port,...] [-sn] [-oN berkas] <host|subnet>: periksa port, layanan, atau host aktif pada subnet.",
    "ip": "ip addr | ip route: tampilkan alamat dan rute jaringan perangkatmu.",
    "netdiscover": "netdiscover -r <subnet/24>: temukan perangkat di subnet lewat ARP.",
    "ssh": "ssh [user@]<host>: masuk ke node jarak jauh jika akses tersedia. Ketik exit untuk keluar.",
    "exit": "exit: keluar dari sesi SSH dan kembali ke terminal lokal.",
    "airodump-ng": "airodump-ng [opsi] <interface>: memindai access point di sekitar lewat interface monitor (wlan0mon). Opsi: -c, -d/--bssid, -t, -N, -u, -w.",
    "airmon-ng": "airmon-ng [start|stop] <interface>: mengaktifkan atau menonaktifkan monitor mode. 'airmon-ng start wlan0' membuat interface wlan0mon.",
}

const MAN_EN := {
    "lsusb": "lsusb: list USB devices connected to the system. Wireless adapters are shown with their vendor:product ID.",
    "aircrack-ng": "aircrack-ng [-w <wordlist>] <target>: test WPA keys from captured handshake data against a wordlist. -w is required. The target must have a handshake.",
    "hashcat": "hashcat -m 2500 <target> <wordlist>: recover WPA passwords (mode 2500) with a wordlist. The hash mode is required.",
    "john": "john --wordlist=<wordlist> <target>: test a wordlist against a password hash. A match is shown with the target name.",
    "wireshark": "wireshark [-r file | -i interface]: open the graphical packet analyzer. -r opens a .simcap file or lab sample; -i starts a simulated capture.",
    "tshark": "tshark [-r file | -i interface] [-Y filter] [-c N] [-q] [-z io,phs|conv,ip]: packet analysis in the Terminal. -D lists interfaces.",
    "network-analyzer": "network-analyzer <analyze|verify|report> ...: assess one network's security (analyze), verify a password (verify), or write a report (report).",
    "password-auditor": "password-auditor <auth|run> <ssid>: capture authentication data (auth), then test the password against a wordlist (run).",
    "apt": "apt [-y] <command> [package...]: manage packages. Commands: install, remove, purge, autoremove, update, upgrade, list, search, show. -y assumes yes.",
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
    "nmap": "nmap [-p port,...] [-sn] [-oN file] <host|subnet>: check ports, services, or live hosts on a subnet.",
    "ip": "ip addr | ip route: show your device's network addresses and routes.",
    "netdiscover": "netdiscover -r <subnet/24>: find devices on a subnet through ARP.",
    "ssh": "ssh [user@]<host>: log in to a remote node if access is available. Type exit to leave.",
    "exit": "exit: leave the SSH session and return to the local terminal.",
    "airodump-ng": "airodump-ng [options] <interface>: scans nearby access points on the monitor interface (wlan0mon). Options: -c, -d/--bssid, -t, -N, -u, -w.",
    "airmon-ng": "airmon-ng [start|stop] <interface>: enables or disables monitor mode. 'airmon-ng start wlan0' creates the wlan0mon interface.",
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
