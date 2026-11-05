extends GutTest

# Tahap 2: Tools Repository. Pencarian, pemasangan dengan dependensi dan persyaratan adapter,
# pembaruan versi, dan perintah tools di Terminal.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func before_each() -> void:
	Bahasa.kode = "id"

func _adapter(s: ShellSession) -> void:
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()

func test_katalog_berisi_software_awal() -> void:
	for id in ["driver-ar9271", "wifi-scanner", "network-analyzer", "password-auditor"]:
		assert_false(Repositori.item(id).is_empty(), id)

func test_cari_mencocokkan_nama_dan_kategori() -> void:
	assert_true(Repositori.cari("scanner").has("wifi-scanner"))
	assert_true(Repositori.cari("autentikasi").has("password-auditor"))
	assert_eq(Repositori.cari("xyz_tidak_ada").size(), 0)

func test_pasang_butuh_dependensi() -> void:
	var s := _sesi()
	_adapter(s)
	var h := s.repositori.pasang("wifi-scanner", s.economy, s.perangkat)
	assert_false(bool(h["ok"]))
	assert_eq(String(h["kunci"]), "sw.dependensi")

func test_pasang_berurutan_dan_bayar() -> void:
	var s := _sesi()
	_adapter(s)
	var saldo := s.economy.saldo
	assert_true(bool(s.repositori.pasang("driver-ar9271", s.economy, s.perangkat)["ok"]))
	assert_true(bool(s.repositori.pasang("wifi-scanner", s.economy, s.perangkat)["ok"]))
	assert_eq(s.economy.saldo, saldo - 60, "driver gratis, wifi-scanner Kr 60")
	assert_eq(s.repositori.versi("wifi-scanner"), "1.0", "dipasang dengan versi awal")

func test_pasang_butuh_adapter_untuk_wifi_scanner() -> void:
	var s := _sesi()
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	var h := s.repositori.pasang("wifi-scanner", s.economy, s.perangkat)
	assert_false(bool(h["ok"]), "tanpa adapter tidak bisa dipasang")
	assert_eq(String(h["kunci"]), "sw.butuh_adapter")

func test_saldo_kurang_menolak_tanpa_mengubah_saldo() -> void:
	var s := _sesi()
	s.repositori.terpasang["wifi-scanner"] = {"versi": "1.0", "riwayat": ["1.0"]}
	s.economy.saldo = 50
	var h := s.repositori.pasang("network-analyzer", s.economy, s.perangkat)
	assert_false(bool(h["ok"]))
	assert_eq(s.economy.saldo, 50)

func test_perbarui_menaikkan_versi_dan_riwayat() -> void:
	var s := _sesi()
	s.repositori.terpasang["wifi-scanner"] = {"versi": "1.0", "riwayat": ["1.0"]}
	assert_true(bool(s.repositori.perbarui("wifi-scanner")["ok"]))
	assert_eq(s.repositori.versi("wifi-scanner"), "1.1")
	assert_eq(s.repositori.riwayat("wifi-scanner"), ["1.0", "1.1"])
	assert_false(bool(s.repositori.perbarui("wifi-scanner")["ok"]), "sudah terbaru")

func test_perintah_software_hanya_tersedia_setelah_dipasang() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("wifi-scanner --scan")).contains("tidak ditemukan"))
	s.repositori.terpasang["wifi-scanner"] = {"versi": "1.0", "riwayat": ["1.0"]}
	assert_false(_teks(s.jalankan("wifi-scanner --scan")).contains("tidak ditemukan"))

func test_terminal_tools_search_info_install() -> void:
	var s := _sesi()
	_adapter(s)
	assert_true(_teks(s.jalankan("tools search scanner")).contains("wifi-scanner"))
	assert_true(_teks(s.jalankan("tools info wifi-scanner")).contains("driver-ar9271"))
	assert_false(_teks(s.jalankan("tools install driver-ar9271")).contains("bash:"))
	assert_true(s.repositori.punya("driver-ar9271"))
	assert_true(s.jaringan.progres.has("pasang:driver-ar9271"))

func test_terminal_tools_galat_tanpa_argumen_lengkap() -> void:
	var s := _sesi()
	assert_eq(String(s.jalankan("tools install")[0]["tipe"]), "error")
	assert_eq(String(s.jalankan("tools bukan_subperintah")[0]["tipe"]), "error")

func test_repositori_bertahan_saat_disimpan() -> void:
	var s := _sesi()
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.repositori.punya("driver-ar9271"))
