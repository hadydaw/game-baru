class_name Reputation
extends RefCounted

# Reputasi 0–100 per grup. Ambang 25, 50, 75 membuka akses bertingkat (anggota, menengah, elite).
# Grup dan ambang dibaca dari data/economy/ekonomi.json.

const MAKS := 100
const MIN := 0

var nilai: Dictionary = {}  # id grup -> int

static func baru() -> Reputation:
	var r := Reputation.new()
	var data := Economy.data_ekonomi()
	for g in Dictionary(data.get("grup", {})).keys():
		r.nilai[String(g)] = 0
	return r

static func nama_grup(id: String) -> String:
	var grup: Dictionary = Dictionary(Economy.data_ekonomi().get("grup", {})).get(id, {})
	return Bahasa.dua(String(grup.get("nama", id)), String(grup.get("nama_en", grup.get("nama", id))))

# Tingkat reputasi dalam dua bahasa, untuk ditampilkan.
const TINGKAT_EN := {"tanpa": "none", "anggota": "member", "menengah": "mid-tier", "elite": "elite"}
static func tingkat_teks(nilai_rep: int) -> String:
	var k := tingkat(nilai_rep)
	return Bahasa.dua(k, String(TINGKAT_EN.get(k, k)))

func get_nilai(grup: String) -> int:
	return int(nilai.get(grup, 0))

func ubah(grup: String, delta: int) -> void:
	nilai[grup] = clampi(get_nilai(grup) + delta, MIN, MAKS)

# Tingkat akses dari nilai reputasi: "tanpa", "anggota", "menengah", atau "elite".
static func tingkat(nilai_rep: int) -> String:
	var ambang: Dictionary = Economy.data_ekonomi().get("ambang_reputasi", {})
	if nilai_rep >= int(ambang.get("elite", 75)):
		return "elite"
	if nilai_rep >= int(ambang.get("menengah", 50)):
		return "menengah"
	if nilai_rep >= int(ambang.get("anggota", 25)):
		return "anggota"
	return "tanpa"

func tingkat_grup(grup: String) -> String:
	return tingkat(get_nilai(grup))

func to_dict() -> Dictionary:
	return {"nilai": nilai.duplicate()}

func terapkan(d: Dictionary) -> void:
	var tersimpan: Dictionary = d.get("nilai", {})
	for g in tersimpan:
		nilai[String(g)] = clampi(int(tersimpan[g]), MIN, MAKS)
