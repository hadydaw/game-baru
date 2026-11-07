class_name ShellCommands
extends RefCounted

# Dispatch perintah dan handler tahap A (navigasi dan berkas).
# Setiap handler menerima sesi dan hasil parse, lalu mengembalikan Array of {tipe, teks}.

# Perintah lama dari versi game sebelum Terminal dibuat seperti Kali. Sementara, nama lama tidak
# dianggap "tidak ditemukan" melainkan menunjuk pengganti. Logika game-nya sudah pindah ke aplikasi,
# jadi nama lama tidak menjalankan apa pun. Save lama tetap terbaca lewat ShellSession.PENGGANTI_FLAG.
# Hapus tabel ini hanya setelah pemberitahuan versi dan tanpa dampak pada save.
const PERINTAH_LAMA := {
    "device": {"ganti": "lsusb", "aplikasi": "Device Manager"},
    "tools": {"ganti": "apt"},
    "security": {"ganti": "network-analyzer"},
    "audit": {"ganti": "password-auditor"},
    "toko": {"aplikasi": "Toko Perangkat"},
    "bm": {"aplikasi": "Pasar"},
    "wallet": {"aplikasi": "Dompet"},
    "scan": {"aplikasi": "Alat Lapangan"},
    "inspeksi": {"aplikasi": "Alat Lapangan"},
    "trace": {"aplikasi": "Alat Lapangan"},
    "decode": {"aplikasi": "Alat Lapangan"},
    "analyze": {"aplikasi": "Alat Lapangan"},
}

static func _pesan_perintah_lama(nama: String) -> String:
    var info: Dictionary = PERINTAH_LAMA[nama]
    if info.has("ganti"):
        var ganti := String(info["ganti"])
        return Bahasa.dua("perintah ini sudah diganti. Gunakan '%s'" % ganti, "this command was replaced. Use '%s'" % ganti)
    var aplikasi := String(info["aplikasi"])
    return Bahasa.dua("perintah ini sudah dipindah ke aplikasi %s di desktop" % aplikasi, "this command moved to the %s app on the desktop" % aplikasi)

static func jalankan(s: ShellSession, p: Dictionary) -> Array:
    var nama := String(p["nama"])
    if PERINTAH_LAMA.has(nama):
        return [s.galat(nama, _pesan_perintah_lama(nama))]
    # Perintah milik tool yang belum dimiliki diperlakukan seperti perintah yang tidak ada.
    if not CommandRegistry.tersedia(s, nama):
        return [s.galat(nama, Teks.t("err.tidak_ditemukan"))]
    match nama:
        "pwd": return [s.baris("info", s.cwd)]
        "whoami": return [s.baris("info", s.user)]
        "echo": return [s.baris("info", " ".join(PackedStringArray(p["argumen"])))]
        "clear": return [s.baris("clear", "")]
        "history": return _history(s)
        "help": return _help(s)
        "apt": return AptCommands.jalankan(s, p)
        "lsusb": return _lsusb(s)
        "airodump-ng": return WifiCommands.airodump(s, p)
        "airmon-ng": return WifiCommands.airmon(s, p)
        "network-analyzer": return WifiCommands.security(s, p)
        "password-auditor": return WifiCommands.audit(s, p)
        "aircrack-ng": return CrackerCommands.aircrack(s, p)
        "hashcat": return CrackerCommands.hashcat(s, p)
        "john": return CrackerCommands.john(s, p)
        "wireshark": return WiresharkCommands.wireshark(s, p)
        "tshark": return WiresharkCommands.tshark(s, p)
        "man": return _man(s, p)
        "ls": return _ls(s, p)
        "cd": return _cd(s, p)
        "cat": return _cat(s, p)
        "mkdir": return _mkdir(s, p)
        "touch": return _touch(s, p)
        "grep": return ShellSearch.grep(s, p)
        "find": return ShellSearch.find(s, p)
        "ping": return PerintahJaringan.ping(s, p)
        "nmap": return PerintahJaringan.nmap(s, p)
        "ssh": return PerintahJaringan.ssh(s, p)
        "exit": return [s.galat("exit", Bahasa.dua("tidak ada sesi SSH aktif", "no active SSH session"))]
        _: return [s.galat(nama, Teks.t("err.tidak_ditemukan"))]

# lsusb: daftar perangkat USB. ID vendor:produk adalah ID asli chipset adapter di katalog perangkat.
const USB_ADAPTER := {
	"usb_wireless_adapter": ["0cf3:9271", "Qualcomm Atheros Communications AR9271 802.11n"],
	"usb_wireless_adapter_rt": ["148f:5370", "Ralink Technology, Corp. RT5370 Wireless Adapter"],
}

static func _lsusb(s: ShellSession) -> Array:
    var hasil: Array = [s.baris("info", "Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub")]
    var ids := USB_ADAPTER.keys()
    ids.sort()
    var nomor := 2
    for id in ids:
        if s.perangkat.jumlah(String(id)) > 0:
            var u: Array = USB_ADAPTER[id]
            hasil.append(s.baris("info", "Bus 001 Device %03d: ID %s %s" % [nomor, u[0], u[1]]))
            nomor += 1
    return hasil

# Saldo dan reputasi pemain. Hanya membaca keadaan; perubahan dilakukan oleh sistem permainan.
static func _history(s: ShellSession) -> Array:
    var hasil: Array = []
    for i in range(s.riwayat.size()):
        hasil.append(s.baris("info", "%5d  %s" % [i + 1, s.riwayat[i]]))
    return hasil

static func _help(s: ShellSession) -> Array:
    var hasil: Array = [{"tipe": "info", "teks": Teks.t("help.judul")}]
    for nama in Teks.MAN.keys():
        if AlatCommands.NAMA.has(String(nama)):
            continue
        if CommandRegistry.tersedia(s, String(nama)):
            hasil.append({"tipe": "info", "teks": "  " + nama})
    return hasil

static func _man(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("man", Teks.t("err.butuh_argumen"))]
    var nama := String(p["argumen"][0])
    if not Teks.MAN.has(nama):
        return [s.galat("man", "%s %s" % [Teks.t("man.tidak_ada"), nama])]
    # Membaca halaman man dicatat sebagai flag, dipakai langkah belajar pada misi tutorial.
    s.jaringan.buka("man:" + nama)
    return [s.baris("info", Teks.man(nama))]

static func _ls(s: ShellSession, p: Dictionary) -> Array:
    var tampil_semua := ShellParser.punya_huruf(p["opsi"], "a")
    var rinci := ShellParser.punya_huruf(p["opsi"], "l")
    var targets: Array = p["argumen"]
    if targets.is_empty():
        targets = [s.cwd]
    var hasil: Array = []
    for t in targets:
        var abs := Vfs.normalisasi(s.cwd, String(t), s.home)
        var node := s.fs.ambil(abs)
        if node.is_empty():
            hasil.append(s.galat("ls", "%s: %s" % [t, Teks.t("err.tidak_ada")]))
            continue
        if String(node["tipe"]) == "file":
            hasil.append(_baris_entri(s, String(t), node, rinci))
            continue
        if not Permissions.boleh(node, s.user, s.grup, "r"):
            hasil.append(s.galat("ls", "%s: %s" % [t, Teks.t("err.izin")]))
            continue
        var isi: Dictionary = node.get("isi", {})
        var nama_list := isi.keys()
        nama_list.sort()
        var nama_tampil: Array = []
        for nama in nama_list:
            if String(nama).begins_with(".") and not tampil_semua:
                continue
            if rinci:
                hasil.append(_baris_entri(s, String(nama), isi[nama], true))
            else:
                nama_tampil.append(String(nama))
        # Tanpa -l, nama ditampilkan dalam satu baris seperti ls di terminal biasa.
        if not rinci and not nama_tampil.is_empty():
            hasil.append(s.baris("info", "  ".join(PackedStringArray(nama_tampil))))
    return hasil

static func _baris_entri(s: ShellSession, nama: String, node: Dictionary, rinci: bool) -> Dictionary:
    if not rinci:
        return s.baris("info", nama + ("/" if String(node["tipe"]) == "dir" else ""))
    var jenis := "d" if String(node["tipe"]) == "dir" else "-"
    var ukuran := int(node.get("ukuran", 0))
    return s.baris("info", "%s%s %s %s %6d %s" % [jenis, String(node.get("izin", "---------")),
        String(node.get("pemilik", "?")), String(node.get("grup", "?")), ukuran, nama])

static func _cd(s: ShellSession, p: Dictionary) -> Array:
    var target := "~"
    if not p["argumen"].is_empty():
        target = String(p["argumen"][0])
    var abs := Vfs.normalisasi(s.cwd, target, s.home)
    var node := s.fs.ambil(abs)
    if node.is_empty():
        return [s.galat("cd", "%s: %s" % [target, Teks.t("err.tidak_ada")])]
    if String(node["tipe"]) != "dir":
        return [s.galat("cd", "%s: %s" % [target, Teks.t("err.bukan_direktori")])]
    if not Permissions.boleh(node, s.user, s.grup, "x"):
        return [s.galat("cd", "%s: %s" % [target, Teks.t("err.izin")])]
    s.cwd = abs
    return []

static func isi_berkas(node: Dictionary) -> String:
    var kunci := String(node.get("isi_key", ""))
    if kunci != "" and Teks.ID.has(kunci):
        return String(Teks.ID[kunci])
    return String(node.get("isi", Teks.t("isi.kosong")))

static func _cat(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("cat", Teks.t("err.butuh_argumen"))]
    var hasil: Array = []
    for t in p["argumen"]:
        var abs := Vfs.normalisasi(s.cwd, String(t), s.home)
        var node := s.fs.ambil(abs)
        if node.is_empty():
            hasil.append(s.galat("cat", "%s: %s" % [t, Teks.t("err.tidak_ada")]))
        elif String(node["tipe"]) == "dir":
            hasil.append(s.galat("cat", "%s: %s" % [t, Teks.t("err.direktori")]))
        elif not Permissions.boleh(node, s.user, s.grup, "r"):
            hasil.append(s.galat("cat", "%s: %s" % [t, Teks.t("err.izin")]))
        elif AnalisisCommands.tolak_cat(s, node) != "":
            hasil.append(s.galat("cat", AnalisisCommands.tolak_cat(s, node)))
        else:
            var isi_teks := isi_berkas(node)
            if not isi_teks.is_empty():
                for baris_teks in isi_teks.split("\n"):
                    hasil.append(s.baris("info", baris_teks))
            # Membaca berkas dicatat sebagai "baca:<host>:<nama>" (host lokal = jtn). Dipakai tujuan misi.
            s.jaringan.buka("baca:%s:%s" % [s.host, s.fs.nama_terakhir(abs)])
            # Berkas penemuan menandai flag saat dibaca, lalu unlock dievaluasi ulang.
            if node.has("penemuan"):
                s.jaringan.buka("temu:" + String(node["penemuan"]))
                UnlockRules.evaluasi(s)
    return hasil

# Membuat node baru di bawah HOME saja. Mengembalikan pesan galat, atau "" bila berhasil.
static func _buat(s: ShellSession, perintah: String, arg: String, dengan_induk: bool, node_baru: Dictionary) -> Dictionary:
    var abs := Vfs.normalisasi(s.cwd, arg, s.home)
    if not abs.begins_with(s.home + "/") and abs != s.home:
        return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.hanya_home")])
    if s.fs.ada(abs):
        if perintah == "mkdir" and dengan_induk:
            return {}
        return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.sudah_ada")])
    var induk := s.fs.induk(abs)
    if not s.fs.ada(induk):
        if not dengan_induk:
            return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.tidak_ada_induk")])
        var sekarang := s.home
        for bagian in abs.substr(s.home.length()).split("/", false):
            var anak := sekarang + "/" + bagian
            if not s.fs.ada(anak):
                s.fs.tambah(sekarang, bagian, _dir_baru(s.user))
            sekarang = anak
        return {}
    var parent := s.fs.ambil(induk)
    if not Permissions.boleh(parent, s.user, s.grup, "w"):
        return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.izin")])
    s.fs.tambah(induk, s.fs.nama_terakhir(abs), node_baru)
    return {}

static func _dir_baru(pemilik: String) -> Dictionary:
    return {"tipe": "dir", "pemilik": pemilik, "grup": pemilik, "izin": "rwxr-x---", "isi": {}}

static func _mkdir(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("mkdir", Teks.t("err.butuh_argumen"))]
    var dengan_induk := ShellParser.punya_huruf(p["opsi"], "p")
    var hasil: Array = []
    for arg in p["argumen"]:
        var g := _buat(s, "mkdir", String(arg), dengan_induk, _dir_baru(s.user))
        if not g.is_empty():
            hasil.append(g)
    return hasil

static func _touch(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("touch", Teks.t("err.butuh_argumen"))]
    var hasil: Array = []
    for arg in p["argumen"]:
        var abs := Vfs.normalisasi(s.cwd, String(arg), s.home)
        if s.fs.ada(abs):
            continue
        var file := {"tipe": "file", "pemilik": s.user, "grup": s.user, "izin": "rw-r-----", "isi": "", "ukuran": 0}
        var g := _buat(s, "touch", String(arg), false, file)
        if not g.is_empty():
            hasil.append(g)
    return hasil
