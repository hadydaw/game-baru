extends GutTest

# Airmon-ng dan airodump-ng: nama interface monitor dari airmon-ng, filter -c daftar kanal,
# validasi opsi, tampilan ringkas di layar sempit, dan mode live yang dihentikan Ctrl+C.

func _sesi_adapter(chipset_ok := true) -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	for c in ["toko beli usb_wireless_adapter", "toko beli antena_eksternal", "toko beli kabel_usb", "device rakit", "tools install driver-ar9271", "device hubungkan", "tools install airodump-ng"]:
		s.jalankan(c)
	return s

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func test_airodump_butuh_monitor_mode_lebih_dulu() -> void:
	var s := _sesi_adapter()
	var h := s.jalankan("airodump-ng wlan0mon")
	assert_eq(String(h[0]["tipe"]), "error", "tanpa airmon-ng, interface monitor belum ada")
	assert_true(_teks(h).contains("airmon-ng start wlan0"), "galat menyebut perintah yang benar")

func test_airmon_start_menghasilkan_nama_interface() -> void:
	var s := _sesi_adapter()
	var h := _teks(s.jalankan("airmon-ng start wlan0"))
	assert_true(h.contains("(mac80211 monitor mode vif enabled for [phy0]wlan0 on [phy0]wlan0mon)"), "keluaran airmon sesuai format mac80211")
	assert_eq(s.wifi.monitor, "wlan0mon", "nama monitor dari airmon-ng disimpan")
	assert_true(s.jaringan.progres.has("wifi:monitor"))
	assert_eq(String(s.jalankan("airmon-ng start wlan0")[0]["tipe"]), "error", "start kedua ditolak")

func test_airodump_memakai_nama_yang_dihasilkan_airmon() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	assert_eq(String(s.jalankan("airodump-ng wlan0")[0]["tipe"]), "error", "wlan0 bukan interface monitor")
	assert_false(_teks(s.jalankan("airodump-ng wlan0mon")).contains("tidak"), "wlan0mon diterima")

func test_chipset_tanpa_monitor_mode_ditolak() -> void:
	# Adapter RT5370 tidak mendukung monitor mode; driver-nya rt2800usb.
	assert_false(WifiLab.mendukung_monitor("rt5370"))
	assert_eq(String(WifiLab.airmon_info("rt5370").get("driver", "")), "rt2800usb")
	assert_true(WifiLab.mendukung_monitor("ar9271"))

func test_airmon_butuh_adapter_terhubung() -> void:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	assert_eq(String(s.jalankan("airmon-ng start wlan0")[0]["tipe"]), "error", "tanpa adapter terhubung, airmon-ng menolak")
	assert_eq(s.wifi.monitor, "")

func test_airmon_stop_mengembalikan_mode_managed() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	var h := _teks(s.jalankan("airmon-ng stop wlan0mon"))
	assert_true(h.contains("(mac80211 monitor mode vif disabled for [phy0]wlan0mon)"))
	assert_eq(s.wifi.monitor, "")

func test_filter_channel_daftar_dipisah_koma() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	var t := _teks(s.jalankan("airodump-ng -c 1,11 wlan0mon"))
	assert_true(t.contains("LAB-WIFI-02"), "kanal 11 tampil")
	assert_true(t.contains("LAB-WIFI-03"), "kanal 1 tampil")
	assert_false(t.contains("LAB-WIFI-01"), "kanal 6 disaring")

func test_opsi_tidak_valid_ditolak() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	assert_eq(String(s.jalankan("airodump-ng -t WEP2 wlan0mon")[0]["tipe"]), "error", "enkripsi tidak dikenal")
	assert_eq(String(s.jalankan("airodump-ng -c abc wlan0mon")[0]["tipe"]), "error", "kanal bukan angka")
	assert_eq(String(s.jalankan("airodump-ng -d 02:4A wlan0mon")[0]["tipe"]), "error", "BSSID tidak lengkap")
	assert_eq(String(s.jalankan("airodump-ng -u 0 wlan0mon")[0]["tipe"]), "error", "interval nol")
	assert_eq(String(s.jalankan("airodump-ng -x wlan0mon")[0]["tipe"]), "error", "opsi tidak dikenal")
	assert_eq(String(s.jalankan("airodump-ng -c")[0]["tipe"]), "error", "opsi tanpa nilai")

func test_filter_essid_dan_enkripsi() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	var t := _teks(s.jalankan("airodump-ng -t WPA2 -N LAB-WIFI-03 wlan0mon"))
	assert_true(t.contains("LAB-WIFI-03"))
	assert_false(t.contains("LAB-WIFI-01"))
	assert_false(t.contains("LAB-WIFI-02"))

func test_tampilan_ringkas_muat_di_layar_sempit() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	s.lebar_kolom = 40
	for b in s.jalankan("airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon"):
		var baris := Bahasa.pilih(String(b["teks"]))
		# Baris tabel dan detail (berawalan spasi atau MAC) harus muat di layar sempit.
		if baris.begins_with(" ") or baris.begins_with("02:"):
			assert_true(baris.length() <= 24, "baris ringkas <= 24 karakter: '%s'" % baris)
	var t := _teks(s.jalankan("airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon"))
	assert_true(t.contains("ESSID LAB-WIFI-01"), "ESSID tetap tampil")
	assert_true(t.contains("RXQ 100"), "RXQ tetap tampil")
	assert_true(t.contains("CCMP PSK"), "cipher dan auth tetap tampil")
	assert_true(t.contains("Probes: Senja-Guest"), "probe station tetap tampil")

func test_tabel_penuh_di_layar_lebar() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	s.lebar_kolom = 120
	var t := _teks(s.jalankan("airodump-ng wlan0mon"))
	assert_true(t.contains("BSSID              PWR RXQ  Beacons    #Data, #/s  CH  MB   ENC  CIPHER AUTH ESSID"))

func test_mode_live_hanya_dari_terminal() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	assert_false(s.live_aktif(), "snapshot biasa tidak memulai mode live")
	s.live_diizinkan = true
	s.jalankan("airodump-ng wlan0mon")
	assert_true(s.live_aktif(), "Terminal mengizinkan mode live")

func test_live_bingkai_berubah_lalu_berhenti() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	s.live_diizinkan = true
	s.jalankan("airodump-ng wlan0mon")
	s.live_diizinkan = false
	var a := _teks(s.live_langkah())
	var b := _teks(s.live_langkah())
	assert_true(a.contains("Elapsed: 0 s") and b.contains("Elapsed: 1 s"), "waktu berjalan tiap bingkai")
	assert_true(a.contains("[SIMULASI]"), "setiap bingkai diberi label simulasi")
	assert_true(a.contains("  37 ") and b.contains("  41 "), "paket naik per bingkai sesuai laju AP")
	s.live_hentikan()
	assert_false(s.live_aktif(), "Ctrl+C menghentikan mode live")
	assert_true(s.live_langkah().is_empty(), "tidak ada bingkai setelah berhenti")
	assert_eq(s.wifi.monitor, "wlan0mon", "monitor mode tetap aktif setelah Ctrl+C")
	assert_true(s.jaringan.progres.has("wifi:scan"), "progres tidak hilang")

func test_mode_live_tidak_ikut_disimpan() -> void:
	var s := _sesi_adapter()
	s.jalankan("airmon-ng start wlan0")
	s.live_diizinkan = true
	s.jalankan("airodump-ng wlan0mon")
	s.live_diizinkan = false
	assert_false(s.to_dict().has("live"), "keadaan live tidak masuk ke save")
	var dimuat := ShellSession.dari_dict(s.to_dict())
	assert_false(dimuat.live_aktif())

func test_keluaran_bahasa_inggris_tanpa_kata_indonesia() -> void:
	var s := _sesi_adapter()
	Bahasa.set_kode("en")
	var a := _teks(s.jalankan("airmon-ng start wlan0"))
	var b := _teks(s.jalankan("airodump-ng wlan0mon"))
	var c := _teks(s.jalankan("airodump-ng wlan0"))
	Bahasa.set_kode("id")
	assert_true(b.contains("[SIMULATION]"), "label simulasi dalam bahasa Inggris")
	assert_true(c.contains("not in monitor mode") or c.contains("not the active monitor"), "galat dalam bahasa Inggris: %s" % c)
	for t in [a, b, c]:
		assert_false(t.contains("[SIMULASI]") or t.contains("Tidak ada") or t.contains("tidak dalam"), "tidak ada kata Indonesia")
