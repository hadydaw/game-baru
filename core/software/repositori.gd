class_name Repositori
extends RefCounted

# Tools Repository: katalog software dan driver, status pemasangan, dan riwayat pembaruan.
# Data katalog dibaca dari data/software/katalog.json. Pemasangan memeriksa dependensi,
# persyaratan adapter, dan saldo sebelum mengubah keadaan.

const DATA := "res://data/software/katalog.json"

var terpasang: Dictionary = {}  # id -> {versi, riwayat: Array}

static func katalog(path: String = DATA) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

static func item(id: String) -> Dictionary:
	return Dictionary(katalog().get(id, {})).duplicate()

static func semua_id() -> Array:
	var ids := katalog().keys()
	ids.sort()
	return ids

# Pencarian sederhana: kata cocok dengan id, nama, kategori, atau deskripsi (tanpa membedakan huruf besar).
static func cari(kata: String) -> Array:
	var k := kata.to_lower().strip_edges()
	var hasil: Array = []
	for id in semua_id():
		var it := item(String(id))
		var teks := (String(id) + " " + String(it["nama"]) + " " + String(it["kategori"]) + " " + Bahasa.t(String(it["deskripsi_kunci"]))).to_lower()
		if k == "" or teks.contains(k):
			hasil.append(String(id))
	return hasil

func punya(id: String) -> bool:
	return terpasang.has(id)

func versi(id: String) -> String:
	return String(Dictionary(terpasang.get(id, {})).get("versi", ""))

func riwayat(id: String) -> Array:
	return Array(Dictionary(terpasang.get(id, {})).get("riwayat", []))

# Aplikasi katalog yang menyediakan perintah tertentu. Kosong bila tidak ada.
static func pemilik_perintah(nama: String) -> String:
	for id in semua_id():
		if Array(item(String(id)).get("perintah", [])).has(nama):
			return String(id)
	return ""

# Semua perintah dari aplikasi yang terpasang. Dipakai CommandRegistry.
func perintah_aktif() -> Array:
	var hasil: Array = []
	for id in terpasang:
		for c in item(String(id)).get("perintah", []):
			hasil.append(String(c))
	return hasil

# Pemasangan: item harus ada, belum terpasang, dependensinya sudah terpasang, persyaratan adapter terpenuhi,
# dan saldo mencukupi. Saldo hanya berkurang bila semua syarat terpenuhi.
func pasang(id: String, ekonomi: Economy, perangkat: Perangkat) -> Dictionary:
	var it := item(id)
	if it.is_empty():
		return _gagal("sw.tidak_ada", [id])
	if punya(id):
		return _gagal("sw.sudah_terpasang", [String(it["nama"])])
	for d in it.get("deps", []):
		if not punya(String(d)):
			return _gagal("sw.dependensi", [String(d)])
	if bool(it.get("butuh_adapter", false)) and not perangkat.sudah_dirakit() and perangkat.adapter_dimiliki().is_empty():
		return _gagal("sw.butuh_adapter", [String(it["nama"])])
	var harga := int(it["harga"])
	if not ekonomi.bisa_bayar(harga):
		return _gagal("sw.saldo_kurang", [harga, ekonomi.saldo])
	ekonomi.bayar(harga)
	var v := String(it["versi_awal"])
	terpasang[id] = {"versi": v, "riwayat": [v]}
	return _ok("sw.dipasang", [String(it["nama"]), v])

# Pembaruan: menaikkan versi terpasang ke versi terbaru di katalog.
func perbarui(id: String) -> Dictionary:
	var it := item(id)
	if it.is_empty() or not punya(id):
		return _gagal("sw.belum_terpasang", [id])
	var terbaru := String(it["versi"])
	if versi(id) == terbaru:
		return _gagal("sw.sudah_terbaru", [String(it["nama"])])
	var r := riwayat(id)
	r.append(terbaru)
	terpasang[id] = {"versi": terbaru, "riwayat": r}
	return _ok("sw.diperbarui", [String(it["nama"]), terbaru])

# Driver terpasang yang mendukung chipset tertentu; kosong bila tidak ada.
func driver_untuk(chipset: String) -> String:
	for id in terpasang:
		var it := item(String(id))
		if String(it["tipe"]) == "driver" and Array(it.get("chipset", [])).has(chipset):
			return String(id)
	return ""

func _ok(kunci: String, args: Array) -> Dictionary:
	return {"ok": true, "kunci": kunci, "args": args}

func _gagal(kunci: String, args: Array) -> Dictionary:
	return {"ok": false, "kunci": kunci, "args": args}

func to_dict() -> Dictionary:
	return {"terpasang": terpasang.duplicate(true)}

func terapkan(d: Dictionary) -> void:
	terpasang = {}
	var t: Dictionary = d.get("terpasang", {})
	for id in t:
		if not item(String(id)).is_empty():
			var e: Dictionary = t[id]
			terpasang[String(id)] = {"versi": String(e.get("versi", "")), "riwayat": Array(e.get("riwayat", [])).duplicate()}
