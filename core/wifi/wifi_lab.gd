class_name WifiLab
extends RefCounted

# Jaringan Wi-Fi laboratorium simulasi: jaringan fiktif dengan konfigurasi dan kelemahan yang dirancang
# untuk gameplay. Data dibaca dari data/wifi/lab.json. Setiap tahap hanya bisa dijalankan
# bila tahap sebelumnya sudah dilakukan untuk jaringan yang sama.

const DATA := "res://data/wifi/lab.json"

var ditemukan: Array = []                # SSID hasil airodump-ng wlan0mon
var terpilih: String = ""                # SSID target hasil airodump-ng --bssid
var dianalisis: Dictionary = {}          # SSID -> true (security analyze)
var handshake: Dictionary = {}           # SSID -> true (audit auth)
var kata_sandi_ditemukan: Dictionary = {}  # SSID -> kata sandi hasil audit run
var terakses: Dictionary = {}            # SSID -> true (security verify)
var riwayat: Array = []                  # tiap pemindaian, terbaru di depan: {waktu, perangkat, jumlah, jaringan, dipilih, analisis}
var waktu_lihat: Dictionary = {}         # SSID -> waktu terakhir ditemukan oleh pemindaian
var monitor: String = ""                 # nama interface monitor hasil airmon-ng start (kosong bila belum aktif)

const BATAS_RIWAYAT := 50

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
		"terakses": terakses.duplicate(true),
		"riwayat": riwayat.duplicate(true),
		"waktu_lihat": waktu_lihat.duplicate(),
		"monitor": monitor,
	}

func terapkan(d: Dictionary) -> void:
	ditemukan = Array(d.get("ditemukan", [])).duplicate()
	terpilih = String(d.get("terpilih", ""))
	dianalisis = Dictionary(d.get("dianalisis", {})).duplicate()
	handshake = Dictionary(d.get("handshake", {})).duplicate()
	kata_sandi_ditemukan = Dictionary(d.get("kata_sandi_ditemukan", {})).duplicate()
	terakses = Dictionary(d.get("terakses", {})).duplicate()
	riwayat = Array(d.get("riwayat", [])).duplicate(true)
	waktu_lihat = Dictionary(d.get("waktu_lihat", {})).duplicate()
	monitor = String(d.get("monitor", ""))

# Mencatat satu pemindaian ke riwayat. Entri terbaru ada di depan.
func catat_scan(perangkat_id: String, ssids: Array, waktu: String) -> void:
	riwayat.push_front({"waktu": waktu, "perangkat": perangkat_id, "jumlah": ssids.size(), "jaringan": ssids.duplicate(), "dipilih": "", "analisis": {}})
	while riwayat.size() > BATAS_RIWAYAT:
		riwayat.pop_back()
	for ssid in ssids:
		waktu_lihat[String(ssid)] = waktu

# Jaringan yang dipilih dicatat pada pemindaian terbaru yang memuatnya.
func catat_pilih(ssid: String) -> void:
	for e in riwayat:
		if Array(e["jaringan"]).has(ssid):
			e["dipilih"] = ssid
			return

# Hasil analisis dicatat pada semua pemindaian yang memuat jaringan itu.
func catat_analisis(ssid: String, tingkat: String) -> void:
	for e in riwayat:
		if Array(e["jaringan"]).has(ssid):
			e["analisis"][ssid] = tingkat

# Semua pemindaian yang pernah menemukan jaringan ini.
func riwayat_jaringan(ssid: String) -> Array:
	var hasil: Array = []
	for e in riwayat:
		if Array(e["jaringan"]).has(ssid):
			hasil.append(e)
	return hasil

# Frekuensi dari nomor kanal: kanal 1-14 berada di 2.4 GHz, selebihnya 5 GHz.
static func frekuensi(j: Dictionary) -> String:
	return "2.4 GHz" if int(j["kanal"]) <= 14 else "5 GHz"

# Batang sinyal 0-4 dari dBm, sama seperti yang dilihat pemain di aplikasi Wi-Fi sungguhan.
static func batang_sinyal(dbm: int) -> int:
	if dbm >= -50:
		return 4
	if dbm >= -60:
		return 3
	if dbm >= -70:
		return 2
	return 1

static func bar(dbm: int) -> String:
	var n := batang_sinyal(dbm)
	return "[" + "#".repeat(n) + "-".repeat(4 - n) + "]"

# Kelemahan jaringan dengan tingkat dan teks dua bahasa, dibaca dari data/wifi/lab.json.
static func kelemahan(ssid: String) -> Array:
	var hasil: Array = []
	var katalog := Dictionary(data().get("kelemahan", {}))
	for k in Array(jaringan(ssid).get("kelemahan", [])):
		var info := Dictionary(katalog.get(String(k), {}))
		if info.is_empty():
			continue
		var rek := Dictionary(info.get("rekomendasi", {}))
		hasil.append({"kunci": String(k), "tingkat": String(info["tingkat"]), "id": String(info["id"]), "en": String(info["en"]), "rek_id": String(rek.get("id", "")), "rek_en": String(rek.get("en", ""))})
	return hasil

# Tingkat risiko keseluruhan: tertinggi dari kelemahan yang ditemukan.
static func tingkat_risiko(ssid: String) -> String:
	var urut := {"rendah": 0, "sedang": 1, "tinggi": 2}
	var hasil := "rendah"
	for k in kelemahan(ssid):
		if int(urut.get(String(k["tingkat"]), 0)) > int(urut.get(hasil, 0)):
			hasil = String(k["tingkat"])
	return hasil

# Driver dan nama chipset yang ditampilkan airmon-ng untuk adapter tertentu.
static func airmon_info(chipset: String) -> Dictionary:
	return Dictionary(Dictionary(data().get("airmon", {})).get(chipset, {})).duplicate()

static func ambang_handshake() -> int:
	return int(data().get("ambang_handshake_dbm", -65))

# Adapter dengan chipset yang mendukung monitor mode dibutuhkan untuk menangkap handshake.
static func mendukung_monitor(chipset: String) -> bool:
	return bool(Dictionary(data().get("monitor_mode", {})).get(chipset, false))

# Label tingkat risiko dalam dua bahasa: [id, en].
static func tingkat_pair(tingkat: String) -> Array:
	match tingkat:
		"tinggi":
			return ["TINGGI", "HIGH"]
		"sedang":
			return ["SEDANG", "MEDIUM"]
	return ["RENDAH", "LOW"]
