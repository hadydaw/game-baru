class_name Misi
extends RefCounted

# Pusat Misi: data misi dibaca dari JSON. Status disimpan di sesi pemain:
#   tidak ada di s.misi  = belum diterima
#   "aktif"              = pesan sudah diterima, tujuan sedang dikerjakan
#   "selesai"            = semua tujuan terpenuhi; hadiah diberikan sekali lewat Hadiah.
# Semua pemeriksaan memakai flag di Jaringan.progres, sehingga hasil tindakan pemain yang sebenarnya.

const DATA := "res://data/misi/misi.json"

# Berkas sumber misi. Tes dapat mengarahkannya ke fixture; permainan memakai DATA.
static var berkas: String = DATA

static func daftar(path: String = "") -> Array:
	var sumber := path if path != "" else berkas
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(sumber)) != OK or typeof(parser.data) != TYPE_ARRAY:
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

# Mengganti penanda {ip:id} dengan IP node sesi ini. IP tidak pernah ditulis permanen di data misi.
static func ganti_ip(s: ShellSession, teks: String) -> String:
	var re := RegEx.new()
	re.compile("\\{ip:([a-z_]+)\\}")
	var hasil := teks
	for m in re.search_all(teks):
		var id := m.get_string(1)
		hasil = hasil.replace(m.get_string(0), s.jaringan.ip(id))
	return hasil

# Daftar tujuan beserta status masing-masing, untuk tampilan.
static func status_tujuan(s: ShellSession, m: Dictionary) -> Array:
	var hasil: Array = []
	for t in m.get("tujuan", []):
		hasil.append({"teks": ganti_ip(s, String(t["teks"])), "selesai": s.jaringan.progres.has(String(t["flag"]))})
	return hasil

# Hanya petunjuk yang sudah ditemukan pemain lewat eksplorasi yang ditampilkan.
static func petunjuk_ditemukan(s: ShellSession, m: Dictionary) -> Array:
	var hasil: Array = []
	for p in m.get("petunjuk", []):
		if s.jaringan.progres.has(String(p["flag"])):
			hasil.append(ganti_ip(s, String(p["teks"])))
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
		"subjek": ganti_ip(s, String(pesan.get("subjek", ""))),
		"isi": ganti_ip(s, String(pesan.get("isi", ""))),
		"dilaporkan": false,
	})

# Kategori misi untuk tampilan Misi Tersedia. Urutan di sini adalah urutan tampil di layar.
const KATEGORI := [
	{"kunci": "tutorial_lanjutan", "judul": "misi.kat.tutorial_lanjutan", "ikon": "tutorial_lanjutan"},
	{"kunci": "harian", "judul": "misi.kat.harian", "ikon": "harian"},
	{"kunci": "hacktivism", "judul": "misi.kat.hacktivism", "ikon": "hacktivism"},
	{"kunci": "rekayasa_sosial", "judul": "misi.kat.rekayasa_sosial", "ikon": "rekayasa_sosial"},
	{"kunci": "peretasan_perusahaan", "judul": "misi.kat.peretasan_perusahaan", "ikon": "peretasan_perusahaan"},
	{"kunci": "peretasan_industri", "judul": "misi.kat.peretasan_industri", "ikon": "peretasan_industri"},
	{"kunci": "peretasan_bank", "judul": "misi.kat.peretasan_bank", "ikon": "peretasan_bank"},
	{"kunci": "perang_maya", "judul": "misi.kat.perang_maya", "ikon": "perang_maya"},
]

static func kategori_misi(m: Dictionary) -> String:
	return String(m.get("kategori", ""))

static func daftar_kategori(kunci: String, sumber: Array = []) -> Array:
	var data: Array = sumber if not sumber.is_empty() else daftar()
	var hasil: Array = []
	for m in data:
		if kategori_misi(m) == kunci:
			hasil.append(m)
	return hasil

static func ikon_kategori(kunci: String) -> String:
	for k in KATEGORI:
		if String(k["kunci"]) == kunci:
			return "res://assets/ikon/misi/%s.png" % String(k["ikon"])
	return ""
