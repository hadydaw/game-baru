class_name Vfs
extends RefCounted

# Filesystem virtual. Pohon berbentuk Dictionary:
# {tipe: "dir"|"file", pemilik, grup, izin, isi (dir), isi_key (file), ukuran}
# Dictionary adalah referensi, jadi perubahan lewat ambil() langsung tersimpan.

var akar: Dictionary = {}

func _init(data: Dictionary = {}) -> void:
    akar = data.duplicate(true)

static func normalisasi(cwd: String, path: String, home: String = "/home/operator") -> String:
    var gabungan := path
    if path.begins_with("~"):
        gabungan = home + path.substr(1)
    elif not path.begins_with("/"):
        gabungan = cwd.rstrip("/") + "/" + path
    var bagian: Array = []
    for p in gabungan.split("/", false):
        if p == "." or p.is_empty():
            continue
        if p == "..":
            if bagian.size() > 0:
                bagian.pop_back()
            continue
        bagian.append(p)
    if bagian.is_empty():
        return "/"
    return "/" + String(PackedStringArray(bagian).join("/"))

func ambil(abs_path: String) -> Dictionary:
    if abs_path == "/" or abs_path.is_empty():
        return akar
    var node: Dictionary = akar
    for p in abs_path.split("/", false):
        if String(node.get("tipe", "")) != "dir":
            return {}
        var isi: Dictionary = node.get("isi", {})
        if not isi.has(p):
            return {}
        node = isi[p]
    return node

func ada(abs_path: String) -> bool:
    return not ambil(abs_path).is_empty()

func nama_terakhir(abs_path: String) -> String:
    if abs_path == "/":
        return "/"
    var bagian := abs_path.split("/", false)
    return String(bagian[bagian.size() - 1])

func induk(abs_path: String) -> String:
    if abs_path == "/":
        return "/"
    var bagian := abs_path.split("/", false)
    bagian.remove_at(bagian.size() - 1)
    if bagian.is_empty():
        return "/"
    return "/" + String(PackedStringArray(bagian).join("/"))

func tambah(abs_induk: String, nama: String, node: Dictionary) -> bool:
    var dir := ambil(abs_induk)
    if String(dir.get("tipe", "")) != "dir":
        return false
    var isi: Dictionary = dir.get("isi", {})
    if isi.has(nama):
        return false
    isi[nama] = node
    dir["isi"] = isi
    return true
