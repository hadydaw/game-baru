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
	for id in ["driver-ar9271", "aircrack-ng", "network-analyzer", "password-auditor"]:
		assert_false(Repositori.item(id).is_empty(), id)

func test_cari_mencocokkan_nama_dan_kategori() -> void:
	assert_true(Repositori.cari("airodump").has("aircrack-ng"))
	assert_true(Repositori.cari("autentikasi").has("password-auditor"))
	assert_eq(Repositori.cari("xyz_tidak_ada").size(), 0)

func test_pasang_butuh_dependensi() -> void:
	var s := _sesi()
	_adapter(s)
	var h := s.repositori.pasang("aircrack-ng", s.economy, s.perangkat)
	assert_false(bool(h["ok"]))
	assert_eq(String(h["kunci"]), "sw.dependensi")

func test_pasang_berurutan_dan_bayar() -> void:
	var s := _sesi()
	_adapter(s)
	var saldo := s.economy.saldo
	assert_true(bool(s.repositori.pasang("driver-ar9271", s.economy, s.perangkat)["ok"]))
	assert_true(bool(s.repositori.pasang("aircrack-ng", s.economy, s.perangkat)["ok"]))
	assert_eq(s.economy.saldo, saldo - 60, "driver gratis, aircrack-ng (berisi airodump-ng dan airmon-ng) Kr 60")
	assert_eq(s.repositori.versi("aircrack-ng"), "1.6", "dipasang dengan versi awal")

func test_pasang_butuh_adapter_untuk_aircrack() -> void:
	var s := _sesi()
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	var h := s.repositori.pasang("aircrack-ng", s.economy, s.perangkat)
	assert_false(bool(h["ok"]), "tanpa adapter tidak bisa dipasang")
	assert_eq(String(h["kunci"]), "sw.butuh_adapter")

func test_saldo_kurang_menolak_tanpa_mengubah_saldo() -> void:
	var s := _sesi()
	s.repositori.terpasang["aircrack-ng"] = {"versi": "1.6", "riwayat": ["1.6"]}
	s.economy.saldo = 50
	var h := s.repositori.pasang("network-analyzer", s.economy, s.perangkat)
	assert_false(bool(h["ok"]))
	assert_eq(s.economy.saldo, 50)

func test_perbarui_menaikkan_versi_dan_riwayat() -> void:
	var s := _sesi()
	s.repositori.terpasang["aircrack-ng"] = {"versi": "1.6", "riwayat": ["1.6"]}
	assert_true(bool(s.repositori.perbarui("aircrack-ng")["ok"]))
	assert_eq(s.repositori.versi("aircrack-ng"), "1.7")
	assert_eq(s.repositori.riwayat("aircrack-ng"), ["1.6", "1.7"])
	assert_false(bool(s.repositori.perbarui("aircrack-ng")["ok"]), "sudah terbaru")

func test_perintah_software_hanya_tersedia_setelah_dipasang() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("airodump-ng wlan0mon")).contains("tidak ditemukan"))
	s.repositori.terpasang["aircrack-ng"] = {"versi": "1.6", "riwayat": ["1.6"]}
	assert_false(_teks(s.jalankan("airodump-ng wlan0mon")).contains("tidak ditemukan"))

func test_terminal_tools_search_info_install() -> void:
	var s := _sesi()
	_adapter(s)
	assert_true(_teks(s.jalankan("apt search airodump")).contains("aircrack-ng"))
	assert_true(_teks(s.jalankan("apt show aircrack-ng")).contains("driver-ar9271"))
	assert_false(_teks(s.jalankan("apt install -y driver-ar9271")).contains("bash:"))
	assert_true(s.repositori.punya("driver-ar9271"))
	assert_true(s.jaringan.progres.has("pasang:driver-ar9271"))

func test_terminal_apt_galat_tanpa_argumen_lengkap() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("apt install")).contains("0 upgraded"), "apt install tanpa paket seperti apt asli")
	assert_eq(String(s.jalankan("tools install driver-ar9271")[0]["tipe"]), "error", "perintah lama ditolak")

func test_repositori_bertahan_saat_disimpan() -> void:
	var s := _sesi()
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.repositori.punya("driver-ar9271"))
