extends GutTest

# Tahap 3b: inventaris tool, perintah yang dibatasi tool, nmap -sV dan firewall, inspeksi, dan trace.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func _galat(hasil: Array) -> bool:
	return hasil.size() > 0 and String(hasil[0]["tipe"]) == "error"

func test_inventaris_awal_kosong() -> void:
	var inv := Inventory.baru()
	assert_false(inv.punya("network_scanner"))
	assert_false(inv.punya("packet_inspector"))
	assert_eq(inv.milik.size(), 0)

func test_tool_tidak_bisa_dimiliki_dua_kali() -> void:
	var inv := Inventory.baru()
	assert_true(inv.miliki("signal_tracer", "black_market"))
	assert_false(inv.miliki("signal_tracer", "misi"), "kepemilikan kedua ditolak")
	assert_eq(inv.sumber("signal_tracer"), "black_market")

func test_naikkan_tingkat_dibatasi_maks() -> void:
	var inv := Inventory.baru()
	inv.miliki("network_scanner", "awal", 1)
	assert_true(inv.naikkan("network_scanner"))
	assert_true(inv.naikkan("network_scanner"))
	assert_false(inv.naikkan("network_scanner"), "tingkat maksimal 3")
	assert_eq(inv.tingkat("network_scanner"), 3)
	assert_false(inv.naikkan("crypt_decoder"), "tool tidak dimiliki tidak bisa naik")

func test_inventaris_bertahan_lewat_to_dict() -> void:
	var s := _sesi()
	s.inventory.miliki("packet_inspector", "misi", 2)
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.inventory.punya("packet_inspector"))
	assert_eq(pulih.inventory.tingkat("packet_inspector"), 2)
	assert_eq(pulih.inventory.sumber("packet_inspector"), "misi")

func test_perintah_tool_tanpa_kepemilikan_tidak_ditemukan() -> void:
	var s := _sesi()
	var hasil := s.jalankan("inspeksi gerbang")
	assert_true(_galat(hasil))
	assert_true(_teks(hasil).contains("perintah tidak ditemukan"))
	assert_false(_teks(s.jalankan("help")).contains("inspeksi"), "help tidak menampilkan perintah yang belum aktif")

func test_help_menampilkan_perintah_tool_yang_dimiliki() -> void:
	var s := _sesi()
	s.inventory.miliki("signal_tracer", "misi")
	assert_true(_teks(s.jalankan("help")).contains("trace"))

func test_tools_menampilkan_daftar() -> void:
	var s := _sesi()
	s.inventory.miliki("network_scanner", "awal", 1)
	assert_true(_teks(s.jalankan("tools")).contains("Network Scanner"))
	var kosong := _sesi()
	kosong.inventory = Inventory.new()
	assert_true(_teks(kosong.jalankan("tools")).contains("Tidak ada tool"))

func test_nmap_sv_butuh_scanner_tingkat_2() -> void:
	var s := _sesi()
	s.inventory.miliki("network_scanner", "uji", 1)
	s.jalankan("ping -c 1 gerbang")
	assert_true(_galat(s.jalankan("nmap -sV gerbang")), "tingkat 1 tidak punya -sV")
	s.inventory.naikkan("network_scanner")
	var t := _teks(s.jalankan("nmap -sV gerbang"))
	assert_true(t.contains("VERSI"))
	assert_true(t.contains("JTN-SSH 2.1"))

func test_nmap_firewall_hanya_tingkat_3() -> void:
	var s := _sesi()
	s.inventory.miliki("network_scanner", "uji", 1)
	s.jalankan("ping -c 1 gerbang")
	assert_false(_teks(s.jalankan("nmap gerbang")).contains("Firewall"))
	s.inventory.naikkan("network_scanner")
	s.inventory.naikkan("network_scanner")
	assert_true(_teks(s.jalankan("nmap gerbang")).contains("Firewall: tingkat 0"))

func test_inspeksi_butuh_host_sudah_dipindai() -> void:
	var s := _sesi()
	s.inventory.miliki("packet_inspector", "awal")
	s.jalankan("ping -c 1 gerbang")
	assert_true(_teks(s.jalankan("inspeksi gerbang")).contains("belum dipindai"))
	s.jalankan("nmap gerbang")
	assert_true(_teks(s.jalankan("inspeksi gerbang")).contains("Log transfer gerbang"))

func test_inspeksi_tingkat_1_menyamarkan_alamat_tujuan() -> void:
	var s := _sesi()
	s.inventory.miliki("packet_inspector", "awal", 1)
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("nmap gerbang")
	var t := _teks(s.jalankan("inspeksi gerbang"))
	assert_true(t.contains("***.***.***.***"))
	assert_false(t.contains("10.7.0.8"))

func test_inspeksi_tingkat_2_menampilkan_alamat() -> void:
	var s := _sesi()
	s.inventory.miliki("packet_inspector", "awal", 2)
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("nmap gerbang")
	assert_true(_teks(s.jalankan("inspeksi gerbang")).contains("10.7.0.8"))

func test_trace_tingkat_1_menampilkan_satu_hop_dan_menemukan_node() -> void:
	var s := _sesi()
	s.inventory.miliki("signal_tracer", "awal", 1)
	s.jalankan("ping -c 1 gerbang")
	var t := _teks(s.jalankan("trace gerbang"))
	assert_true(t.contains("relay"))
	assert_true(s.jaringan.dikenal("relay"), "node satu hop biasa menjadi terlihat")
	assert_false(t.contains("arsip"), "node khusus scan tidak tampil sebelum scan")
	assert_false(s.jaringan.dikenal("arsip"), "node khusus scan tidak terbuka oleh trace")
	assert_false(s.jaringan.dikenal("server_kota"), "dua hop belum terlihat di tingkat 1")

func test_trace_tingkat_3_menampilkan_seluruh_jaringan_dan_menyamarkan_terkunci() -> void:
	var s := _sesi()
	s.inventory.miliki("signal_tracer", "awal", 3)
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("scan 10.7.0.8")
	var t := _teks(s.jalankan("trace gerbang"))
	assert_true(t.contains("server_kota"))
	assert_true(t.contains("terkunci"))
	assert_false(s.jaringan.dikenal("server_kota"), "node terkunci tidak terungkap")
	assert_true(s.jaringan.dikenal("arsip"), "arsip terbuka setelah scan")

func test_status_pemindaian_bertahan() -> void:
	var s := _sesi()
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("nmap gerbang")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.jaringan.sudah_dipindai("gerbang"))
	assert_false(pulih.jaringan.sudah_dipindai("arsip"))
