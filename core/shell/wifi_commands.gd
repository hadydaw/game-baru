class_name WifiCommands
extends RefCounted

# Perintah pengujian Wi-Fi laboratorium: wifi-scanner --scan, network list|inspect,
# security analyze|verify, dan audit auth|run. Setiap perintah memeriksa tahap sebelumnya
# dan data yang dihasilkannya (WifiLab). Tidak ada perintah yang langsung memberi akses.

static func scan(s: ShellSession, p: Dictionary) -> Array:
	if not s.perangkat.terhubung():
		return [s.galat_kunci("wifi-scanner", "hw.belum_terhubung")]
	if not ShellParser.punya_opsi(p["opsi"], "--scan"):
		return [s.galat_kunci("wifi-scanner", "wifi.usage_scan")]
	var ssids := Dictionary(WifiLab.data().get("jaringan", {})).keys()
	ssids.sort()
	s.wifi.ditemukan = []
	var hasil: Array = [s.baris_kunci("info", "wifi.judul_scan")]
	for ssid in ssids:
		var j := WifiLab.jaringan(String(ssid))
		s.wifi.ditemukan.append(String(ssid))
		hasil.append(s.baris("info", Bahasa.dua("  %-12s kanal %-3d sinyal %4d dBm  %s", "  %-12s channel %-3d signal %4d dBm  %s", [String(ssid), int(j["kanal"]), int(j["sinyal"]), String(j["enkripsi"])])))
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
				hasil.append(s.baris("info", "  " + String(ssid)))
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
			s.jaringan.buka("wifi:pilih:" + ssid)
			return [
				s.baris_kunci("info", "wifi.judul_inspect", [ssid]),
				s.baris_kunci("info", "wifi.detail", [String(j["bssid"]), int(j["kanal"]), int(j["sinyal"]), String(j["enkripsi"])]),
			]
	return [s.galat_kunci("network", "wifi.usage_network")]

static func security(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.is_empty():
		return [s.galat_kunci("security", "wifi.usage_security")]
	match String(args[0]):
		"analyze":
			if args.size() < 2:
				return [s.galat_kunci("security", "err.butuh_argumen")]
			var ssid := String(args[1])
			if s.wifi.terpilih != ssid:
				return [s.galat_kunci("security", "wifi.belum_dipilih")]
			var j := WifiLab.jaringan(ssid)
			var enkripsi := String(j["enkripsi"])
			s.wifi.dianalisis[ssid] = true
			s.jaringan.buka("wifi:analisis:" + ssid)
			return [
				s.baris_kunci("info", "wifi.analisis_judul", [ssid]),
				s.baris_kunci("info", "wifi.analisis_" + enkripsi.to_lower(), []),
			]
		"verify":
			if args.size() < 3:
				return [s.galat_kunci("security", "err.butuh_argumen")]
			var ssid := String(args[1])
			var kata := String(args[2])
			if not s.wifi.kata_sandi_ditemukan.has(ssid):
				return [s.galat_kunci("security", "wifi.belum_audit")]
			if String(s.wifi.kata_sandi_ditemukan[ssid]) != kata:
				return [s.galat_kunci("security", "wifi.kata_sandi_salah", [ssid])]
			s.wifi.terakses[ssid] = true
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
			s.wifi.handshake[ssid] = true
			s.jaringan.buka("wifi:auth:" + ssid)
			var enkripsi := String(WifiLab.jaringan(ssid)["enkripsi"])
			var kunci := "wifi.handshake_wpa" if enkripsi == "WPA2" else "wifi.iv_wep"
			return [s.baris_kunci("info", kunci, [ssid])]
		"run":
			if not s.wifi.handshake.has(ssid):
				return [s.galat_kunci("audit", "wifi.belum_auth")]
			var kata := String(WifiLab.jaringan(ssid)["kata_sandi"])
			if not WifiLab.kamus().has(kata):
				return [s.baris_kunci("error", "wifi.tidak_ada_kamus", [])]
			s.wifi.kata_sandi_ditemukan[ssid] = kata
			s.jaringan.buka("wifi:audit:" + ssid)
			return [s.baris_kunci("info", "wifi.kunci_ditemukan", [ssid, kata])]
	return [s.galat_kunci("audit", "wifi.usage_audit")]
