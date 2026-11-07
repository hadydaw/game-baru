class_name WiresharkModel
extends RefCounted

# Keadaan satu sesi Wireshark: paket yang dibuka atau ditangkap, filter tampilan, paket terpilih, dan
# status capture simulasi. Dipakai bersama oleh aplikasi jendela (ui/wireshark_app.gd) dan tshark.
# Capture hanya memutar skenario simulasi per paket; tidak ada paket sungguhan yang dibaca dari perangkat.

var paket: Array = []          # semua paket sesi (urutan asli, nomor = field "no")
var judul := ""
var antarmuka := ""
var filter_teks := ""
var filter_galat := ""
var tampil: Array = []         # indeks ke paket yang lolos filter
var terpilih := -1             # indeks ke paket (bukan ke tampil); -1 bila belum ada yang dipilih
var menangkap := false
var _sumber: Array = []        # paket skenario capture yang belum diputar
var _node_filter: Dictionary = {}

func muat_berkas(data: Dictionary, nama_judul: String) -> void:
	paket = data.get("paket", []).duplicate()
	judul = nama_judul
	antarmuka = String(data.get("antarmuka", ""))
	menangkap = false
	_sumber = []
	terpilih = -1
	_bangun_tampil()

func mulai_tangkap(iface: String, skenario: Array) -> void:
	paket = []
	judul = "Capture %s" % iface
	antarmuka = iface
	_sumber = skenario
	menangkap = true
	terpilih = -1
	_bangun_tampil()

# Memutar satu paket dari skenario. Mengembalikan false bila skenario sudah habis.
func tangkap_satu() -> bool:
	if not menangkap or _sumber.is_empty():
		menangkap = false
		return false
	paket.append(_sumber.pop_front())
	_bangun_tampil()
	if _sumber.is_empty():
		menangkap = false
	return true

func berhenti_tangkap() -> void:
	menangkap = false
	_sumber = []

func sisa_tangkap() -> int:
	return _sumber.size()

# Mengembalikan galat ("" bila berhasil). Filter kosong menampilkan semua paket.
func terapkan_filter(teks: String) -> String:
	filter_teks = teks.strip_edges()
	filter_galat = ""
	if filter_teks == "":
		_node_filter = {}
	else:
		var r := WiresharkFilter.parse(filter_teks)
		if not bool(r["ok"]):
			filter_galat = Bahasa.pilih(String(r["pesan"]))
			_node_filter = {}
			_bangun_tampil()
			return filter_galat
		_node_filter = r["node"]
	_bangun_tampil()
	return ""

func _bangun_tampil() -> void:
	tampil = []
	for i in range(paket.size()):
		if _node_filter.is_empty() or WiresharkFilter.cocok(_node_filter, paket[i]):
			tampil.append(i)
	if terpilih >= paket.size():
		terpilih = -1

func pilih(indeks: int) -> void:
	terpilih = indeks if indeks >= 0 and indeks < paket.size() else -1

func paket_terpilih() -> Dictionary:
	return paket[terpilih] if terpilih >= 0 else {}

# Hanya paket yang tampil dihitung; hierarki dan percakapan mengikuti filter, seperti di Wireshark.
func paket_tampil() -> Array:
	var hasil: Array = []
	for i in tampil:
		hasil.append(paket[i])
	return hasil

func punya_paket() -> bool:
	return not paket.is_empty()

# Antarmuka yang bisa ditangkap sekarang. wlan0mon hanya ada bila monitor mode aktif.
static func antarmuka_tersedia(monitor: String) -> Array:
	var hasil := ["eth0"]
	if monitor != "":
		hasil.append(monitor)
	return hasil

static func skenario_untuk(iface: String, monitor: String) -> String:
	if iface == "eth0":
		return String(WiresharkData.SKENARIO_ANTARMUKA["eth0"])
	if monitor != "" and iface == monitor:
		return String(WiresharkData.SKENARIO_ANTARMUKA["wlan0mon"])
	return ""
