extends GutTest

# Pengujian Wi-Fi yang mendalam: keluaran tabel, hambatan perangkat, sinyal lemah, log, laporan,
# permintaan membuka Network Manager setelah scan, dan Tab melengkapi alat yang terpasang.

func before_each() -> void:
	Bahasa.kode = "id"

func _sesi_terpasang() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	for c in ["toko beli usb_wireless_adapter", "toko beli antena_eksternal", "toko beli kabel_usb", "device rakit", "tools install driver-ar9271", "device hubungkan", "tools install airodump-ng", "tools install network-analyzer", "tools install password-auditor"]:
		s.jalankan(c)
	return s

func _teks(hasil: Array) -> String:
	var bagian: Array = []
	for b in hasil:
		bagian.append(ShellSession.teks_baris(b))
	return "\n".join(PackedStringArray(bagian))

func test_scan_menampilkan_tabel_dan_batang_sinyal() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	var t := _teks(s.jalankan("airodump-ng wlan0mon"))
	assert_true(t.contains("BSSID"), "header tabel ada")
	assert_true(t.contains("02:4A:1C:00:01:01"), "BSSID tampil")
	assert_true(t.contains("-48"), "PWR -48 dBm tampil")
	assert_true(t.contains("-71"), "PWR -71 dBm tampil")

func test_scan_tidak_membuka_network_manager() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	assert_eq(s.permintaan_aplikasi, "", "scan hanya menampilkan hasil di Terminal")

func test_monitor_mode_hanya_untuk_chipset_yang_mendukung() -> void:
	assert_true(WifiLab.mendukung_monitor("ar9271"))
	assert_false(WifiLab.mendukung_monitor("rt5370"))

func test_handshake_gagal_karena_sinyal_lemah_beralasan() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	s.jalankan("airodump-ng --bssid 02:4A:1C:00:03:03 wlan0mon")
	s.jalankan("security analyze LAB-WIFI-03")
	var t := _teks(s.jalankan("audit auth LAB-WIFI-03"))
	assert_true(t.contains("tidak lengkap"), "alasan kegagalan tampil")
	assert_false(s.wifi.handshake.has("LAB-WIFI-03"), "handshake tidak tercatat")

func test_antena_lebih_kuat_membuat_handshake_berhasil() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	s.jalankan("airodump-ng --bssid 02:4A:1C:00:03:03 wlan0mon")
	s.jalankan("security analyze LAB-WIFI-03")
	s.perangkat.rakitan["antena"] = 2
	s.jalankan("audit auth LAB-WIFI-03")
	assert_true(s.wifi.handshake.has("LAB-WIFI-03"), "antena penguat menutup selisih sinyal")

func test_log_dan_laporan_tertulis_di_berkas() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	s.jalankan("airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon")
	s.jalankan("security analyze LAB-WIFI-01")
	s.jalankan("security report LAB-WIFI-01")
	var log_node := s.fs.ambil("/home/operator/log/wifi.log")
	assert_false(log_node.is_empty(), "log dibuat")
	assert_true(String(log_node["isi"]).contains("airodump-ng wlan0mon"), "log mencatat scan")
	var laporan := s.fs.ambil("/home/operator/laporan/LAB-WIFI-01.txt")
	assert_false(laporan.is_empty(), "laporan dibuat")
	assert_true(String(laporan["isi"]).contains("Tingkat risiko keseluruhan: TINGGI"), "risiko tercantum")
	assert_true(String(laporan["isi"]).contains("Rekomendasi"), "rekomendasi tercantum")

func test_laporan_butuh_analisis_dulu() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	var t := _teks(s.jalankan("security report LAB-WIFI-01"))
	assert_true(t.contains("security analyze"), "pemain diarahkan ke analisis")

func test_tab_melengkapi_alat_yang_terpasang() -> void:
	var s := _sesi_terpasang()
	var hasil := ShellComplete.lengkapi(s, "airo")
	assert_eq(String(hasil["teks"]), "airodump-ng ", "airo dilengkapi menjadi airodump-ng")

func test_tab_melengkapi_subperintah() -> void:
	var s := _sesi_terpasang()
	var hasil := ShellComplete.lengkapi(s, "airodump-ng --b")
	assert_eq(String(hasil["teks"]), "airodump-ng --bssid ", "opsi --bssid dilengkapi")
