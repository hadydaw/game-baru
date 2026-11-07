class_name WiresharkData
extends RefCounted

# Data paket Wireshark. Semua paket di sini hasil simulasi internal (lihat tools/gen_wireshark.py).
# Tidak ada lalu lintas jaringan sungguhan yang ditangkap atau dibaca. Berkas .simcap buatan pemain
# adalah JSON sederhana berformat simcap-1; isinya disalin dari sesi capture simulasi.

const FORMAT := "simcap-1"
const DIR_CONTOH := "res://data/wireshark/"
const DIR_SAMPEL := "/usr/share/wireshark/samples/"
const EKSTENSI := ".simcap"
const CONTOH := ["lab-jaringan-umum", "lab-wifi-01-handshake", "lab-pindai-port", "lab-jejak-internal"]
# Antarmuka simulasi -> skenario yang diputar saat menangkap. wlan0mon hanya ada setelah monitor mode aktif.
const SKENARIO_ANTARMUKA := {"eth0": "lab-jaringan-umum", "wlan0mon": "lab-wifi-01-handshake"}

static func muat_contoh(id: String) -> Dictionary:
	if not CONTOH.has(id):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(DIR_CONTOH + id + ".json")) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

static func path_contoh(id: String) -> String:
	return DIR_SAMPEL + id + EKSTENSI

# Berkas contoh dibaca langsung dari path ini tanpa disalin ke sistem berkas pemain.
static func id_contoh_dari_path(abs_path: String) -> String:
	if not abs_path.begins_with(DIR_SAMPEL) or not abs_path.ends_with(EKSTENSI):
		return ""
	var id := abs_path.substr(DIR_SAMPEL.length(), abs_path.length() - DIR_SAMPEL.length() - EKSTENSI.length())
	return id if CONTOH.has(id) else ""

# Mengurai teks berkas. Mengembalikan {"ok", "judul", "antarmuka", "paket"}; ok=false bila rusak.
static func urai(teks: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(teks) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false}
	var d: Dictionary = parser.data
	if String(d.get("format", "")) != FORMAT or typeof(d.get("paket")) != TYPE_ARRAY:
		return {"ok": false}
	for p in d["paket"]:
		if typeof(p) != TYPE_DICTIONARY or not p.has("hex") or not p.has("rincian") or not p.has("fitur"):
			return {"ok": false}
	return {"ok": true, "judul": String(d.get("judul", "")), "antarmuka": String(d.get("antarmuka", "")), "paket": d["paket"]}

static func teks_simpan(judul: String, antarmuka: String, paket: Array) -> String:
	return JSON.stringify({"format": FORMAT, "simulasi": true, "judul": judul, "antarmuka": antarmuka, "paket": paket})

static func hex_ke_byte(hex: String) -> PackedByteArray:
	var b := PackedByteArray()
	for i in range(0, hex.length() - 1, 2):
		b.append(hex.substr(i, 2).hex_to_int())
	return b
