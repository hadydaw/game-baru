class_name PerintahScan
extends RefCounted

# Perintah scan: mengidentifikasi perangkat berdasarkan alamat IP. Hanya menemukan dan
# menampilkan identitas. Tidak memeriksa port (nmap), tidak menguji koneksi (ping), dan tidak
# membuka akses SSH. Node khusus misi hanya terbuka lewat perintah ini.

static func scan(s: ShellSession, p: Dictionary) -> Array:
	if p["argumen"].is_empty():
		return [s.galat("scan", Teks.t("err.butuh_argumen"))]
	var ip := String(p["argumen"][0])
	if not ip_valid(ip):
		return [s.galat("scan", "masukkan alamat IP, contoh: scan 10.7.0.8")]
	var j := s.jaringan
	var id := j.cari_ip(ip)
	if id == "":
		return [s.galat("scan", "Tidak ada perangkat yang ditemukan pada %s" % ip)]
	var keadaan := TataLetakPeta.keadaan(j.ringkasan(id))
	j.tandai_ditemukan(id)
	j.buka("pindai:" + id)
	return [
		s.baris("info", "Memindai %s..." % ip),
		s.baris("info", "Perangkat ditemukan: %s" % id),
		s.baris("info", "IP      : %s" % ip),
		s.baris("info", "Status  : %s" % _label_keadaan(keadaan)),
	]

static func ip_valid(teks: String) -> bool:
	var re := RegEx.new()
	re.compile("^\\d{1,3}(\\.\\d{1,3}){3}$")
	return re.search(teks) != null

static func _label_keadaan(keadaan: String) -> String:
	match keadaan:
		"aktif":
			return "Aktif"
		"tidak_aktif":
			return "Tidak aktif"
		_:
			return "Terkunci"

# Simpanan lama: node yang sudah ada di daftar ditemukan (lewat tetangga sebelum fitur scan)
# dianggap sudah dipindai, agar objektif scan tidak macet. Idempoten dan tidak mengubah data lain.
static func migrasi(s: ShellSession) -> void:
	var j := s.jaringan
	for id in j.data.keys():
		var nama := String(id)
		if not j.butuh_scan(nama):
			continue
		# Akses yang sudah tercatat (ssh atau baca) membuktikan node pernah dijangkau.
		if _sudah_dijangkau(j, nama):
			j.tandai_ditemukan(nama)
		if j.dikenal(nama):
			j.buka("pindai:" + nama)

static func _sudah_dijangkau(j: Jaringan, nama: String) -> bool:
	for k in j.progres:
		var kunci := String(k)
		if kunci == "ssh:" + nama or kunci.begins_with("baca:" + nama + ":"):
			return true
	return false
