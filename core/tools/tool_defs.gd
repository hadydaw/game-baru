class_name ToolDefs
extends RefCounted

# Definisi tool sebagai data. Efeknya dihitung oleh core simulator (ShellCommands, ToolCommands,
# PerintahJaringan), bukan menjalankan kode sistem. Harga per tingkat dalam Kr.

const DEFS := {
	"network_scanner": {
		"nama": "Network Scanner", "kategori": "Pemindaian", "maks": 3,
		"harga": {1: 350, 2: 900, 3: 2200}, "perintah": [],
	},
	"packet_inspector": {
		"nama": "Packet Inspector", "kategori": "Lalu lintas", "maks": 3,
		"harga": {1: 400, 2: 1000, 3: 2500}, "perintah": ["inspeksi"],
	},
	"signal_tracer": {
		"nama": "Signal Tracer", "kategori": "Pelacakan", "maks": 3,
		"harga": {1: 450, 2: 1100, 3: 2800}, "perintah": ["trace"],
	},
	"password_analyzer": {
		"nama": "Password Analyzer", "kategori": "Autentikasi", "maks": 3,
		"harga": {1: 300, 2: 800, 3: 1800}, "perintah": ["analyze"],
	},
	"crypt_decoder": {
		"nama": "Crypt Decoder", "kategori": "Berkas", "maks": 3,
		"harga": {1: 500, 2: 1200, 3: 3000}, "perintah": ["decode"],
	},
	"firewall_bypass": {
		"nama": "Firewall Bypass", "kategori": "Akses", "maks": 3,
		"harga": {1: 400, 2: 1000, 3: 2600}, "perintah": [],
	},
}

static func ada(id: String) -> bool:
	return DEFS.has(id)

static func nama(id: String) -> String:
	return String(DEFS.get(id, {}).get("nama", id))

static func maks(id: String) -> int:
	return int(DEFS.get(id, {}).get("maks", 0))

static func harga(id: String, tingkat: int) -> int:
	var h: Dictionary = DEFS.get(id, {}).get("harga", {})
	return int(h.get(tingkat, 0))

static func perintah(id: String) -> Array:
	return Array(DEFS.get(id, {}).get("perintah", []))
