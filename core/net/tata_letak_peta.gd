class_name TataLetakPeta
extends RefCounted

# Logika Peta Jaringan yang tidak bergantung pada layar: posisi node, keadaan visual, dan sidik perubahan.
# Semua data berasal dari Jaringan, sumber yang sama dengan Terminal.

# Posisi tiap node dalam area. Gerbang di atas, node lain di dua baris.
static func posisi(ids: Array, area: Rect2) -> Dictionary:
    var hasil := {}
    var lain: Array = []
    for id in ids:
        if String(id) == "gerbang":
            hasil["gerbang"] = Vector2(area.position.x + area.size.x * 0.5, area.position.y + area.size.y * 0.2)
        else:
            lain.append(String(id))
    lain.sort()
    var baris1 := lain.slice(0, int(ceil(lain.size() / 2.0)))
    var baris2 := lain.slice(baris1.size())
    _susun_baris(baris1, area, 0.55, hasil)
    _susun_baris(baris2, area, 0.82, hasil)
    return hasil

static func _susun_baris(ids: Array, area: Rect2, proporsi_y: float, hasil: Dictionary) -> void:
    var n := ids.size()
    for i in range(n):
        var x := area.position.x + area.size.x * float(i + 1) / float(n + 1)
        var y := area.position.y + area.size.y * proporsi_y
        hasil[String(ids[i])] = Vector2(x, y)

# Keadaan visual satu node: terkunci, aktif, atau tidak_aktif. Terkunci lebih diutamakan.
static func keadaan(ringkasan: Dictionary) -> String:
    if bool(ringkasan.get("terkunci", false)):
        return "terkunci"
    if String(ringkasan.get("status", "")) == "aktif":
        return "aktif"
    return "tidak_aktif"

# Sidik seluruh tampilan peta. Jika sidik berubah, peta perlu digambar ulang.
static func sidik(j: Jaringan) -> String:
    var bagian: Array = []
    for n in j.daftar_terlihat():
        bagian.append("%s=%s;%s" % [n["id"], keadaan(n), ",".join(PackedStringArray(_tetangga_teks(n)))])
    return "|".join(PackedStringArray(bagian))

static func _tetangga_teks(n: Dictionary) -> Array:
    var hasil: Array = []
    for t in n.get("tetangga", []):
        hasil.append(String(t))
    return hasil

# Pasangan garis koneksi yang keduanya terlihat oleh pemain.
static func sambungan(j: Jaringan) -> Array:
    var hasil: Array = []
    var terlihat: Array = []
    for n in j.daftar_terlihat():
        terlihat.append(String(n["id"]))
    for n in j.daftar_terlihat():
        for t in n.get("tetangga", []):
            var pasangan := [String(n["id"]), String(t)]
            if terlihat.has(String(t)) and not _sudah_ada(hasil, pasangan):
                hasil.append(pasangan)
    return hasil

static func _sudah_ada(daftar: Array, pasangan: Array) -> bool:
    for p in daftar:
        if (p[0] == pasangan[0] and p[1] == pasangan[1]) or (p[0] == pasangan[1] and p[1] == pasangan[0]):
            return true
    return false
