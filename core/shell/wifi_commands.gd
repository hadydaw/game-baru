class_name WifiCommands
extends RefCounted

# Perintah pengujian Wi-Fi laboratorium: wifi-scanner --scan, network list|inspect,
# security analyze|verify, dan audit auth|run. Setiap perintah memeriksa tahap sebelumnya,
# perangkat yang terpasang, dan data yang dihasilkannya (WifiLab). Tidak ada perintah yang
# langsung memberi akses: kata sandi harus ditemukan lewat audit lalu diverifikasi.

# dBm yang ditambahkan tiap tingkat antena ke sinyal yang sampai ke adapter.
const BONUS_ANTENA_DBM := 5

static func scan(s: ShellSession, p: Dictionary) -> Array:
	if not s.perangkat.terhubung():
		return [s.galat_kunci("wifi-scanner", "hw.belum_terhubung")]
	if not ShellParser.punya_opsi(p["opsi"], "--scan"):
		return [s.galat_kunci("wifi-scanner", "wifi.usage_scan")]
	var ssids := Dictionary(WifiLab.data().get("jaringan", {})).keys()
	ssids.sort()
	s.wifi.ditemukan = []
	var waktu := Time.get_datetime_string_from_system().substr(0, 16).replace("T", " ")
	var hasil: Array = [s.baris_kunci("info", "wifi.judul_scan")]
	hasil.append(s.baris("info", "BSSID              CH   SINYAL          ENK    SSID"))
	for ssid in ssids:
		var j := WifiLab.jaringan(String(ssid))
		s.wifi.ditemukan.append(String(ssid))
		var dbm := int(j["sinyal"])
		hasil.append(s.baris("info", "%-17s  %3d  %s %4d dBm  %-5s  %s" % [String(j["bssid"]), int(j["kanal"]), WifiLab.bar(dbm), dbm, String(j["enkripsi"]), String(ssid)]))
	hasil.append(s.baris("info", Bahasa.dua("%d jaringan ditemukan. Gunakan 'network inspect <SSID>' untuk detail.", "%d networks found. Use 'network inspect <SSID>' for details.", [ssids.size()])))
	s.wifi.catat_scan(s.perangkat.adapter(), ssids, waktu)
	_catat(s, "wifi-scanner --scan: %d networks [%s]" % [ssids.size(), ", ".join(PackedStringArray(ssids))])
	s.jaringan.buka("wifi:scan")
	return hasil

static func network(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.is_empty():
		return [s.galat_kunci("network", "wifi.usage_network")]
	match String(args[0]):
		"list":
			if not s.wifi.sudah_scan():
				return [s.galat_kunci("network", "wifi.belum_scan")]
			var hasil: Array = [s.baris_kunci("info", "wifi.judul_list")]
			for ssid in s.wifi.ditemukan:
				var j := WifiLab.jaringan(String(ssid))
				hasil.append(s.baris("info", "  %-12s %s  %s  %s" % [String(ssid), WifiLab.bar(int(j["sinyal"])), String(j["enkripsi"]), String(j["vendor"])]))
			return hasil
		"inspect":
			if args.size() < 2:
				return [s.galat_kunci("network", "err.butuh_argumen")]
			var ssid := String(args[1])
			if not s.wifi.sudah_scan():
				return [s.galat_kunci("network", "wifi.belum_scan")]
			if not s.wifi.terlihat(ssid):
				return [s.galat_kunci("network", "wifi.tidak_terlihat", [ssid])]
			var j := WifiLab.jaringan(ssid)
			s.wifi.terpilih = ssid
			s.wifi.catat_pilih(ssid)
			_catat(s, "network inspect %s: bssid=%s channel=%d signal=%d enc=%s wps=%s clients=%d" % [ssid, String(j["bssid"]), int(j["kanal"]), int(j["sinyal"]), String(j["enkripsi"]), str(bool(j["wps"])), int(j["klien"])])
			s.jaringan.buka("wifi:pilih:" + ssid)
			return [
				s.baris_kunci("info", "wifi.judul_inspect", [ssid]),
				s.baris("info", _kv("BSSID", "BSSID", String(j["bssid"]), String(j["bssid"]))),
				s.baris("info", _kv("Vendor", "Vendor", "%s %s" % [String(j["vendor"]), String(j["model"])], "%s %s" % [String(j["vendor"]), String(j["model"])])),
				s.baris("info", _kv("Kanal", "Channel", "%d (%s, %d MHz)" % [int(j["kanal"]), WifiLab.frekuensi(j), int(j["lebar_kanal"])], "%d (%s, %d MHz)" % [int(j["kanal"]), WifiLab.frekuensi(j), int(j["lebar_kanal"])])),
				s.baris("info", _kv("Sinyal", "Signal", "%d dBm %s" % [int(j["sinyal"]), WifiLab.bar(int(j["sinyal"]))], "%d dBm %s" % [int(j["sinyal"]), WifiLab.bar(int(j["sinyal"]))])),
				s.baris("info", _kv("Enkripsi", "Encryption", String(j["enkripsi"]), String(j["enkripsi"]))),
				s.baris("info", _kv("WPS", "WPS", "aktif" if bool(j["wps"]) else "nonaktif", "enabled" if bool(j["wps"]) else "disabled")),
				s.baris("info", _kv("Klien", "Clients", str(int(j["klien"])), str(int(j["klien"])))),
			]
	return [s.galat_kunci("network", "wifi.usage_network")]

# Baris "label: nilai" dalam kolom yang rapi, dengan label dan nilai untuk masing-masing bahasa.
static func _kv(id: String, en: String, nilai_id: String, nilai_en: String) -> String:
	return Bahasa.dua("  %-12s %s" % [id + ":", nilai_id], "  %-12s %s" % [en + ":", nilai_en])

static func security(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.is_empty():
		return [s.galat_kunci("security", "wifi.usage_security")]
	match String(args[0]):
		"report":
			if args.size() < 2:
				return [s.galat_kunci("security", "err.butuh_argumen")]
			var ssid := String(args[1])
			if not s.wifi.dianalisis.has(ssid):
				return [s.baris("error", Bahasa.dua("security report: jalankan 'security analyze %s' dulu." % ssid, "security report: run 'security analyze %s' first." % ssid))]
			var path := "%s/laporan/%s.txt" % [s.home, ssid]
			s.tulis_berkas(path, _laporan(s, ssid))
			_catat(s, "security report %s: saved to %s" % [ssid, path])
			return [s.baris("info", Bahasa.dua("Laporan disimpan di %s" % path, "Report saved to %s" % path))]
		"analyze":
			if args.size() < 2:
				return [s.galat_kunci("security", "err.butuh_argumen")]
			var ssid := String(args[1])
			if s.wifi.terpilih != ssid:
				return [s.galat_kunci("security", "wifi.belum_dipilih")]
			var j := WifiLab.jaringan(ssid)
			var enkripsi := String(j["enkripsi"])
			s.wifi.dianalisis[ssid] = true
			s.wifi.catat_analisis(ssid, WifiLab.tingkat_risiko(ssid))
			s.jaringan.buka("wifi:analisis:" + ssid)
			var hasil: Array = [
				s.baris_kunci("info", "wifi.analisis_judul", [ssid]),
				s.baris_kunci("info", "wifi.analisis_" + enkripsi.to_lower(), []),
			]
			var daftar := WifiLab.kelemahan(ssid)
			_catat(s, "security analyze %s: risk=%s findings=%d" % [ssid, WifiLab.tingkat_pair(WifiLab.tingkat_risiko(ssid))[1], daftar.size()])
			if daftar.is_empty():
				hasil.append(s.baris("info", Bahasa.dua("  Tidak ditemukan kelemahan utama.", "  No major weakness found.")))
			for k in daftar:
				var t := WifiLab.tingkat_pair(String(k["tingkat"]))
				hasil.append(s.baris("info", Bahasa.dua("  [%s] %s" % [t[0], String(k["id"])], "  [%s] %s" % [t[1], String(k["en"])])))
			var r := WifiLab.tingkat_pair(WifiLab.tingkat_risiko(ssid))
			hasil.append(s.baris("info", Bahasa.dua("  Tingkat risiko: %s" % r[0], "  Risk level: %s" % r[1])))
			return hasil
		"verify":
			if args.size() < 3:
				return [s.galat_kunci("security", "err.butuh_argumen")]
			var ssid := String(args[1])
			var kata := String(args[2])
			if not s.wifi.kata_sandi_ditemukan.has(ssid):
				return [s.galat_kunci("security", "wifi.belum_audit")]
			if String(s.wifi.kata_sandi_ditemukan[ssid]) != kata:
				_catat(s, "security verify %s: REJECTED" % ssid)
				return [s.galat_kunci("security", "wifi.kata_sandi_salah", [ssid])]
			s.wifi.terakses[ssid] = true
			_catat(s, "security verify %s: ACCEPTED, lab access granted" % ssid)
			s.jaringan.buka("wifi:akses:" + ssid)
			return [s.baris_kunci("info", "wifi.akses", [ssid])]
	return [s.galat_kunci("security", "wifi.usage_security")]

static func audit(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.size() < 2:
		return [s.galat_kunci("audit", "wifi.usage_audit")]
	var ssid := String(args[1])
	match String(args[0]):
		"auth":
			if not s.wifi.dianalisis.has(ssid):
				return [s.galat_kunci("audit", "wifi.belum_analisis")]
			var j := WifiLab.jaringan(ssid)
			var chipset := Perangkat.chipset_adapter(s.perangkat.adapter())
			if not WifiLab.mendukung_monitor(chipset):
				_catat(s, "audit auth %s: FAILED adapter chipset %s has no monitor mode" % [ssid, chipset])
				return [s.baris("error", Bahasa.dua("audit auth: adapter %s tidak mendukung monitor mode, handshake tidak bisa ditangkap.", "audit auth: adapter %s does not support monitor mode, the handshake cannot be captured.", [chipset]))]
			var sinyal_efektif := int(j["sinyal"]) + _bonus_antena(s)
			if sinyal_efektif < WifiLab.ambang_handshake():
				_catat(s, "audit auth %s: FAILED effective signal %d dBm < threshold %d dBm" % [ssid, sinyal_efektif, WifiLab.ambang_handshake()])
				return [s.baris("error", Bahasa.dua("audit auth: handshake tidak lengkap. Sinyal efektif %d dBm di bawah ambang %d dBm. Tingkatkan antena atau dekatkan perangkat.", "audit auth: handshake incomplete. Effective signal %d dBm is below the %d dBm threshold. Upgrade the antenna or move closer.", [sinyal_efektif, WifiLab.ambang_handshake()]))]
			s.wifi.handshake[ssid] = true
			_catat(s, "audit auth %s: handshake captured (signal %d dBm)" % [ssid, sinyal_efektif])
			s.jaringan.buka("wifi:auth:" + ssid)
			var enkripsi := String(j["enkripsi"])
			var kunci := "wifi.handshake_wpa" if enkripsi == "WPA2" else "wifi.iv_wep"
			return [s.baris_kunci("info", kunci, [ssid])]
		"run":
			if not s.wifi.handshake.has(ssid):
				return [s.galat_kunci("audit", "wifi.belum_auth")]
			var kata := String(WifiLab.jaringan(ssid)["kata_sandi"])
			if not WifiLab.kamus().has(kata):
				_catat(s, "audit run %s: NOT FOUND in dictionary (%d words tried)" % [ssid, WifiLab.kamus().size()])
				return [s.baris_kunci("error", "wifi.tidak_ada_kamus", [])]
			s.wifi.kata_sandi_ditemukan[ssid] = kata
			_catat(s, "audit run %s: key recovered from dictionary (%d words tried), strength=weak" % [ssid, WifiLab.kamus().size()])
			s.jaringan.buka("wifi:audit:" + ssid)
			return [s.baris_kunci("info", "wifi.kunci_ditemukan", [ssid, kata])]
	return [s.galat_kunci("audit", "wifi.usage_audit")]

static func _bonus_antena(s: ShellSession) -> int:
	return s.perangkat.antena() * BONUS_ANTENA_DBM

# Catatan proses ke log pemain: ~/log/wifi.log. Teks log berbahasa Inggris seperti log alat sungguhan.
static func _catat(s: ShellSession, teks: String) -> void:
	s.tulis_berkas("%s/log/wifi.log" % s.home, "%s %s" % [Time.get_time_string_from_system(), teks], true)

# Satu teks dalam bahasa aktif, untuk isi berkas yang disimpan sebagai teks biasa.
static func _l(id: String, en: String) -> String:
	return Bahasa.pilih(Bahasa.dua(id, en))

# Laporan temuan: target, kelemahan, tingkat risiko, rekomendasi, dan status akses lab.
static func _laporan(s: ShellSession, ssid: String) -> String:
	var j := WifiLab.jaringan(ssid)
	var risiko := WifiLab.tingkat_pair(WifiLab.tingkat_risiko(ssid))
	var daftar := WifiLab.kelemahan(ssid)
	var baris: Array = [
		_l("LAPORAN TEMUAN KEAMANAN WI-FI", "WI-FI SECURITY FINDINGS REPORT"),
		"",
		"%s: %s %s" % [_l("Target", "Target"), ssid, _l("(laboratorium fiktif)", "(fictional lab)")],
		"BSSID: %s" % String(j["bssid"]),
		"Vendor: %s %s" % [String(j["vendor"]), String(j["model"])],
		"%s: %s" % [_l("Enkripsi", "Encryption"), String(j["enkripsi"])],
		"WPS: %s" % (_l("aktif", "enabled") if bool(j["wps"]) else _l("nonaktif", "disabled")),
		"%s: %d" % [_l("Klien terdeteksi", "Clients detected"), int(j["klien"])],
		"",
		"%s: %s" % [_l("Tingkat risiko keseluruhan", "Overall risk level"), _l(risiko[0], risiko[1])],
		"",
		_l("Temuan:", "Findings:"),
	]
	if daftar.is_empty():
		baris.append("- " + _l("Tidak ada temuan utama.", "No major findings."))
	for k in daftar:
		var t := WifiLab.tingkat_pair(String(k["tingkat"]))
		baris.append("- [%s] %s" % [_l(t[0], t[1]), _l(String(k["id"]), String(k["en"]))])
	baris.append("")
	baris.append(_l("Rekomendasi:", "Recommendations:"))
	if daftar.is_empty():
		baris.append("- " + _l("Pertahankan konfigurasi saat ini.", "Keep the current configuration."))
	for k in daftar:
		baris.append("- " + _l(String(k["rek_id"]), String(k["rek_en"])))
	baris.append("")
	baris.append("%s: %s" % [_l("Status akses lab", "Lab access status"), _l("terverifikasi", "verified") if s.wifi.terakses.has(ssid) else _l("belum diverifikasi", "not verified")])
	baris.append("%s: %s, %s" % [_l("Dibuat oleh", "Created by"), s.user, Time.get_date_string_from_system()])
	return "\n".join(PackedStringArray(baris))

