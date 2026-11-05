class_name Pengaturan
extends RefCounted

# Pengaturan perangkat dan nama profil. Disimpan terpisah dari save filesystem,
# sehingga Sesi Baru tidak menghapus pengaturan dan nama profil.

const BERKAS := "user://pengaturan.json"
const UKURAN := {"kecil": 22, "sedang": 26, "besar": 30}
const UKURAN_AWAL := "sedang"
const NAMA_MIN := 3
const NAMA_MAKS := 16

# Aplikasi yang bisa diatur posisinya di Desktop. Urutan ini adalah susunan awal.
const SEMUA_APLIKASI := ["terminal", "peta", "berkas", "tools", "forum", "pasar", "misi", "log"]

# Jalur berkas yang dipakai. Tes mengganti ini agar tidak menimpa pengaturan pemain.
static var berkas_aktif: String = BERKAS

static func muat() -> Dictionary:
	var hasil := {"profil_nama": "", "ukuran_teks": UKURAN_AWAL, "susunan_desktop": []}
	if not FileAccess.file_exists(berkas_aktif):
		return hasil
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(berkas_aktif)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return hasil
	var d: Dictionary = parser.data
	if nama_valid(String(d.get("profil_nama", ""))):
		hasil["profil_nama"] = String(d["profil_nama"])
	if UKURAN.has(String(d.get("ukuran_teks", ""))):
		hasil["ukuran_teks"] = String(d["ukuran_teks"])
	hasil["susunan_desktop"] = _bersihkan_susunan(d.get("susunan_desktop", []))
	return hasil

# Hanya id aplikasi yang dikenal, tanpa duplikat. Id asing diabaikan agar berkas rusak tidak merusak Desktop.
static func _bersihkan_susunan(mentah: Variant) -> Array:
	var hasil: Array = []
	if typeof(mentah) != TYPE_ARRAY:
		return hasil
	for id in mentah:
		var nama := String(id)
		if SEMUA_APLIKASI.has(nama) and not hasil.has(nama):
			hasil.append(nama)
	return hasil

static func simpan(d: Dictionary) -> bool:
	var f := FileAccess.open(berkas_aktif, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	return true

static func _ubah(kunci: String, nilai: Variant) -> bool:
	var d := muat()
	d[kunci] = nilai
	return simpan(d)

static func ukuran_teks() -> String:
	return String(muat()["ukuran_teks"])

static func ukuran_font() -> int:
	return int(UKURAN.get(ukuran_teks(), UKURAN[UKURAN_AWAL]))

static func set_ukuran_teks(kunci: String) -> bool:
	if not UKURAN.has(kunci):
		return false
	return _ubah("ukuran_teks", kunci)

static func nama_profil() -> String:
	return String(muat()["profil_nama"])

# Nama 3–16 karakter berisi huruf, angka, atau garis bawah.
static func nama_valid(nama: String) -> bool:
	if nama.length() < NAMA_MIN or nama.length() > NAMA_MAKS:
		return false
	var r := RegEx.new()
	r.compile("^[A-Za-z0-9_]+$")
	return r.search(nama) != null

static func set_nama_profil(nama: String) -> bool:
	if not nama_valid(nama):
		return false
	return _ubah("profil_nama", nama)

# Susunan ikon Desktop. Kosong berarti urutan awal. Disimpan di pengaturan perangkat, bukan di sesi:
# ini preferensi tampilan dan tidak mengubah progres permainan.
static func susunan_desktop() -> Array:
	return muat()["susunan_desktop"]

static func set_susunan_desktop(urutan: Array) -> bool:
	return _ubah("susunan_desktop", _bersihkan_susunan(urutan))

static func reset_susunan_desktop() -> bool:
	return set_susunan_desktop([])
