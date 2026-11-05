class_name WifiLab
extends RefCounted

# Jaringan Wi-Fi laboratorium simulasi: jaringan fiktif dengan konfigurasi dan kelemahan yang dirancang
# untuk gameplay. Data dibaca dari data/wifi/lab.json. Setiap tahap hanya bisa dijalankan
# bila tahap sebelumnya sudah dilakukan untuk jaringan yang sama.

const DATA := "res://data/wifi/lab.json"

var ditemukan: Array = []                # SSID hasil wifi-scanner --scan
var terpilih: String = ""                # SSID hasil network inspect
var dianalisis: Dictionary = {}          # SSID -> true (security analyze)
var handshake: Dictionary = {}           # SSID -> true (audit auth)
var kata_sandi_ditemukan: Dictionary = {}  # SSID -> kata sandi hasil audit run
var terakses: Dictionary = {}            # SSID -> true (security verify)

static func data(path: String = DATA) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

static func jaringan(ssid: String) -> Dictionary:
	return Dictionary(Dictionary(data().get("jaringan", {})).get(ssid, {})).duplicate()

static func kamus() -> Array:
	return Array(data().get("kamus_audit", []))

func sudah_scan() -> bool:
	return not ditemukan.is_empty()

func terlihat(ssid: String) -> bool:
	return ditemukan.has(ssid)

func to_dict() -> Dictionary:
	return {
		"ditemukan": ditemukan.duplicate(),
		"terpilih": terpilih,
		"dianalisis": dianalisis.duplicate(),
		"handshake": handshake.duplicate(),
		"kata_sandi_ditemukan": kata_sandi_ditemukan.duplicate(),
		"terakses": terakses.duplicate(),
	}

func terapkan(d: Dictionary) -> void:
	ditemukan = Array(d.get("ditemukan", [])).duplicate()
	terpilih = String(d.get("terpilih", ""))
	dianalisis = Dictionary(d.get("dianalisis", {})).duplicate()
	handshake = Dictionary(d.get("handshake", {})).duplicate()
	kata_sandi_ditemukan = Dictionary(d.get("kata_sandi_ditemukan", {})).duplicate()
	terakses = Dictionary(d.get("terakses", {})).duplicate()
