class_name Perangkat
extends RefCounted

# Perangkat keras pemain: komponen yang dimiliki, perakitan, antena, dan koneksi.
# Data komponen dibaca dari data/hardware/komponen.json. Semua perubahan lewat metode di kelas ini.
# Hasil metode berupa Dictionary {ok, kunci, args}; kunci adalah teks bahasa (Bahasa.t) yang ditampilkan.

const DATA := "res://data/hardware/komponen.json"
const ID_KIT := "wifi_hacking_kit"

var komponen: Dictionary = {}   # id komponen -> jumlah yang dimiliki
var rakitan: Dictionary = {}    # kosong = belum dirakit; isi: {adapter, antena, terhubung, driver}

static func data(path: String = DATA) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

static func info(id: String) -> Dictionary:
	var d := Dictionary(Dictionary(data().get("komponen", {})).get(id, {})).duplicate()
	# Nama komponen tampil dalam dua bahasa; sisanya (harga, chipset, tipe) tidak berubah.
	if d.has("nama"):
		d["nama"] = Bahasa.dua(String(d["nama"]), String(d.get("nama_en", d["nama"])))
	return d

static func semua_id() -> Array:
	var ids := Dictionary(data().get("komponen", {})).keys()
	ids.sort()
	return ids

static func chipset_adapter(id: String) -> String:
	return String(info(id).get("chipset", ""))

func jumlah(id: String) -> int:
	return int(komponen.get(id, 0))

func punya(id: String) -> bool:
	return jumlah(id) > 0

func tambah(id: String, n: int = 1) -> void:
	komponen[id] = jumlah(id) + n

func kurangi(id: String, n: int = 1) -> void:
	var sisa := jumlah(id) - n
	if sisa <= 0:
		komponen.erase(id)
	else:
		komponen[id] = sisa

func sudah_dirakit() -> bool:
	return not rakitan.is_empty()

func adapter() -> String:
	return String(rakitan.get("adapter", ""))

func antena() -> int:
	return int(rakitan.get("antena", 0))

func terhubung() -> bool:
	return bool(rakitan.get("terhubung", false))

# Semua komponen yang dimiliki: yang masih di inventaris dan yang sudah dirakit.
# Komponen yang dirakit tetap dihitung agar Device Manager dan Inventaris tidak kehilangan barang.
func dimiliki_dan_terpasang() -> Dictionary:
	var hasil := komponen.duplicate()
	if sudah_dirakit():
		hasil[adapter()] = int(hasil.get(adapter(), 0)) + 1
		var antena_id := "antena_penguat" if antena() >= 2 else "antena_eksternal"
		hasil[antena_id] = int(hasil.get(antena_id, 0)) + 1
	return hasil

func driver_aktif() -> String:
	return String(rakitan.get("driver", ""))

# Daftar adapter yang dimiliki, diurutkan.
func adapter_dimiliki() -> Array:
	var hasil: Array = []
	for id in komponen:
		if String(info(String(id)).get("tipe", "")) == "adapter":
			hasil.append(String(id))
	hasil.sort()
	return hasil

func beli(id: String, ekonomi: Economy) -> Dictionary:
	var it := info(id)
	if it.is_empty() or bool(it.get("tidak_dijual", false)):
		return _gagal("hw.tidak_dijual", [id])
	var harga := int(it["harga"])
	if not ekonomi.bisa_bayar(harga):
		return _gagal("hw.saldo_kurang", [harga, ekonomi.saldo])
	ekonomi.bayar(harga)
	tambah(id)
	return _ok("hw.dibeli", [String(it["nama"]), harga])

# Merakit adapter, antena eksternal, dan kabel USB menjadi satu perangkat.
# Adapter bisa dipilih lewat argumen; bila kosong dipakai adapter pertama yang dimiliki.
func rakit(pilih: String = "") -> Dictionary:
	if sudah_dirakit():
		return _gagal("hw.sudah_dirakit", [])
	var daftar_adapter := adapter_dimiliki()
	var adp: String = pilih if pilih != "" else (String(daftar_adapter[0]) if not daftar_adapter.is_empty() else "")
	if adp == "" or not punya(adp) or String(info(adp).get("tipe", "")) != "adapter":
		return _gagal("hw.adapter_kurang", [])
	if not punya("antena_eksternal"):
		return _gagal("hw.antena_kurang", [])
	if not punya("kabel_usb"):
		return _gagal("hw.kabel_kurang", [])
	kurangi(adp)
	kurangi("antena_eksternal")
	kurangi("kabel_usb")
	rakitan = {"adapter": adp, "antena": 1, "terhubung": false, "driver": ""}
	return _ok("hw.dirakit", [String(info(adp)["nama"])])

# Meningkatkan antena perangkat yang sudah dirakit dengan Antena Penguat.
func upgrade_antena() -> Dictionary:
	if not sudah_dirakit():
		return _gagal("hw.belum_dirakit", [])
	if antena() >= 2:
		return _gagal("hw.antena_sudah_maks", [])
	if not punya("antena_penguat"):
		return _gagal("hw.antena_penguat_kurang", [])
	kurangi("antena_penguat")
	rakitan["antena"] = 2
	return _ok("hw.antena_naik", [])

# Menghubungkan perangkat. Driver harus terpasang dari Tools Repository dan mendukung chipset adapter.
func hubungkan(driver_id: String, chipset_didukung: Array) -> Dictionary:
	if not sudah_dirakit():
		return _gagal("hw.belum_dirakit", [])
	if terhubung():
		return _gagal("hw.sudah_terhubung", [])
	if driver_id == "":
		return _gagal("hw.driver_kurang", [])
	if not chipset_didukung.has(chipset_adapter(adapter())):
		return _gagal("hw.chipset_tidak_cocok", [chipset_adapter(adapter())])
	rakitan["terhubung"] = true
	rakitan["driver"] = driver_id
	return _ok("hw.terhubung", [driver_id])

func putuskan() -> Dictionary:
	if not terhubung():
		return _gagal("hw.belum_terhubung", [])
	rakitan["terhubung"] = false
	return _ok("hw.terputus", [])

# Wi-Fi Hacking Kit dari misi: masuk inventaris, dan antena perangkat yang sudah dirakit ikut naik.
func terima_kit() -> void:
	tambah(ID_KIT)
	if sudah_dirakit() and antena() < 2:
		rakitan["antena"] = 2

func _ok(kunci: String, args: Array) -> Dictionary:
	return {"ok": true, "kunci": kunci, "args": args}

func _gagal(kunci: String, args: Array) -> Dictionary:
	return {"ok": false, "kunci": kunci, "args": args}

func to_dict() -> Dictionary:
	return {"komponen": komponen.duplicate(), "rakitan": rakitan.duplicate()}

func terapkan(d: Dictionary) -> void:
	komponen = {}
	var k: Dictionary = d.get("komponen", {})
	for id in k:
		if not info(String(id)).is_empty():
			komponen[String(id)] = maxi(int(k[id]), 0)
	rakitan = {}
	var r: Dictionary = d.get("rakitan", {})
	if not r.is_empty() and not info(String(r.get("adapter", ""))).is_empty():
		rakitan = {
			"adapter": String(r["adapter"]),
			"antena": clampi(int(r.get("antena", 1)), 1, 2),
			"terhubung": bool(r.get("terhubung", false)),
			"driver": String(r.get("driver", "")),
		}
