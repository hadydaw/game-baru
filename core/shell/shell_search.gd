class_name ShellSearch
extends RefCounted

# grep dan find untuk tahap A. Hanya membaca filesystem virtual.

static func grep(s: ShellSession, p: Dictionary) -> Array:
    var abu := ShellParser.punya_huruf(p["opsi"], "i")
    var no_baris := ShellParser.punya_huruf(p["opsi"], "n")
    var rekursif := ShellParser.punya_huruf(p["opsi"], "r")
    var args: Array = p["argumen"]
    if args.size() < 2 and not (rekursif and args.size() == 1):
        return [s.galat("grep", Teks.t("err.butuh_argumen"))]
    var pola := String(args[0])
    var targets: Array = args.slice(1)
    if targets.is_empty():
        targets = ["."]
    var multi := targets.size() > 1 or rekursif
    var hasil: Array = []
    for t in targets:
        var abs := Vfs.normalisasi(s.cwd, String(t), ShellSession.HOME)
        var node := s.fs.ambil(abs)
        if node.is_empty():
            hasil.append(s.galat("grep", "%s: %s" % [t, Teks.t("err.tidak_ada")]))
            continue
        var berkas: Array = []
        if String(node["tipe"]) == "dir":
            if not rekursif:
                hasil.append(s.galat("grep", "%s: %s" % [t, Teks.t("err.direktori")]))
                continue
            _kumpul_berkas(abs, node, berkas)
        else:
            berkas.append({"path": abs, "node": node})
        for b in berkas:
            if not Permissions.boleh(b["node"], ShellSession.USER, ShellSession.GRUP, "r"):
                hasil.append(s.galat("grep", "%s: %s" % [b["path"], Teks.t("err.izin")]))
                continue
            var nomor := 0
            for baris_teks in ShellCommands.isi_berkas(b["node"]).split("\n"):
                nomor += 1
                var cocok := baris_teks.containsn(pola) if abu else baris_teks.contains(pola)
                if not cocok:
                    continue
                var awal := ""
                if multi:
                    awal += String(b["path"]) + ":"
                if no_baris:
                    awal += str(nomor) + ":"
                hasil.append(s.baris("info", awal + baris_teks))
    return hasil

static func _kumpul_berkas(abs: String, node: Dictionary, out: Array) -> void:
    var isi: Dictionary = node.get("isi", {})
    var kunci := isi.keys()
    kunci.sort()
    for nama in kunci:
        var anak: Dictionary = isi[nama]
        var jalur := abs.rstrip("/") + "/" + String(nama)
        if String(anak["tipe"]) == "dir":
            _kumpul_berkas(jalur, anak, out)
        else:
            out.append({"path": jalur, "node": anak})

static func find(s: ShellSession, p: Dictionary) -> Array:
    var token := ShellParser.tokenkan(String(p["mentah"]))
    var path := "."
    var pola_nama := ""
    var jenis := ""
    var i := 1
    while i < token.size():
        var t := String(token[i])
        if t == "-name" and i + 1 < token.size():
            pola_nama = String(token[i + 1])
            i += 2
            continue
        if t == "-type" and i + 1 < token.size():
            jenis = String(token[i + 1])
            i += 2
            continue
        if not t.begins_with("-"):
            path = t
        i += 1
    var abs := Vfs.normalisasi(s.cwd, path, ShellSession.HOME)
    var node := s.fs.ambil(abs)
    if node.is_empty():
        return [s.galat("find", "%s: %s" % [path, Teks.t("err.tidak_ada")])]
    var hasil: Array = []
    _telusuri(s, abs, node, pola_nama, jenis, hasil)
    return hasil

static func _telusuri(s: ShellSession, abs: String, node: Dictionary, pola: String, jenis: String, out: Array) -> void:
    var nama := s.fs.nama_terakhir(abs)
    var cocok_nama := pola == "" or nama.match(pola)
    var cocok_jenis := jenis == "" or (jenis == "d" and String(node["tipe"]) == "dir") or (jenis == "f" and String(node["tipe"]) == "file")
    if cocok_nama and cocok_jenis:
        out.append(s.baris("info", abs))
    if String(node["tipe"]) != "dir":
        return
    if not Permissions.boleh(node, ShellSession.USER, ShellSession.GRUP, "r"):
        out.append(s.galat("find", "%s: %s" % [abs, Teks.t("err.izin")]))
        return
    var isi: Dictionary = node.get("isi", {})
    var kunci := isi.keys()
    kunci.sort()
    for k in kunci:
        var jalur := abs.rstrip("/") + "/" + String(k)
        _telusuri(s, jalur, isi[k], pola, jenis, out)
