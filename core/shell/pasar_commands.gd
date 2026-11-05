class_name PasarCommands
extends RefCounted

# Perintah Black Market di terminal: bm, bm <penjual>, bm info <id>, bm beli <id>.
# Semua logika ada di BlackMarket; perintah ini hanya menyusun teks hasilnya.

static func jalankan(s: ShellSession, p: Dictionary) -> Array:
    var args: Array = p["argumen"]
    if args.is_empty():
        return _daftar_penjual(s)
    var sub := String(args[0])
    if sub == "beli":
        if args.size() < 2:
            return [s.galat("bm", Teks.t("err.butuh_argumen"))]
        return _beli(s, String(args[1]))
    if sub == "info":
        if args.size() < 2:
            return [s.galat("bm", Teks.t("err.butuh_argumen"))]
        return _info(s, String(args[1]))
    if BlackMarket.penjual_ids().has(sub):
        return _katalog(s, sub)
    return [s.galat("bm", "%s: penjual tidak dikenal" % sub)]

static func _daftar_penjual(s: ShellSession) -> Array:
    var hasil: Array = [s.baris("info", "Penjual di Black Market:")]
    for pid in BlackMarket.penjual_ids():
        var p := BlackMarket.penjual(pid)
        var status := "[terbuka]" if BlackMarket.penjual_terbuka(pid, s.reputation) else "[butuh reputasi %d]" % int(p.get("syarat_rep", 0))
        hasil.append(s.baris("info", "  %s  %s %s" % [pid, String(p.get("nama", pid)), status]))
    return hasil

static func _katalog(s: ShellSession, pid: String) -> Array:
    var p := BlackMarket.penjual(pid)
    var hasil: Array = [s.baris("info", String(p.get("nama", pid)))]
    if not BlackMarket.penjual_terbuka(pid, s.reputation):
        hasil.append(s.baris("info", "Belum terbuka. Butuh reputasi %d (%s)." % [int(p.get("syarat_rep", 0)), Reputation.nama_grup(String(p.get("syarat_grup", "")))]))
        return hasil
    var market := s.market
    for it in p.get("item", []):
        var id := String(it["id"])
        hasil.append(s.baris("info", _ringkas_item(s, id, it)))
    return hasil

static func _ringkas_item(s: ShellSession, id: String, it: Dictionary) -> String:
    var tool := String(it["tool"])
    var tgt := int(it["tingkat"])
    return "  %s  %-18s T%d  %4d Kr  stok %d  %s  %s" % [id, ToolDefs.nama(tool), tgt, ToolDefs.harga(tool, tgt),
        s.market.sisa(id), String(it["kelangkaan"]).replace("_", " "), s.market.status_item(id, s.inventory)]

static func _info(s: ShellSession, id: String) -> Array:
    var it := BlackMarket.item(id)
    if it.is_empty():
        return [s.galat("bm", "%s: item tidak ditemukan" % id)]
    var tool := String(it["tool"])
    var tgt := int(it["tingkat"])
    var hasil: Array = [
        s.baris("info", "%s — %s tingkat %d" % [id, ToolDefs.nama(tool), tgt]),
        s.baris("info", "Harga: %d Kr" % ToolDefs.harga(tool, tgt)),
        s.baris("info", "Stok: %d (%s)" % [s.market.sisa(id), String(it["kelangkaan"]).replace("_", " ")]),
        s.baris("info", "Status: %s" % s.market.status_item(id, s.inventory)),
    ]
    return hasil

static func _beli(s: ShellSession, id: String) -> Array:
    var hasil := s.market.beli(id, s)
    if not bool(hasil["ok"]):
        return [s.galat("bm", String(hasil["pesan"]))]
    return [s.baris("info", String(hasil["pesan"]))]
