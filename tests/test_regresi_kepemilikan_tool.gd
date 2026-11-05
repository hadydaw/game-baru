extends GutTest

# Regresi: perintah milik tool hanya aktif setelah tool dimiliki, dan help serta dispatcher konsisten.
# Kasus asal: pemain membeli Packet Inspector, lalu "trace" ditolak karena Signal Tracer belum dibeli.

func _sesi() -> ShellSession:
	var akar := {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}
	var s := ShellSession.new(Vfs.new(akar))
	s.economy.tambah(5000)
	return s

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(Bahasa.pilih(String(b["teks"]))) + "\n"
	return t

func _tidak_ditemukan(hasil: Array) -> bool:
	return hasil.size() > 0 and String(hasil[0]["tipe"]) == "error" and Bahasa.pilih(String(hasil[0]["teks"])).ends_with("perintah tidak ditemukan")

func test_trace_ditolak_sebelum_signal_tracer_dibeli() -> void:
	var s := _sesi()
	s.jalankan("ping -c 1 gerbang")
	assert_true(_tidak_ditemukan(s.jalankan("trace gerbang")))
	assert_false(s.inventory.punya("signal_tracer"))

func test_pembelian_signal_tracer_membuka_trace() -> void:
	var s := _sesi()
	s.jalankan("ping -c 1 gerbang")
	assert_true(bool(s.market.beli("a2", s)["ok"]), "pembelian a2 berhasil")
	assert_true(s.inventory.punya("signal_tracer"))
	var hasil := s.jalankan("trace gerbang")
	assert_false(_tidak_ditemukan(hasil), "setelah dibeli, trace harus dikenali")
	assert_true(_teks(hasil).contains("relay"))

func test_pembelian_packet_inspector_tidak_membuka_trace() -> void:
	var s := _sesi()
	s.market.beli("a1", s)
	assert_true(_tidak_ditemukan(s.jalankan("trace gerbang")), "tool lain tidak membuka trace")
	assert_false(_tidak_ditemukan(s.jalankan("tools")))

func test_help_konsisten_dengan_dispatcher() -> void:
	var s := _sesi()
	s.inventory.miliki("signal_tracer", "black_market", 1)
	var help := _teks(s.jalankan("help"))
	for nama in Teks.MAN.keys():
		var dikenal := CommandRegistry.tersedia(s, String(nama))
		assert_eq(help.contains("  " + String(nama) + "\n"), dikenal, "help konsisten untuk %s" % nama)
		if dikenal and CommandRegistry.pemilik(String(nama)) != "":
			assert_false(_tidak_ditemukan(s.jalankan(String(nama))), "dispatcher mengenali %s" % nama)

func test_setiap_perintah_milik_tool_punya_manual() -> void:
	for id in ToolDefs.DEFS:
		for c in ToolDefs.perintah(String(id)):
			assert_true(Teks.MAN.has(String(c)), "manual untuk %s hilang" % c)
			assert_eq(CommandRegistry.pemilik(String(c)), String(id), "%s terdaftar ke %s" % [c, id])

func test_perintah_tanpa_pemilik_selalu_tersedia() -> void:
	var kosong := _sesi()
	kosong.inventory = Inventory.new()
	for nama in ["ping", "nmap", "ls", "cd", "wallet", "bm", "tools", "device", "toko"]:
		assert_true(CommandRegistry.tersedia(kosong, nama), "%s tidak perlu tool" % nama)
