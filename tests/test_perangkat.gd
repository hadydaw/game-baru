extends GutTest

# Tahap 1: perangkat keras. Pemain mulai tanpa adapter, membeli komponen, merakit, dan menghubungkan
# perangkat. Semua lewat Perangkat, PerangkatCommands, dan sesi yang sama dengan Terminal.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func before_each() -> void:
	Bahasa.kode = "id"

func test_mulai_tanpa_perangkat_apa_pun() -> void:
	var s := _sesi()
	assert_eq(s.perangkat.komponen.size(), 0)
	assert_false(s.perangkat.sudah_dirakit())
	assert_false(s.perangkat.terhubung())

func test_beli_komponen_mengurangi_saldo() -> void:
	var s := _sesi()
	var awal := s.economy.saldo
	var h := s.perangkat.beli("usb_wireless_adapter", s.economy)
	assert_true(bool(h["ok"]))
	assert_eq(s.economy.saldo, awal - 110)
	assert_true(s.perangkat.punya("usb_wireless_adapter"))

func test_beli_ditolak_saat_saldo_kurang() -> void:
	var s := _sesi()
	s.economy.saldo = 10
	var h := s.perangkat.beli("usb_wireless_adapter", s.economy)
	assert_false(bool(h["ok"]))
	assert_eq(s.economy.saldo, 10, "saldo tidak berubah")
	assert_false(s.perangkat.punya("usb_wireless_adapter"))

func test_wifi_hacking_kit_tidak_dijual() -> void:
	var s := _sesi()
	assert_false(bool(s.perangkat.beli("wifi_hacking_kit", s.economy)["ok"]))

func test_rakit_butuh_adapter_antena_dan_kabel() -> void:
	var s := _sesi()
	assert_false(bool(s.perangkat.rakit()["ok"]), "tanpa adapter")
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	assert_false(bool(s.perangkat.rakit()["ok"]), "tanpa antena")
	s.perangkat.beli("antena_eksternal", s.economy)
	assert_false(bool(s.perangkat.rakit()["ok"]), "tanpa kabel")
	s.perangkat.beli("kabel_usb", s.economy)
	assert_true(bool(s.perangkat.rakit()["ok"]))
	assert_true(s.perangkat.sudah_dirakit())
	assert_eq(s.perangkat.adapter(), "usb_wireless_adapter")
	assert_eq(s.perangkat.jumlah("kabel_usb"), 0, "komponen dipakai saat dirakit")

func test_hubungkan_butuh_driver_yang_cocok() -> void:
	var s := _sesi()
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()
	assert_false(bool(PerangkatCommands.hubungkan(s)["ok"]), "tanpa driver")
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	assert_true(bool(PerangkatCommands.hubungkan(s)["ok"]))
	assert_true(s.perangkat.terhubung())
	assert_eq(s.perangkat.driver_aktif(), "driver-ar9271")
	assert_true(s.jaringan.progres.has("device:terhubung"))

func test_chipset_tanpa_driver_ditolak() -> void:
	var s := _sesi()
	s.perangkat.beli("usb_wireless_adapter_rt", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit("usb_wireless_adapter_rt")
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	var h := PerangkatCommands.hubungkan(s)
	assert_false(bool(h["ok"]))
	assert_eq(String(h["kunci"]), "hw.driver_kurang", "driver ar9271 tidak cocok, sehingga dianggap belum ada")

func test_upgrade_antena_dengan_antena_penguat() -> void:
	var s := _sesi()
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()
	assert_false(bool(s.perangkat.upgrade_antena()["ok"]), "tanpa antena penguat")
	s.perangkat.beli("antena_penguat", s.economy)
	assert_true(bool(s.perangkat.upgrade_antena()["ok"]))
	assert_eq(s.perangkat.antena(), 2)

func test_wifi_hacking_kit_menaikkan_antena() -> void:
	var s := _sesi()
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()
	s.perangkat.terima_kit()
	assert_eq(s.perangkat.jumlah("wifi_hacking_kit"), 1)
	assert_eq(s.perangkat.antena(), 2)

func test_terminal_device_list_dan_detect() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("device list")).contains("Belum dirakit"))
	assert_true(_teks(s.jalankan("device detect")).contains("Tidak ada perangkat"))
	s.jalankan("toko beli usb_wireless_adapter")
	assert_true(_teks(s.jalankan("device detect")).contains("belum dirakit"))

func test_terminal_toko_beli_dan_rakit() -> void:
	var s := _sesi()
	s.jalankan("toko beli usb_wireless_adapter")
	s.jalankan("toko beli antena_eksternal")
	s.jalankan("toko beli kabel_usb")
	var t := _teks(s.jalankan("device rakit"))
	assert_true(t.contains("dirakit"))
	assert_true(s.jaringan.progres.has("rakit:wifi_kit"))
	assert_true(s.jaringan.progres.has("beli:usb_wireless_adapter"))

func test_terminal_galat_jika_argumen_kurang() -> void:
	var s := _sesi()
	assert_eq(String(s.jalankan("device upgrade")[0]["tipe"]), "error")
	assert_eq(String(s.jalankan("toko beli")[0]["tipe"]), "error")

func test_perangkat_bertahan_saat_disimpan() -> void:
	var s := _sesi()
	s.perangkat.beli("usb_wireless_adapter", s.economy)
	s.perangkat.beli("antena_eksternal", s.economy)
	s.perangkat.beli("kabel_usb", s.economy)
	s.perangkat.rakit()
	s.repositori.terpasang["driver-ar9271"] = {"versi": "2.0", "riwayat": ["2.0"]}
	PerangkatCommands.hubungkan(s)
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.perangkat.terhubung())
	assert_eq(pulih.perangkat.adapter(), "usb_wireless_adapter")
	assert_true(pulih.repositori.punya("driver-ar9271"))

func test_pasar_komponen_tidak_menampilkan_kit() -> void:
	var s := _sesi()
	var t := _teks(s.jalankan("toko"))
	assert_true(t.contains("usb_wireless_adapter"))
	assert_false(t.contains("wifi_hacking_kit"))
