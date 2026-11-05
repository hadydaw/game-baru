class_name Lokasi
extends RefCounted

# Lokasi pemain di peta dunia: 10 negara, masing-masing 10 kota.
# Data dibaca dari data/lokasi/negara.json. Koordinat x,y adalah posisi relatif (0..1) di peta.

const BERKAS := "res://data/lokasi/negara.json"

static var _cache: Array = []

static func semua_negara() -> Array:
	if _cache.is_empty():
		_cache = _muat()
	return _cache

static func cari_negara(kode: String) -> Dictionary:
	for n in semua_negara():
		if n["kode"] == kode:
			return n
	return {}

static func cari_kota(kode_negara: String, kode_kota: String) -> Dictionary:
	for k in cari_negara(kode_negara).get("kota", []):
		if k["kode"] == kode_kota:
			return k
	return {}

static func nama_negara(kode: String) -> String:
	var n := cari_negara(kode)
	return _pilih_bahasa(n.get("nama", {"id": kode, "en": kode}))

static func nama_kota(kode_negara: String, kode_kota: String) -> String:
	var k := cari_kota(kode_negara, kode_kota)
	return _pilih_bahasa(k.get("nama", {"id": kode_kota, "en": kode_kota}))

static func _pilih_bahasa(nama: Dictionary) -> String:
	var kode := Bahasa.kode
	return str(nama.get(kode, nama.get("id", "")))

static func _muat() -> Array:
	if not ResourceLoader.exists(BERKAS) and not FileAccess.file_exists(BERKAS):
		push_warning("Data lokasi tidak ditemukan: %s" % BERKAS)
		return []
	var teks := FileAccess.get_file_as_string(BERKAS)
	var data: Variant = JSON.parse_string(teks)
	if typeof(data) != TYPE_ARRAY:
		push_warning("Format data lokasi tidak valid")
		return []
	return data
