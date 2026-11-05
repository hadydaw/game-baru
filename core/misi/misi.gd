class_name Misi
extends RefCounted

# Pusat Misi: data misi dibaca dari JSON. Status disimpan di sesi pemain:
#   tidak ada di s.misi  = belum diterima
#   "aktif"              = pesan sudah diterima, tujuan sedang dikerjakan
#   "selesai"            = semua tujuan terpenuhi; hadiah diberikan sekali lewat Hadiah.
# Semua pemeriksaan memakai flag di Jaringan.progres, sehingga hasil tindakan pemain yang sebenarnya.

const DATA := "res://data/misi/misi.json"

static func daftar(path: String = DATA) -> Array:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_ARRAY:
		return []
	var hasil: Array = parser.data
	hasil.sort_custom(func(a, b): return int(a["urutan"]) < int(b["urutan"]))
	return hasil

static func temukan(id: String) -> Dictionary:
	for m in daftar():
		if String(m["id"]) == id:
			return m
	return {}

# Memperbarui status semua misi berdasarkan flag saat ini. Idempoten: pesan dan hadiah hanya sekali.
static func perbarui(s: ShellSession) -> void:
	var berubah := true
	while berubah:
		berubah = false
		for m in daftar():
			var id := String(m["id"])
			var dari := String(m["pengirim"])
			if not s.misi.has(id):
				if _semua_ada(s, m.get("syarat_terima", [])):
					s.misi[id] = "aktif"
					_kirim(s, id, dari, m["pesan_masuk"])
					berubah = true
			elif String(s.misi[id]) == "aktif" and _tujuan_selesai(s, m):
				s.misi[id] = "selesai"
				_kirim(s, id, dari, m["pesan_selesai"])
				Hadiah.selesaikan_misi(s, id)
				berubah = true

# Daftar tujuan beserta status masing-masing, untuk tampilan.
static func status_tujuan(s: ShellSession, m: Dictionary) -> Array:
	var hasil: Array = []
	for t in m.get("tujuan", []):
		hasil.append({"teks": String(t["teks"]), "selesai": s.jaringan.progres.has(String(t["flag"]))})
	return hasil

# Hanya petunjuk yang sudah ditemukan pemain lewat eksplorasi yang ditampilkan.
static func petunjuk_ditemukan(s: ShellSession, m: Dictionary) -> Array:
	var hasil: Array = []
	for p in m.get("petunjuk", []):
		if s.jaringan.progres.has(String(p["flag"])):
			hasil.append(String(p["teks"]))
	return hasil

static func _tujuan_selesai(s: ShellSession, m: Dictionary) -> bool:
	for t in m.get("tujuan", []):
		if not s.jaringan.progres.has(String(t["flag"])):
			return false
	return not m.get("tujuan", []).is_empty()

static func _semua_ada(s: ShellSession, daftar_flag: Array) -> bool:
	for f in daftar_flag:
		if not s.jaringan.progres.has(String(f)):
			return false
	return true

static func _kirim(s: ShellSession, id: String, dari: String, pesan: Dictionary) -> void:
	s.pesan_misi.append({
		"misi": id,
		"dari": dari,
		"subjek": String(pesan.get("subjek", "")),
		"isi": String(pesan.get("isi", "")),
		"dilaporkan": false,
	})
