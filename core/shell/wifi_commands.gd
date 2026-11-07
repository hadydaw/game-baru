class_name WifiCommands
extends RefCounted

# Perintah pengujian Wi-Fi laboratorium: airmon-ng (monitor mode), airodump-ng (pemindaian dan pemilihan target),
# network-analyzer analyze|verify, dan password-auditor auth|run. Setiap perintah memeriksa tahap sebelumnya,
# perangkat yang terpasang, dan data yang dihasilkannya (WifiLab). Tidak ada perintah yang
# langsung memberi akses: kata sandi harus ditemukan lewat audit lalu diverifikasi.

# dBm yang ditambahkan tiap tingkat antena ke sinyal yang sampai ke adapter.
const BONUS_ANTENA_DBM := 5

# Opsi airodump-ng yang membutuhkan nilai (sintaks resmi aircrack-ng).
const OPSI_BERNILAI := ["-c", "--channel", "-d", "--bssid", "-t", "--encrypt", "-N", "--essid", "-w", "--write", "-u", "--update"]
const ENKRIPSI_VALID := ["OPN", "WEP", "WPA", "WPA1", "WPA2", "WPA3", "OWE"]
# Kanal yang dipindai airodump-ng bila -c tidak diberikan (2.4 GHz, mode berpindah kanal).
const KANAL_DEFAULT := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
# Di bawah lebar ini (karakter), tabel AP dan station ditampilkan ringkas agar muat di layar HP.
const LEBAR_TABEL_PENUH := 92
const HEADER_AP := " BSSID              PWR RXQ  Beacons    #Data, #/s  CH  MB   ENC  CIPHER AUTH ESSID"
const HEADER_STATION := " BSSID              STATION            PWR   Rate    Lost    Frames  Notes  Probes"

# airmon-ng start|stop <interface>. Monitor mode hanya bisa diaktifkan pada adapter yang driver-nya
# mendukungnya. Interface yang dihasilkan adalah <interface>mon, dan nama itu yang dipakai airodump-ng.
static func airmon(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = ShellParser.tokenkan(String(p["mentah"])).slice(1)
	if args.size() < 2 or not (String(args[0]) == "start" or String(args[0]) == "stop"):
		return [s.galat_kunci("airmon-ng", "wifi.usage_airmon")]
	var aksi := String(args[0])
	var iface := String(args[1])
	if not s.perangkat.terhubung():
		return [s.galat_kunci("airmon-ng", "hw.belum_terhubung")]
	var chipset := Perangkat.chipset_adapter(s.perangkat.adapter())
	var info := WifiLab.airmon_info(chipset)
	var driver := String(info.get("driver", ""))
	var nama_chipset := String(info.get("nama_chipset", chipset))
	if aksi == "start":
		if iface != "wlan0":
			return [s.galat_kunci("airmon-ng", "wifi.iface_tidak_ada", [iface])]
		if s.wifi.monitor != "":
			return [s.galat_kunci("airmon-ng", "wifi.monitor_sudah", [s.wifi.monitor])]
		if not WifiLab.mendukung_monitor(chipset):
			return [s.galat_kunci("airmon-ng", "wifi.monitor_tidak_didukung", [driver])]
		var mon := iface + "mon"
		s.wifi.monitor = mon
		s.jaringan.buka("wifi:monitor")
		_catat(s, "airmon-ng start %s: monitor mode vif enabled for [phy0]%s on [phy0]%s" % [iface, iface, mon])
		return [
			s.baris("info", "PHY  Interface  Driver      Chipset"),
			s.baris("info", ""),
			s.baris("info", "phy0 %s %s %s" % [iface.rpad(9), driver.rpad(11), nama_chipset]),
			s.baris("info", "\t\t(mac80211 monitor mode vif enabled for [phy0]%s on [phy0]%s)" % [iface, mon]),
			s.baris("info", "\t\t(mac80211 station mode vif disabled for [phy0]%s)" % iface),
		]
	# stop: menerima nama interface monitor, bukan nama adapter.
	if s.wifi.monitor == "" or iface != s.wifi.monitor:
		return [s.galat_kunci("airmon-ng", "wifi.monitor_belum", [iface])]
	var mon_lama := s.wifi.monitor
	s.wifi.monitor = ""
	s.live_hentikan()
	_catat(s, "airmon-ng stop %s: monitor mode vif disabled for [phy0]%s" % [mon_lama, mon_lama])
	return [
		s.baris("info", "PHY  Interface  Driver      Chipset"),
		s.baris("info", ""),
		s.baris("info", "phy0 %s %s %s" % [mon_lama.rpad(9), driver.rpad(11), nama_chipset]),
		s.baris("info", "\t\t(mac80211 monitor mode vif disabled for [phy0]%s)" % mon_lama),
		s.baris("info", "\t\t(mac80211 station mode vif enabled for [phy0]%s)" % mon_lama.trim_suffix("mon")),
	]

# airodump-ng [opsi] <interface>. Sintaks dan opsi mengikuti aircrack-ng:
# -c/--channel (daftar dipisah koma), -d/--bssid, -t/--encrypt, -N/--essid (boleh berulang),
# -u/--update (detik), dan -w/--write. Interface harus interface monitor yang dibuat airmon-ng.
# Tanpa -c, airodump-ng berpindah kanal. Hanya Terminal yang memulai mode live.
static func airodump(s: ShellSession, p: Dictionary) -> Array:
	if not s.perangkat.terhubung():
		return [s.galat_kunci("airodump-ng", "hw.belum_terhubung")]
	var args: Array = ShellParser.tokenkan(String(p["mentah"])).slice(1)
	var saring := {"kanal": [], "bssid": "", "enkripsi": [], "essid": [], "tulis": "", "update": 1}
	var interface := ""
	var i := 0
	while i < args.size():
		var a := String(args[i])
		if a in OPSI_BERNILAI:
			if i + 1 >= args.size():
				return [s.galat_kunci("airodump-ng", "wifi.opsi_butuh_nilai", [a])]
			var nilai := String(args[i + 1])
			match a:
				"-c", "--channel":
					var daftar: Array = []
					for bagian in nilai.split(","):
						if not bagian.is_valid_int() or int(bagian) < 1:
							return [s.galat_kunci("airodump-ng", "wifi.kanal_salah", [nilai])]
						daftar.append(int(bagian))
					saring["kanal"] = daftar
				"-d", "--bssid":
					if not _bssid_valid(nilai):
						return [s.galat_kunci("airodump-ng", "wifi.bssid_salah", [nilai])]
					saring["bssid"] = nilai.to_upper()
				"-t", "--encrypt":
					if not ENKRIPSI_VALID.has(nilai.to_upper()):
						return [s.galat_kunci("airodump-ng", "wifi.enkripsi_salah", [nilai])]
					(saring["enkripsi"] as Array).append(nilai.to_upper())
				"-N", "--essid":
					(saring["essid"] as Array).append(nilai)
				"-u", "--update":
					if not nilai.is_valid_int() or int(nilai) < 1:
						return [s.galat_kunci("airodump-ng", "wifi.update_salah", [nilai])]
					saring["update"] = int(nilai)
				"-w", "--write":
					saring["tulis"] = nilai
			i += 2
			continue
		if a.begins_with("-"):
			return [s.galat_kunci("airodump-ng", "wifi.opsi_tidak_dikenal", [a])]
		interface = a
		i += 1
	if interface == "":
		return [s.galat_kunci("airodump-ng", "wifi.usage_airodump")]
	if s.wifi.monitor == "":
		return [s.galat_kunci("airodump-ng", "wifi.iface_bukan_monitor", [interface])]
	if interface != s.wifi.monitor:
		return [s.galat_kunci("airodump-ng", "wifi.iface_salah", [interface, s.wifi.monitor])]

	var semua := Dictionary(WifiLab.data().get("jaringan", {})).keys()
	semua.sort()
	s.wifi.ditemukan = []
	for ssid in semua:
		s.wifi.ditemukan.append(String(ssid))
	var waktu := Time.get_datetime_string_from_system().substr(0, 16).replace("T", " ")
	var hasil := _bingkai(s, saring, 0, waktu)
	var cocok := _ap_cocok(saring)

	s.wifi.catat_scan(s.perangkat.adapter(), semua, waktu)
	_catat(s, "airodump-ng %s: %d access points, %d shown" % [interface, semua.size(), cocok.size()])
	s.jaringan.buka("wifi:scan")
	if cocok.size() == 1 and String(saring["bssid"]) != "":
		var ssid := String(cocok[0])
		s.wifi.terpilih = ssid
		s.wifi.catat_pilih(ssid)
		s.jaringan.buka("wifi:pilih:" + ssid)
		hasil.append(s.baris_kunci("info", "wifi.judul_inspect", [ssid]))
	if String(saring["tulis"]) != "":
		_tulis_csv(s, saring, waktu)
		hasil.append(s.baris_kunci("info", "wifi.tulis", [s.home + "/" + String(saring["tulis"]) + "-01.csv"]))
	if s.live_diizinkan:
		s.live = {"saring": saring, "waktu": waktu, "tick": 0, "update": int(saring["update"])}
	return hasil

# Bingkai berikutnya untuk mode live. Dipanggil Terminal setiap interval -u.
static func live_langkah(s: ShellSession) -> Array:
	if s.live.is_empty():
		return []
	var t := int(s.live["tick"])
	s.live["tick"] = t + 1
	return _bingkai(s, s.live["saring"], t, String(s.live["waktu"]))

# Ctrl+C: menghentikan mode live. Berkas -w ditulis ulang dengan hasil terakhir.
static func live_hentikan(s: ShellSession) -> void:
	if s.live.is_empty():
		return
	if String(Dictionary(s.live["saring"]).get("tulis", "")) != "":
		_tulis_csv(s, s.live["saring"], String(s.live["waktu"]))
	s.live = {}

static func _bssid_valid(teks: String) -> bool:
	var bagian := teks.split(":")
	if bagian.size() != 6:
		return false
	for b in bagian:
		if b.length() != 2 or not b.is_valid_hex_number():
			return false
	return true

# AP yang lolos filter -c, -d, -t, dan -N.
static func _ap_cocok(saring: Dictionary) -> Array:
	var hasil: Array = []
	var semua := Dictionary(WifiLab.data().get("jaringan", {})).keys()
	semua.sort()
	for ssid in semua:
		var j := WifiLab.jaringan(String(ssid))
		var kanal_daftar: Array = saring["kanal"]
		if not kanal_daftar.is_empty() and not kanal_daftar.has(int(j["kanal"])):
			continue
		if String(saring["bssid"]) != "" and String(j["bssid"]) != String(saring["bssid"]):
			continue
		var enkripsi: Array = saring["enkripsi"]
		if not enkripsi.is_empty() and not enkripsi.has(String(j["enkripsi"])):
			continue
		var essid: Array = saring["essid"]
		if not essid.is_empty() and not essid.has(String(ssid)):
			continue
		hasil.append(String(ssid))
	return hasil

# Satu bingkai tampilan airodump-ng. tick adalah jumlah detik sejak dimulai; angka paket naik
# setiap bingkai. Semua angka berasal dari laboratorium, dan bingkai selalu diberi label simulasi.
static func _bingkai(s: ShellSession, saring: Dictionary, tick: int, waktu: String) -> Array:
	var kanal_daftar: Array = saring["kanal"]
	var daftar_kanal: Array = kanal_daftar if not kanal_daftar.is_empty() else KANAL_DEFAULT
	var kanal_aktif: int = int(daftar_kanal[tick % daftar_kanal.size()])
	var interval := int(saring.get("update", 1))
	var ap := _ap_cocok(saring)
	var penuh := s.lebar_kolom >= LEBAR_TABEL_PENUH
	var hasil: Array = [s.baris_kunci("info", "wifi.simulasi_catatan")]
	if penuh:
		hasil.append(s.baris("info", " CH %2d ][ Elapsed: %d s ][ %s" % [kanal_aktif, tick * interval, waktu]))
	else:
		hasil.append(s.baris("info", " CH %2d ][ Elapsed: %d s" % [kanal_aktif, tick * interval]))
	if penuh:
		hasil.append(s.baris("info", ""))
		hasil.append(s.baris("info", HEADER_AP))
		hasil.append(s.baris("info", ""))
	for ssid in ap:
		var j := WifiLab.jaringan(ssid)
		var step := _langkah_paket(ssid)
		var beacon := int(j["beacon"]) + tick * 10
		var data := int(j["data"]) + tick * step
		var per_detik := step if tick > 0 else 0
		if penuh:
			hasil.append(s.baris("info", " %-17s %4d %3d %8d %8d %4d %3d %3d  %-4s %-6s %-4s %s" % [
				String(j["bssid"]), int(j["sinyal"]), int(j["rxq"]), beacon, data, per_detik,
				int(j["kanal"]), int(j["mb"]), String(j["enkripsi"]), String(j["cipher"]), String(j["auth"]), ssid]))
		else:
			# Ringkas: satu AP menjadi beberapa baris pendek agar muat di layar HP. Semua kolom tetap ada.
			hasil.append(s.baris("info", " %s" % String(j["bssid"])))
			hasil.append(s.baris("info", "  PWR %d  CH %d" % [int(j["sinyal"]), int(j["kanal"])]))
			hasil.append(s.baris("info", "  %s %s %s" % [String(j["enkripsi"]), String(j["cipher"]), String(j["auth"]).strip_edges()]))
			hasil.append(s.baris("info", "  ESSID %s" % ssid))
			hasil.append(s.baris("info", "  RXQ %d MB %d" % [int(j["rxq"]), int(j["mb"])]))
			hasil.append(s.baris("info", "  Beacons %d" % beacon))
			hasil.append(s.baris("info", "  #Data %d #/s %d" % [data, per_detik]))
	if ap.is_empty():
		hasil.append(s.baris("info", Bahasa.dua("  Tidak ada access point yang cocok dengan filter.", "  No access points match the filter.")))
	if String(saring["bssid"]) != "" and ap.size() == 1:
		var ssid := String(ap[0])
		var stasiun: Array = Array(WifiLab.jaringan(ssid).get("stasiun", []))
		hasil.append(s.baris("info", ""))
		if penuh:
			hasil.append(s.baris("info", HEADER_STATION))
		else:
			hasil.append(s.baris("info", Bahasa.dua("Stasiun:", "Stations:")))
		for st in stasiun:
			var frame := int(st["frames"]) + tick * 2
			if penuh:
				hasil.append(s.baris("info", " %-17s  %-17s %4d  0-1      0  %7d         %s" % [String(saring["bssid"]), String(st["mac"]), int(st["pwr"]), frame, String(st["probe"])]))
			else:
				hasil.append(s.baris("info", " %s" % String(st["mac"])))
				hasil.append(s.baris("info", "  PWR %d  Frames %d" % [int(st["pwr"]), frame]))
				hasil.append(s.baris("info", "  Rate 0-1 Lost 0"))
				hasil.append(s.baris("info", "  Probes: %s" % (String(st["probe"]) if String(st["probe"]) != "" else "-")))
	return hasil

# Langkah jumlah paket per detik dibuat dari SSID, supaya tiap AP punya laju yang tetap.
static func _langkah_paket(ssid: String) -> int:
	return 1 + ssid.length() % 4

static func _tulis_csv(s: ShellSession, saring: Dictionary, waktu: String) -> void:
	var baris_csv := PackedStringArray(["BSSID,First time seen,Channel,Privacy,Cipher,Authentication,Power,ESSID"])
	for ssid in _ap_cocok(saring):
		var j := WifiLab.jaringan(String(ssid))
		baris_csv.append("%s,%s,%d,%s,%s,%s,%d,%s" % [String(j["bssid"]), waktu, int(j["kanal"]), String(j["enkripsi"]), String(j["cipher"]), String(j["auth"]), int(j["sinyal"]), String(ssid)])
	s.tulis_berkas("%s/%s-01.csv" % [s.home, String(saring["tulis"])], "\n".join(baris_csv))

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
				return [s.baris("error", Bahasa.dua("network-analyzer report: jalankan 'network-analyzer analyze %s' dulu." % ssid, "network-analyzer report: run 'network-analyzer analyze %s' first." % ssid))]
			var path := "%s/laporan/%s.txt" % [s.home, ssid]
			s.tulis_berkas(path, _laporan(s, ssid))
			_catat(s, "network-analyzer report %s: saved to %s" % [ssid, path])
			s.jaringan.buka("wifi:laporan:" + ssid)
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
			_catat(s, "network-analyzer analyze %s: risk=%s findings=%d" % [ssid, WifiLab.tingkat_pair(WifiLab.tingkat_risiko(ssid))[1], daftar.size()])
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
				_catat(s, "network-analyzer verify %s: REJECTED" % ssid)
				return [s.galat_kunci("security", "wifi.kata_sandi_salah", [ssid])]
			s.wifi.terakses[ssid] = true
			_catat(s, "network-analyzer verify %s: ACCEPTED, lab access granted" % ssid)
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
				_catat(s, "password-auditor auth %s: FAILED adapter chipset %s has no monitor mode" % [ssid, chipset])
				return [s.baris("error", Bahasa.dua("password-auditor auth: adapter %s tidak mendukung monitor mode, handshake tidak bisa ditangkap.", "password-auditor auth: adapter %s does not support monitor mode, the handshake cannot be captured.", [chipset]))]
			var sinyal_efektif := int(j["sinyal"]) + _bonus_antena(s)
			if sinyal_efektif < WifiLab.ambang_handshake():
				_catat(s, "password-auditor auth %s: FAILED effective signal %d dBm < threshold %d dBm" % [ssid, sinyal_efektif, WifiLab.ambang_handshake()])
				return [s.baris("error", Bahasa.dua("password-auditor auth: handshake tidak lengkap. Sinyal efektif %d dBm di bawah ambang %d dBm. Tingkatkan antena atau dekatkan perangkat.", "password-auditor auth: handshake incomplete. Effective signal %d dBm is below the %d dBm threshold. Upgrade the antenna or move closer.", [sinyal_efektif, WifiLab.ambang_handshake()]))]
			s.wifi.handshake[ssid] = true
			_catat(s, "password-auditor auth %s: handshake captured (signal %d dBm)" % [ssid, sinyal_efektif])
			s.jaringan.buka("wifi:auth:" + ssid)
			var enkripsi := String(j["enkripsi"])
			var kunci := "wifi.handshake_wpa" if enkripsi == "WPA2" else "wifi.iv_wep"
			return [s.baris_kunci("info", kunci, [ssid])]
		"run":
			if not s.wifi.handshake.has(ssid):
				return [s.galat_kunci("audit", "wifi.belum_auth")]
			var kata := String(WifiLab.jaringan(ssid)["kata_sandi"])
			if not WifiLab.kamus().has(kata):
				_catat(s, "password-auditor run %s: NOT FOUND in dictionary (%d words tried)" % [ssid, WifiLab.kamus().size()])
				return [s.baris_kunci("error", "wifi.tidak_ada_kamus", [])]
			s.wifi.kata_sandi_ditemukan[ssid] = kata
			_catat(s, "password-auditor run %s: key recovered from dictionary (%d words tried), strength=weak" % [ssid, WifiLab.kamus().size()])
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

