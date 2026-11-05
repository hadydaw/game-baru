extends GutTest

# Tahap 3: alur pengujian Wi-Fi laboratorium. Setiap tahap memakai hasil tahap sebelumnya,
# dan tidak ada perintah tunggal yang langsung memberi akses.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func _siap() -> ShellSession:
	var s := _sesi()
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	s.repositori.terpasang["wifi-scanner"] = {"versi": "1.0", "riwayat": ["1.0"]}
	s.repositori.terpasang["network-analyzer"] = {"versi": "1.2", "riwayat": ["1.2"]}
	s.repositori.terpasang["password-auditor"] = {"versi": "1.0", "riwayat": ["1.0"]}
	PerangkatCommands.hubungkan(s)
	return s

func before_each() -> void:
	Bahasa.kode = "id"

func test_scan_butuh_perangkat_terhubung() -> void:
	var s := _sesi()
	s.repositori.terpasang["wifi-scanner"] = {"versi": "1.0", "riwayat": ["1.0"]}
	assert_eq(String(s.jalankan("wifi-scanner --scan")[0]["tipe"]), "error")

func test_scan_menemukan_jaringan_lab() -> void:
	var s := _siap()
	var t := _teks(s.jalankan("wifi-scanner --scan"))
	assert_true(t.contains("LAB-WIFI-01"))
	assert_true(s.wifi.terlihat("LAB-WIFI-02"))
	assert_true(s.jaringan.progres.has("wifi:scan"))

func test_network_butuh_scan() -> void:
	var s := _siap()
	assert_eq(String(s.jalankan("network list")[0]["tipe"]), "error")
	s.jalankan("wifi-scanner --scan")
	assert_true(_teks(s.jalankan("network list")).contains("LAB-WIFI-01"))

func test_security_analyze_butuh_inspect_lebih_dulu() -> void:
	var s := _siap()
	s.jalankan("wifi-scanner --scan")
	assert_eq(String(s.jalankan("security analyze LAB-WIFI-01")[0]["tipe"]), "error")
	s.jalankan("network inspect LAB-WIFI-01")
	assert_true(s.jaringan.progres.has("wifi:pilih:LAB-WIFI-01"))
	assert_false(_teks(s.jalankan("security analyze LAB-WIFI-01")).contains("bash:"))
	assert_true(s.wifi.dianalisis.has("LAB-WIFI-01"))

func test_audit_auth_butuh_analisis() -> void:
	var s := _siap()
	s.jalankan("wifi-scanner --scan")
	s.jalankan("network inspect LAB-WIFI-01")
	assert_eq(String(s.jalankan("audit auth LAB-WIFI-01")[0]["tipe"]), "error")
	s.jalankan("security analyze LAB-WIFI-01")
	s.jalankan("audit auth LAB-WIFI-01")
	assert_true(s.wifi.handshake.has("LAB-WIFI-01"))

func test_audit_run_menemukan_kata_sandi_lemah() -> void:
	var s := _siap()
	s.jalankan("wifi-scanner --scan")
	s.jalankan("network inspect LAB-WIFI-01")
	s.jalankan("security analyze LAB-WIFI-01")
	s.jalankan("audit auth LAB-WIFI-01")
	var t := _teks(s.jalankan("audit run LAB-WIFI-01"))
	assert_true(t.contains("senja1234"))
	assert_eq(String(s.wifi.kata_sandi_ditemukan["LAB-WIFI-01"]), "senja1234")

func test_audit_run_gagal_untuk_kata_sandi_kuat() -> void:
	var s := _siap()
	s.jalankan("wifi-scanner --scan")
	s.jalankan("network inspect LAB-WIFI-03")
	s.jalankan("security analyze LAB-WIFI-03")
	s.jalankan("audit auth LAB-WIFI-03")
	assert_eq(String(s.jalankan("audit run LAB-WIFI-03")[0]["tipe"]), "error")
	assert_false(s.wifi.kata_sandi_ditemukan.has("LAB-WIFI-03"))

func test_verify_akses_hanya_dengan_kata_sandi_benar() -> void:
	var s := _siap()
	s.jalankan("wifi-scanner --scan")
	s.jalankan("network inspect LAB-WIFI-01")
	s.jalankan("security analyze LAB-WIFI-01")
	s.jalankan("audit auth LAB-WIFI-01")
	assert_eq(String(s.jalankan("security verify LAB-WIFI-01 senja1234")[0]["tipe"]), "error", "belum audit")
	s.jalankan("audit run LAB-WIFI-01")
	assert_eq(String(s.jalankan("security verify LAB-WIFI-01 salah")[0]["tipe"]), "error")
	assert_false(s.wifi.terakses.has("LAB-WIFI-01"))
	assert_false(_teks(s.jalankan("security verify LAB-WIFI-01 senja1234")).contains("bash:"))
	assert_true(s.wifi.terakses.has("LAB-WIFI-01"))
	assert_true(s.jaringan.progres.has("wifi:akses:LAB-WIFI-01"))

func test_keadaan_wifi_bertahan_saat_disimpan() -> void:
	var s := _siap()
	s.jalankan("wifi-scanner --scan")
	s.jalankan("network inspect LAB-WIFI-01")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.wifi.terlihat("LAB-WIFI-01"))
	assert_eq(pulih.wifi.terpilih, "LAB-WIFI-01")
