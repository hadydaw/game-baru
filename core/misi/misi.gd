class_name Misi
extends RefCounted

# Pusat Misi: data misi dibaca dari JSON. Status disimpan di sesi pemain:
#   tidak ada di s.misi  = belum diterima
#   "aktif"              = sudah diterima pemain lewat MENERIMA, tujuan sedang dikerjakan
#   "selesai"            = semua tujuan terpenuhi; hadiah diberikan sekali lewat Hadiah.
# Semua pemeriksaan memakai flag di Jaringan.progres, sehingga hasil tindakan pemain yang sebenarnya.

const DATA := "res://data/misi/misi.json"

# Berkas sumber misi. Tes dapat mengarahkannya ke fixture; permainan memakai DATA.
static var berkas: String = DATA

# Teks misi punya pasangan "<kunci>_en". Saat data dimuat, keduanya digabung menjadi satu teks dua-bahasa.
static func _dwibahasa(o: Variant) -> void:
	if o is Array:
		for x in o:
			_dwibahasa(x)
	elif o is Dictionary:
		for k in o.keys():
			if not o.has(k) or String(k).ends_with("_en"):
				continue
			var en := String(k) + "_en"
			if o.has(en) and typeof(o[k]) == TYPE_STRING:
				o[k] = Bahasa.dua(String(o[k]), String(o[en]))
				o.erase(en)
			else:
				_dwibahasa(o[k])

static func daftar(path: String = "") -> Array:
	var sumber := path if path != "" else berkas
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(sumber)) != OK or typeof(parser.data) != TYPE_ARRAY:
		return []
	_dwibahasa(parser.data)
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
			if String(s.misi.get(id, "")) == "aktif" and _tujuan_selesai(s, m):
				s.misi[id] = "selesai"
				_kirim(s, id, dari, m["pesan_selesai"])
				Hadiah.selesaikan_misi(s, id)
				berubah = true
			elif String(s.misi.get(id, "")) == "aktif" and _cek_tahap(s, m):
				berubah = true

# Misi tersedia: syarat terpenuhi, tetapi belum diterima pemain.
static func tersedia(s: ShellSession, m: Dictionary) -> bool:
	return not s.misi.has(String(m["id"])) and _semua_ada(s, m.get("syarat_terima", []))

# Pemain menerima misi lewat tombol MENERIMA. Pesan masuk dikirim ke Email sekali di sini.
static func terima(s: ShellSession, id: String) -> bool:
	var m := temukan(id)
	if m.is_empty() or not tersedia(s, m):
		return false
	s.misi[id] = "aktif"
	_kirim(s, id, String(m["pengirim"]), _pesan_masuk_lengkap(m))
	_kirim_tahap(s, m, 1)
	perbarui(s)
	return true

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

# Tahap misi dituntun lewat Email: email tahap n+1 datang saat tahap n selesai.
static func _cek_tahap(s: ShellSession, m: Dictionary) -> bool:
	var id := String(m["id"])
	# Nomor tahap dibaca sebagai bilangan bulat: JSON memuatnya sebagai float (1.0), yang tidak sama dengan 1.
	var sudah: Array = []
	for x in s.misi_tahap.get(id, []):
		sudah.append(int(x))
	var baru := false
	var daftar: Array = m.get("tahap", [])
	for i in range(daftar.size()):
		var n := i + 1
		if sudah.has(n) or not _tahap_selesai(s, m, n):
			continue
		sudah.append(n)
		s.misi_tahap[id] = sudah
		_kirim_tahap(s, m, n + 1)
		baru = true
	return baru

# Email untuk tahap n: instruksi tahap itu beserta daftar tujuannya.
static func _kirim_tahap(s: ShellSession, m: Dictionary, n: int) -> void:
	var daftar: Array = m.get("tahap", [])
	if n < 1 or n > daftar.size():
		return
	var t: Dictionary = daftar[n - 1]
	# Email hanya pengantar langkah. Penjelasan lengkap ada di aplikasi Misi, langkah demi langkah.
	var isi := String(t["pesan"]) + _rincian_tahap(m, n) + "\n\n" + Bahasa.dua("Buka aplikasi Misi untuk panduan lengkap langkah ini.", "Open the Missions app for the full guide to this step.")
	_kirim(s, String(m["id"]), String(m["pengirim"]), {"subjek": String(t["judul"]), "isi": isi})

static func _tahap_selesai(s: ShellSession, m: Dictionary, n: int) -> bool:
	var ada := false
	for t in m.get("tujuan", []):
		if int(t.get("tahap", 0)) != n:
			continue
		ada = true
		if not s.jaringan.progres.has(String(t["flag"])):
			return false
	return ada

# Progres per tahap untuk tampilan: judul tahap, dan tujuan di dalamnya dengan statusnya.
static func tahap_progres(s: ShellSession, m: Dictionary) -> Array:
	var hasil: Array = []
	var daftar: Array = m.get("tahap", [])
	for i in range(daftar.size()):
		var n := i + 1
		var items: Array = []
		for t in m.get("tujuan", []):
			if int(t.get("tahap", 0)) == n:
				items.append({"teks": ganti_ip(s, String(t["teks"])), "selesai": s.jaringan.progres.has(String(t["flag"]))})
		hasil.append({"judul": String(daftar[i]["judul"]), "tujuan": items, "selesai": _tahap_selesai(s, m, n),
			"alasan": String(daftar[i].get("alasan", "")), "pengetahuan": String(daftar[i].get("pengetahuan", ""))})
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

# Email masuk membawa rincian misi lengkap, jadi pemain tidak perlu membuka daftar misi untuk tahu tujuannya.
static func _pesan_masuk_lengkap(m: Dictionary) -> Dictionary:
	var p: Dictionary = (m["pesan_masuk"] as Dictionary).duplicate()
	var hadiah := int(Hadiah.data().get(String(m["id"]), {}).get("kredit", 0))
	var r := "\n\n"
	r += Bahasa.dua("Tujuan: ", "Goal: ") + String(m.get("tujuan_ringkas", "")) + "\n"
	r += Bahasa.dua("Pembayaran: Kr %d", "Payment: Kr %d", [hadiah]) + "\n"
	r += Bahasa.dua("Persyaratan: ", "Requirements: ") + String(m.get("persyaratan", "-")) + "\n"
	r += Bahasa.dua("Target: ", "Target: ") + String(m.get("target", "")) + "\n"
	r += Bahasa.dua("Buka aplikasi Misi untuk panduan langkah demi langkah.", "Open the Missions app for a step-by-step guide.")
	p["isi"] = String(p.get("isi", "")) + r
	return p

# Email tiap tahap membawa daftar tujuan di tahap itu, sebagai rincian tahap yang baru selesai.
static func _rincian_tahap(m: Dictionary, n: int) -> String:
	var r := "\n\n" + Bahasa.dua("Tujuan tahap ini:", "Goals of this stage:")
	for t in m.get("tujuan", []):
		if int(t.get("tahap", 0)) == n:
			r += "\n- " + String(t["teks"])
	return r

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
	{"kunci": "tutorial", "judul": "misi.kat.tutorial", "ikon": "tutorial"},
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
