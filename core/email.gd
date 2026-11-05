class_name Email
extends RefCounted

# Kotak masuk E-Mail pemain. Pesan berasal dari data tetap (teks lewat Bahasa),
# sedangkan status (masuk, sampah, sudah dibaca) disimpan di ShellSession.email.

const PESAN := [
	{"id": "panduan", "dari": "email.panduan.dari", "judul": "email.panduan.judul", "isi": "email.panduan.isi"},
	{"id": "mira", "dari": "email.mira.dari", "judul": "email.mira.judul", "isi": "email.mira.isi"},
]

# Pesan misi ikut masuk ke kotak E-Mail. Id-nya "misi:<indeks>" mengacu ke sesi.pesan_misi.
static func pesan_misi(s: ShellSession) -> Array:
	var hasil: Array = []
	for i in range(s.pesan_misi.size()):
		var p: Dictionary = s.pesan_misi[i]
		hasil.append({"id": "misi:%d" % i, "dari": String(p.get("dari", "")), "judul": String(p.get("subjek", "")), "isi": String(p.get("isi", "")), "mentah": true})
	return hasil

static func cari(id: String, s: ShellSession = null) -> Dictionary:
	for p in PESAN:
		if String(p["id"]) == id:
			return p
	if s != null:
		for p in pesan_misi(s):
			if String(p["id"]) == id:
				return p
	return {}

# Status tersimpan per pesan; pesan yang belum punya catatan dianggap masuk dan belum dibaca.
static func status(s: ShellSession, id: String) -> String:
	return String(s.email.get("status", {}).get(id, "masuk"))

static func sudah_dibaca(s: ShellSession, id: String) -> bool:
	return bool(s.email.get("dibaca", {}).get(id, false))

static func daftar(s: ShellSession, status_cari: String) -> Array:
	var hasil: Array = []
	for p in PESAN + pesan_misi(s):
		if status(s, String(p["id"])) == status_cari:
			hasil.append(p)
	return hasil

# Dipakai ikon aplikasi untuk titik merah: ada email masuk yang belum dibaca di sesi utama.
static func ada_belum_dibaca_utama() -> bool:
	var s := SesiUtama.sesi
	return s != null and jumlah_belum_dibaca(s) > 0

static func jumlah_belum_dibaca(s: ShellSession) -> int:
	var n := 0
	for p in daftar(s, "masuk"):
		if not sudah_dibaca(s, String(p["id"])):
			n += 1
	return n

static func tandai_dibaca(s: ShellSession, id: String) -> void:
	_isi_dict(s, "dibaca")[id] = true

static func pindah_ke_sampah(s: ShellSession, id: String) -> void:
	_isi_dict(s, "status")[id] = "sampah"

static func pulihkan(s: ShellSession, id: String) -> void:
	_isi_dict(s, "status")[id] = "masuk"

# Hapus permanen dari sampah: pesan tidak bisa dipulihkan lagi.
static func hapus_permanen(s: ShellSession, id: String) -> void:
	_isi_dict(s, "status")[id] = "terhapus"

static func _isi_dict(s: ShellSession, kunci: String) -> Dictionary:
	if not s.email.has(kunci):
		s.email[kunci] = {}
	return s.email[kunci]

static func sambutan_sudah_tampil(s: ShellSession) -> bool:
	return bool(s.email.get("sambutan", false))

static func tandai_sambutan(s: ShellSession) -> void:
	s.email["sambutan"] = true
