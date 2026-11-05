class_name ShellCommands
extends RefCounted

# Dispatch perintah dan handler tahap A (navigasi dan berkas).
# Setiap handler menerima sesi dan hasil parse, lalu mengembalikan Array of {tipe, teks}.

static func jalankan(s: ShellSession, p: Dictionary) -> Array:
    var nama := String(p["nama"])
    match nama:
        "pwd": return [s.baris("info", s.cwd)]
        "whoami": return [s.baris("info", ShellSession.USER)]
        "echo": return [s.baris("info", " ".join(PackedStringArray(p["argumen"])))]
        "clear": return [s.baris("clear", "")]
        "history": return _history(s)
        "help": return _help()
        "man": return _man(s, p)
        "ls": return _ls(s, p)
        "cd": return _cd(s, p)
        "cat": return _cat(s, p)
        "mkdir": return _mkdir(s, p)
        "touch": return _touch(s, p)
        "grep": return ShellSearch.grep(s, p)
        "find": return ShellSearch.find(s, p)
        _: return [s.galat(nama, Teks.t("err.tidak_ditemukan"))]

static func _history(s: ShellSession) -> Array:
    var hasil: Array = []
    for i in range(s.riwayat.size()):
        hasil.append(s.baris("info", "%5d  %s" % [i + 1, s.riwayat[i]]))
    return hasil

static func _help() -> Array:
    var hasil: Array = [{"tipe": "info", "teks": Teks.t("help.judul")}]
    for nama in Teks.MAN.keys():
        hasil.append({"tipe": "info", "teks": "  " + nama})
    return hasil

static func _man(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("man", Teks.t("err.butuh_argumen"))]
    var nama := String(p["argumen"][0])
    if not Teks.MAN.has(nama):
        return [s.galat("man", "%s %s" % [Teks.t("man.tidak_ada"), nama])]
    return [s.baris("info", String(Teks.MAN[nama]))]

static func _ls(s: ShellSession, p: Dictionary) -> Array:
    var tampil_semua := ShellParser.punya_huruf(p["opsi"], "a")
    var rinci := ShellParser.punya_huruf(p["opsi"], "l")
    var targets: Array = p["argumen"]
    if targets.is_empty():
        targets = [s.cwd]
    var hasil: Array = []
    for t in targets:
        var abs := Vfs.normalisasi(s.cwd, String(t), ShellSession.HOME)
        var node := s.fs.ambil(abs)
        if node.is_empty():
            hasil.append(s.galat("ls", "%s: %s" % [t, Teks.t("err.tidak_ada")]))
            continue
        if String(node["tipe"]) == "file":
            hasil.append(_baris_entri(s, String(t), node, rinci))
            continue
        if not Permissions.boleh(node, ShellSession.USER, ShellSession.GRUP, "r"):
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
    var abs := Vfs.normalisasi(s.cwd, target, ShellSession.HOME)
    var node := s.fs.ambil(abs)
    if node.is_empty():
        return [s.galat("cd", "%s: %s" % [target, Teks.t("err.tidak_ada")])]
    if String(node["tipe"]) != "dir":
        return [s.galat("cd", "%s: %s" % [target, Teks.t("err.bukan_direktori")])]
    if not Permissions.boleh(node, ShellSession.USER, ShellSession.GRUP, "x"):
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
        var abs := Vfs.normalisasi(s.cwd, String(t), ShellSession.HOME)
        var node := s.fs.ambil(abs)
        if node.is_empty():
            hasil.append(s.galat("cat", "%s: %s" % [t, Teks.t("err.tidak_ada")]))
        elif String(node["tipe"]) == "dir":
            hasil.append(s.galat("cat", "%s: %s" % [t, Teks.t("err.direktori")]))
        elif not Permissions.boleh(node, ShellSession.USER, ShellSession.GRUP, "r"):
            hasil.append(s.galat("cat", "%s: %s" % [t, Teks.t("err.izin")]))
        else:
            var isi_teks := isi_berkas(node)
            if not isi_teks.is_empty():
                for baris_teks in isi_teks.split("\n"):
                    hasil.append(s.baris("info", baris_teks))
    return hasil

# Membuat node baru di bawah HOME saja. Mengembalikan pesan galat, atau "" bila berhasil.
static func _buat(s: ShellSession, perintah: String, arg: String, dengan_induk: bool, node_baru: Dictionary) -> Dictionary:
    var abs := Vfs.normalisasi(s.cwd, arg, ShellSession.HOME)
    if not abs.begins_with(ShellSession.HOME + "/") and abs != ShellSession.HOME:
        return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.hanya_home")])
    if s.fs.ada(abs):
        if perintah == "mkdir" and dengan_induk:
            return {}
        return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.sudah_ada")])
    var induk := s.fs.induk(abs)
    if not s.fs.ada(induk):
        if not dengan_induk:
            return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.tidak_ada_induk")])
        var sekarang := ShellSession.HOME
        for bagian in abs.substr(ShellSession.HOME.length()).split("/", false):
            var anak := sekarang + "/" + bagian
            if not s.fs.ada(anak):
                s.fs.tambah(sekarang, bagian, _dir_baru())
            sekarang = anak
        return {}
    var parent := s.fs.ambil(induk)
    if not Permissions.boleh(parent, ShellSession.USER, ShellSession.GRUP, "w"):
        return s.galat(perintah, "%s: %s" % [arg, Teks.t("err.izin")])
    s.fs.tambah(induk, s.fs.nama_terakhir(abs), node_baru)
    return {}

static func _dir_baru() -> Dictionary:
    return {"tipe": "dir", "pemilik": ShellSession.USER, "grup": "operator", "izin": "rwxr-x---", "isi": {}}

static func _mkdir(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("mkdir", Teks.t("err.butuh_argumen"))]
    var dengan_induk := ShellParser.punya_huruf(p["opsi"], "p")
    var hasil: Array = []
    for arg in p["argumen"]:
        var g := _buat(s, "mkdir", String(arg), dengan_induk, _dir_baru())
        if not g.is_empty():
            hasil.append(g)
    return hasil

static func _touch(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("touch", Teks.t("err.butuh_argumen"))]
    var hasil: Array = []
    for arg in p["argumen"]:
        var abs := Vfs.normalisasi(s.cwd, String(arg), ShellSession.HOME)
        if s.fs.ada(abs):
            continue
        var file := {"tipe": "file", "pemilik": ShellSession.USER, "grup": "operator", "izin": "rw-r-----", "isi": "", "ukuran": 0}
        var g := _buat(s, "touch", String(arg), false, file)
        if not g.is_empty():
            hasil.append(g)
    return hasil
