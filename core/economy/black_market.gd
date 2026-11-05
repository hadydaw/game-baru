class_name BlackMarket
extends RefCounted

# Black Market: beberapa penjual dengan syarat reputasi, katalog tool, stok, dan kelangkaan.
# Semua data dibaca dari data/economy/black_market.json. Pembelian diproses di sini, bukan di layar.
# Stok bisa pulih ketika flag misi tertentu aktif (pulih_oleh), bukan berdasarkan waktu nyata.

const DATA := "res://data/economy/black_market.json"

var stok: Dictionary = {}  # id item -> sisa stok

static func baru() -> BlackMarket:
	var m := BlackMarket.new()
	for pid in penjual_ids():
		for it in penjual(pid).get("item", []):
			m.stok[String(it["id"])] = int(it["stok"])
	return m

static func _data(path: String = DATA) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

static func penjual_ids() -> Array:
	var ids := Dictionary(_data().get("penjual", {})).keys()
	ids.sort()
	return ids

static func penjual(id: String) -> Dictionary:
	return Dictionary(Dictionary(_data().get("penjual", {})).get(id, {}))

# Data satu item beserta id penjualnya. Kosong bila id tidak ada.
static func item(id: String) -> Dictionary:
	for pid in penjual_ids():
		for it in penjual(pid).get("item", []):
			if String(it["id"]) == id:
				var hasil: Dictionary = Dictionary(it).duplicate()
				hasil["penjual"] = pid
				return hasil
	return {}

static func id_penjual_dari_item(id: String) -> String:
	return String(item(id).get("penjual", ""))

func sisa(id: String) -> int:
	return int(stok.get(id, 0))

static func penjual_terbuka(pid: String, rep: Reputation) -> bool:
	var p := penjual(pid)
	if p.is_empty():
		return false
	return rep.get_nilai(String(p.get("syarat_grup", ""))) >= int(p.get("syarat_rep", 0))

# Status item bagi pemain: "dimiliki", "upgrade", "tersedia", atau "habis".
func status_item(id: String, inv: Inventory) -> String:
	var it := item(id)
	if it.is_empty():
		return ""
	if sisa(id) <= 0:
		return "habis"
	var tool := String(it["tool"])
	var tgt := int(it["tingkat"])
	if inv.tingkat(tool) >= tgt:
		return "dimiliki"
	if inv.punya(tool):
		return "upgrade"
	return "tersedia"

# Membeli tool atau peningkatan tingkat. Semua syarat diperiksa dulu; saldo hanya berkurang bila berhasil.
# Mengembalikan {ok, pesan}.
func beli(id: String, s: ShellSession) -> Dictionary:
	var it := item(id)
	if it.is_empty():
		return _gagal("Item tidak ditemukan: %s" % id)
	var pid := String(it["penjual"])
	if not penjual_terbuka(pid, s.reputation):
		var p := penjual(pid)
		return _gagal("%s belum mau bertransaksi. Butuh reputasi %d (%s)." % [String(p.get("nama", pid)), int(p.get("syarat_rep", 0)), Reputation.nama_grup(String(p.get("syarat_grup", "")))])
	if sisa(id) <= 0:
		return _gagal("Stok habis.")
	var tool := String(it["tool"])
	var tgt := int(it["tingkat"])
	if s.inventory.tingkat(tool) >= tgt:
		return _gagal("%s tingkat %d sudah dimiliki." % [ToolDefs.nama(tool), tgt])
	var harga := ToolDefs.harga(tool, tgt)
	if not s.economy.bisa_bayar(harga):
		return _gagal("Saldo tidak cukup. Harga %d Kr, saldo %d Kr." % [harga, s.economy.saldo])
	s.economy.bayar(harga)
	if s.inventory.punya(tool):
		s.inventory.setel_tingkat(tool, tgt)
	else:
		s.inventory.miliki(tool, "black_market", tgt)
	stok[id] = sisa(id) - 1
	return {"ok": true, "pesan": "Dibeli: %s tingkat %d seharga %d Kr." % [ToolDefs.nama(tool), tgt, harga]}

# Mengisi ulang stok item yang bergantung pada flag misi tertentu.
func pulihkan_untuk_flag(flag: String) -> void:
	for pid in penjual_ids():
		for it in penjual(pid).get("item", []):
			if String(it.get("pulih_oleh", "")) == flag:
				stok[String(it["id"])] = int(it["stok"])

func _gagal(pesan: String) -> Dictionary:
	return {"ok": false, "pesan": pesan}

func to_dict() -> Dictionary:
	return {"stok": stok.duplicate()}

func terapkan(d: Dictionary) -> void:
	var tersimpan: Dictionary = d.get("stok", {})
	for id in tersimpan:
		if stok.has(String(id)):
			stok[String(id)] = clampi(int(tersimpan[id]), 0, int(item(String(id)).get("stok", 0)))
