class_name ToolCommands
extends RefCounted

# Perintah yang disediakan tool: tools, inspeksi (Packet Inspector), dan trace (Signal Tracer).
# Semua hasil dihitung dari data jaringan dan inventaris pemain; tidak ada akses sistem.

const BATAS_LOG_T1 := 24
const ALAMAT_DISAMARKAN := "***.***.***.***"

static func tools(s: ShellSession) -> Array:
    var inv := s.inventory
    if inv.milik.is_empty():
        return [s.baris("info", "Tidak ada tool yang dimiliki.")]
    var hasil: Array = [s.baris("info", "Tool yang dimiliki:")]
    var ids := inv.milik.keys()
    ids.sort()
    for id in ids:
        hasil.append(s.baris("info", "  %-18s tingkat %d/%d  (%s)" % [ToolDefs.nama(String(id)), inv.tingkat(String(id)), ToolDefs.maks(String(id)), inv.sumber(String(id))]))
    return hasil

# inspeksi <host>: membaca log transfer node yang sudah pernah dipindai nmap.
static func inspeksi(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("inspeksi", Teks.t("err.butuh_argumen"))]
    var target := String(p["argumen"][0])
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("inspeksi", "%s: Nama atau layanan tidak diketahui" % target)]
    if j.terkunci(id):
        return [s.galat("inspeksi", "%s: Host tidak dapat dijangkau" % target)]
    if not j.sudah_dipindai(id):
        return [s.galat("inspeksi", "%s: host belum dipindai dengan nmap" % target)]
    var t := s.inventory.tingkat("packet_inspector")
    var log: Array = j.data[id].get("log", [])
    var terhapus: Array = j.data[id].get("log_terhapus", []) if t >= 3 else []
    var hasil: Array = [s.baris("info", "Log transfer %s:" % target)]
    if log.is_empty() and terhapus.is_empty():
        hasil.append(s.baris("info", "(tidak ada log)"))
        return hasil
    var awal := maxi(log.size() - BATAS_LOG_T1, 0) if t == 1 else 0
    for i in range(awal, log.size()):
        hasil.append(_baris_log(s, log[i], t, ""))
    for e in terhapus:
        hasil.append(_baris_log(s, e, t, "[cache] "))
    return hasil

static func _baris_log(s: ShellSession, e: Dictionary, t: int, awalan: String) -> Dictionary:
    var ke := String(e.get("ke", ""))
    var dari := String(e.get("dari", ""))
    if t < 2:
        ke = ALAMAT_DISAMARKAN
    else:
        ke = _alamat_tampil(s, ke)
    dari = _alamat_tampil(s, dari)
    return s.baris("info", "%s%s  %s -> %s  %dB" % [awalan, String(e.get("jam", "")), dari, ke, int(e.get("bytes", 0))])

# Log menyimpan id node; tampilan tingkat 2 ke atas memakai IP node tersebut.
static func _alamat_tampil(s: ShellSession, nilai: String) -> String:
    return s.jaringan.ip(nilai) if s.jaringan.data.has(nilai) else nilai

# trace <host>: menampilkan jalur koneksi dari node. Tingkat 1: satu hop, 2: dua hop, 3: seluruh jaringan.
# Node yang tampil (dan tidak terkunci) menjadi terlihat di peta.
static func trace(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("trace", Teks.t("err.butuh_argumen"))]
    var target := String(p["argumen"][0])
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("trace", "%s: Nama atau layanan tidak diketahui" % target)]
    if j.terkunci(id):
        return [s.galat("trace", "%s: Host tidak dapat dijangkau" % target)]
    var t := s.inventory.tingkat("signal_tracer")
    var kedalaman := _kedalaman(j, id)
    var hasil: Array = [s.baris("info", "Jalur dari %s:" % target)]
    var ids := j.data.keys()
    ids.sort()
    var tampil := 0
    for hid in ids:
        var hop := String(hid)
        if hop == id:
            continue
        var d := int(kedalaman.get(hop, -1))
        if t < 3 and (d < 1 or d > t):
            continue
        # Node yang butuh scan tidak tampil dan tidak terbuka sebelum ditemukan lewat perintah scan.
        if j.butuh_scan(hop) and not j.dikenal(hop):
            continue
        tampil += 1
        if j.terkunci(hop):
            hasil.append(s.baris("info", "%s  %s  terkunci" % [_label_hop(d), hop]))
            continue
        if not j.dikenal(hop):
            j.ditemukan.append(hop)
        hasil.append(s.baris("info", "%s  %s (%s)" % [_label_hop(d), hop, j.ip(hop)]))
    if tampil == 0:
        hasil.append(s.baris("info", "Tidak ada jalur lanjutan dari %s." % target))
    return hasil

static func _label_hop(d: int) -> String:
    return "-" if d < 0 else str(d)

# Jarak (jumlah hop) dari node awal ke setiap node yang terhubung. Node tak terjangkau tidak ada di hasil.
static func _kedalaman(j: Jaringan, awal: String) -> Dictionary:
    var jarak := {awal: 0}
    var antrean := [awal]
    while not antrean.is_empty():
        var cur := String(antrean.pop_front())
        for t in j.data[cur].get("tetangga", []):
            var n := String(t)
            if j.data.has(n) and not jarak.has(n):
                jarak[n] = int(jarak[cur]) + 1
                antrean.append(n)
    return jarak
