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
const SEMUA_APLIKASI := ["terminal", "peta", "berkas", "tools", "forum", "pasar", "misi", "log", "email", "perangkat", "netmgr", "inventaris"]
# Ukuran grid ikon Desktop (kolom x baris). Harus sama dengan DesktopView.KOLOM dan BARIS.
const KOLOM_DESKTOP := 4
const BARIS_DESKTOP := 4

# Jalur berkas yang dipakai. Tes mengganti ini agar tidak menimpa pengaturan pemain.
static var berkas_aktif: String = BERKAS

static func muat() -> Dictionary:
	var hasil := {"profil_nama": "", "ukuran_teks": UKURAN_AWAL, "bahasa": Bahasa.KODE_AWAL, "posisi_desktop": {}}
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
	if Bahasa.KODE.has(String(d.get("bahasa", ""))):
		hasil["bahasa"] = String(d["bahasa"])
	hasil["posisi_desktop"] = _bersihkan_posisi(d.get("posisi_desktop", {}))
	return hasil

# Posisi ikon: id -> [kolom, baris]. Hanya id yang dikenal, koordinat dalam grid, dan satu ikon per sel.
static func _bersihkan_posisi(mentah: Variant) -> Dictionary:
	var hasil := {}
	if typeof(mentah) != TYPE_DICTIONARY:
		return hasil
	var terpakai := {}
	for k in mentah:
		var id := String(k)
		var v: Variant = mentah[k]
		if not SEMUA_APLIKASI.has(id) or typeof(v) != TYPE_ARRAY or v.size() != 2:
			continue
		var c := int(v[0])
		var r := int(v[1])
		if c < 0 or c >= KOLOM_DESKTOP or r < 0 or r >= BARIS_DESKTOP:
			continue
		var sel := Vector2i(c, r)
		if terpakai.has(sel):
			continue
		terpakai[sel] = true
		hasil[id] = [c, r]
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

static func bahasa() -> String:
	return String(muat()["bahasa"])

# Menyimpan bahasa dan langsung mengaktifkannya untuk tampilan berikutnya.
static func set_bahasa(kode: String) -> bool:
	if not Bahasa.KODE.has(kode):
		return false
	if not _ubah("bahasa", kode):
		return false
	Bahasa.set_kode(kode)
	return true

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

# Posisi ikon Desktop. Kosong berarti posisi awal. Disimpan sebagai preferensi perangkat, bukan di sesi,
# sehingga tidak mengubah progres permainan.
static func posisi_desktop() -> Dictionary:
	return muat()["posisi_desktop"]

static func set_posisi_desktop(posisi: Dictionary) -> bool:
	return _ubah("posisi_desktop", _bersihkan_posisi(posisi))

static func reset_posisi_desktop() -> bool:
	return set_posisi_desktop({})
