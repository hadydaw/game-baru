extends GutTest

# Tahap 1: APT simulasi. install dengan dependensi, konfirmasi Y/n, remove dengan dependen,
# purge, autoremove, upgrade, update, list, search, show, dan galat seperti apt asli.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func _apt(s: ShellSession, perintah: String) -> Array:
	return s.jalankan(perintah)

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += String(b["teks"]) + "\n"
	return t

func before_each() -> void:
	Bahasa.kode = "en"

func _adapter(s: ShellSession) -> void:
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()

func test_apt_tanpa_argumen_menampilkan_pemakaian() -> void:
	var s := _sesi()
	assert_string_contains(_teks(_apt(s, "apt")), "Usage: apt")

func test_install_meminta_konfirmasi_lalu_memasang_dependensi() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	var lines := _apt(s, "apt install aircrack-ng")
	assert_string_contains(_teks(lines), "The following additional packages will be installed:")
	assert_string_contains(_teks(lines), "Do you want to continue? [Y/n]")
	assert_false(s.repositori.punya("aircrack-ng"), "belum dipasang sebelum dijawab")
	var hasil := s.jalankan("y")
	assert_string_contains(_teks(hasil), "Setting up driver-ar9271")
	assert_string_contains(_teks(hasil), "Setting up aircrack-ng")
	assert_true(s.repositori.punya("driver-ar9271"))
	assert_true(s.repositori.punya("aircrack-ng"))
	assert_true(s.repositori.auto("driver-ar9271"), "dependensi ditandai otomatis")
	assert_false(s.repositori.auto("aircrack-ng"), "paket yang diminta tidak otomatis")

func test_jawaban_n_membatalkan_instalasi() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install aircrack-ng")
	var hasil := s.jalankan("n")
	assert_string_contains(_teks(hasil), "Abort.")
	assert_false(s.repositori.punya("aircrack-ng"))

func test_install_dengan_y_langsung_memasang() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	var hasil := _apt(s, "apt install -y aircrack-ng")
	assert_string_contains(_teks(hasil), "Setting up aircrack-ng")
	assert_true(s.repositori.punya("aircrack-ng"))

func test_install_paket_tidak_dikenal_galat_seperti_apt() -> void:
	var s := _sesi()
	var hasil := _apt(s, "apt install xyz-tidak-ada")
	assert_string_contains(_teks(hasil), "E: Unable to locate package xyz-tidak-ada")

func test_install_paket_yang_sudah_terpasang() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y aircrack-ng")
	var hasil := _apt(s, "apt install -y aircrack-ng")
	assert_string_contains(_teks(hasil), "aircrack-ng is already the newest version")

func test_install_saldo_kurang_tidak_mengubah_apa_pun() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 10
	var hasil := _apt(s, "apt install -y aircrack-ng")
	assert_string_contains(_teks(hasil), "E: Not enough credits")
	assert_false(s.repositori.punya("driver-ar9271"))
	assert_eq(s.economy.saldo, 10)

func test_install_tanpa_adapter_ditolak() -> void:
	var s := _sesi()
	s.economy.saldo = 5000
	var hasil := _apt(s, "apt install -y driver-ar9271")
	assert_string_contains(_teks(hasil), "requires a Wi-Fi adapter")
	assert_false(s.repositori.punya("driver-ar9271"))

func test_remove_ikut_menghapus_dependen() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y network-analyzer")
	var hasil := _apt(s, "apt remove -y aircrack-ng")
	assert_string_contains(_teks(hasil), "The following packages will be REMOVED:")
	assert_false(s.repositori.punya("aircrack-ng"))
	assert_false(s.repositori.punya("network-analyzer"), "dependen ikut terhapus")
	assert_true(s.repositori.punya("driver-ar9271"), "dependensi tetap ada sampai autoremove")

func test_remove_paket_yang_tidak_terpasang_galat() -> void:
	var s := _sesi()
	var hasil := _apt(s, "apt remove aircrack-ng")
	assert_string_contains(_teks(hasil), "is not installed, so not removed")

func test_autoremove_menghapus_dependensi_yatim() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y aircrack-ng")
	_apt(s, "apt remove -y aircrack-ng")
	var hasil := _apt(s, "apt autoremove -y")
	assert_string_contains(_teks(hasil), "driver-ar9271")
	assert_false(s.repositori.punya("driver-ar9271"))

func test_autoremove_tanpa_kandidat() -> void:
	var s := _sesi()
	var hasil := _apt(s, "apt autoremove -y")
	assert_string_contains(_teks(hasil), "0 to remove")

func test_purge_menampilkan_pesan_purging() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y driver-ar9271")
	var hasil := _apt(s, "apt purge -y driver-ar9271")
	assert_string_contains(_teks(hasil), "Purging configuration files for driver-ar9271")
	assert_false(s.repositori.punya("driver-ar9271"))

func test_upgrade_memperbarui_paket_lama() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y aircrack-ng")
	s.repositori.terpasang["aircrack-ng"]["versi"] = "1.6"
	var hasil := _apt(s, "apt upgrade -y")
	assert_string_contains(_teks(hasil), "Setting up aircrack-ng (1.7)")
	assert_eq(s.repositori.versi("aircrack-ng"), "1.7")

func test_update_melaporkan_paket_yang_bisa_diperbarui() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y aircrack-ng")
	s.repositori.terpasang["aircrack-ng"]["versi"] = "1.6"
	var hasil := _apt(s, "apt update")
	assert_string_contains(_teks(hasil), "Hit:1 http://http.kali.org/kali kali-rolling InRelease")
	assert_string_contains(_teks(hasil), "packages can be upgraded")

func test_list_installed_dan_upgradable() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y aircrack-ng")
	assert_string_contains(_teks(_apt(s, "apt list --installed")), "aircrack-ng/kali-rolling,now")
	s.repositori.terpasang["aircrack-ng"]["versi"] = "1.6"
	assert_string_contains(_teks(_apt(s, "apt list --upgradable")), "[upgradable from: 1.6]")

func test_search_dan_show() -> void:
	var s := _sesi()
	assert_string_contains(_teks(_apt(s, "apt search airodump")), "aircrack-ng/kali-rolling")
	assert_string_contains(_teks(_apt(s, "apt show aircrack-ng")), "Package: aircrack-ng")
	assert_string_contains(_teks(_apt(s, "apt show tidak-ada")), "E: No packages found")

func test_perintah_tidak_dikenal_dan_opsi_salah() -> void:
	var s := _sesi()
	assert_string_contains(_teks(_apt(s, "apt xyz")), "E: Invalid operation xyz")
	assert_string_contains(_teks(_apt(s, "apt install -x aircrack-ng")), "E: Command line option")

func test_tools_install_lama_ditolak_seperti_perintah_tidak_ada() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	var teks := _teks(s.jalankan("tools install driver-ar9271"))
	assert_string_contains(teks, "tools", "galat menyebut perintah yang tidak ada")
	assert_false(s.repositori.punya("driver-ar9271"), "perintah lama tidak memasang apa pun")

func test_show_memakai_nama_bagian_bahasa_inggris() -> void:
	var s := _sesi()
	var teks := _teks(_apt(s, "apt show aircrack-ng"))
	assert_string_contains(teks, "Section: net")
	assert_false(teks.contains("nirkabel"), "tidak ada kategori Indonesia")

func test_search_menandai_paket_yang_bisa_diperbarui() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y aircrack-ng")
	s.repositori.terpasang["aircrack-ng"]["versi"] = "1.6"
	assert_string_contains(_teks(_apt(s, "apt search airodump")), "[installed,upgradable to: 1.7]")

func test_perintah_lain_setelah_prompt_tetap_dijalankan() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install aircrack-ng")
	var hasil := _teks(s.jalankan("whoami"))
	assert_string_contains(hasil, "Abort.")
	assert_string_contains(hasil, "operator")
	assert_false(s.repositori.punya("aircrack-ng"), "jawaban non-Y tidak memasang")
	assert_false(s.konfirmasi_tertunda.is_valid(), "prompt sudah selesai")

func test_save_lama_tanpa_penanda_auto_tetap_terbaca() -> void:
	var lama := {"terpasang": {
		"driver-ar9271": {"versi": "2.0", "riwayat": ["2.0"]},
		"aircrack-ng": {"versi": "1.6", "riwayat": ["1.6"]},
	}}
	var r := Repositori.new()
	r.terapkan(lama)
	assert_true(r.punya("driver-ar9271"))
	assert_true(r.punya("aircrack-ng"))
	assert_eq(r.terpasang.size(), 2, "tidak ada paket yang bertambah atau hilang")
	assert_false(r.auto("driver-ar9271"), "save lama dianggap pemasangan manual")
	assert_eq(r.versi("aircrack-ng"), "1.6")

func test_save_bolak_balik_mempertahankan_penanda_auto() -> void:
	var r := Repositori.new()
	r.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"], "auto": true}
	var r2 := Repositori.new()
	r2.terapkan(r.to_dict())
	assert_true(r2.auto("driver-ar9271"))
	assert_eq(r2.terpasang.size(), 1)

func test_remove_menyisakan_konfigurasi_dan_purge_menghapusnya() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y driver-ar9271")
	_apt(s, "apt remove -y driver-ar9271")
	assert_false(s.repositori.punya("driver-ar9271"))
	assert_true(s.repositori.punya_konfig("driver-ar9271"), "remove menyisakan konfigurasi")
	var hasil := _teks(_apt(s, "apt purge -y driver-ar9271"))
	assert_string_contains(hasil, "Purging configuration files for driver-ar9271")
	assert_false(s.repositori.punya_konfig("driver-ar9271"), "purge menghapus konfigurasi")

func test_purge_langsung_tidak_menyisakan_konfigurasi() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y driver-ar9271")
	_apt(s, "apt purge -y driver-ar9271")
	assert_false(s.repositori.punya_konfig("driver-ar9271"))

func test_remove_tidak_menghapus_konfigurasi_dan_tidak_menulis_purging() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y driver-ar9271")
	var hasil := _teks(_apt(s, "apt remove -y driver-ar9271"))
	assert_false(hasil.contains("Purging"))
	assert_true(s.repositori.punya_konfig("driver-ar9271"))

func test_konfigurasi_ikut_tersimpan_dan_dipulihkan() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install -y driver-ar9271")
	_apt(s, "apt remove -y driver-ar9271")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.repositori.punya_konfig("driver-ar9271"))
	assert_string_contains(_teks(_apt(pulih, "apt purge -y driver-ar9271")), "Purging configuration files")
	assert_false(pulih.repositori.punya_konfig("driver-ar9271"))

func test_save_lama_tanpa_konfig_tetap_terbaca() -> void:
	var r := Repositori.new()
	r.terapkan({"terpasang": {"aircrack-ng": {"versi": "1.6", "riwayat": ["1.6"]}}})
	assert_true(r.punya("aircrack-ng"))
	assert_false(r.punya_konfig("aircrack-ng"))

func test_ctrl_c_saat_prompt_membatalkan_tanpa_memasang() -> void:
	var s := _sesi()
	_adapter(s)
	s.economy.saldo = 5000
	_apt(s, "apt install aircrack-ng")
	assert_true(s.batalkan_konfirmasi(), "prompt tertunda dibatalkan")
	assert_false(s.repositori.punya("aircrack-ng"))
	assert_false(s.repositori.punya("driver-ar9271"))
	assert_eq(s.economy.saldo, 5000, "saldo tidak berubah")
	assert_false(s.konfirmasi_tertunda.is_valid())
	assert_false(s.batalkan_konfirmasi(), "tidak ada prompt yang dibatalkan")
	assert_string_contains(_teks(s.jalankan("whoami")), "operator", "perintah berikutnya normal")

# Paket yang sudah terpasang (mis. dari simpanan lama) tetap mencatat flag pasang, agar misi tidak macet.
func test_install_paket_yang_sudah_ada_mencatat_flag_pasang() -> void:
	var s := _sesi()
	_adapter(s)
	s.repositori.pasang("driver-ar9271", s.economy, s.perangkat, false)
	assert_false(s.jaringan.progres.has("pasang:driver-ar9271"), "flag belum ada sebelum apt install")
	var teks := _teks(_apt(s, "apt install driver-ar9271"))
	assert_string_contains(teks, "already the newest version")
	assert_true(s.jaringan.progres.has("pasang:driver-ar9271"), "flag pasang tercatat walau sudah terpasang")
