extends GutTest

# Tahap 3d: Black Market (penjual, syarat reputasi, stok, kelangkaan, pembelian) dan perintah bm.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += String(b["teks"]) + "\n"
	return t

func _galat(hasil: Array) -> bool:
	return hasil.size() > 0 and String(hasil[0]["tipe"]) == "error"

func test_empat_penjual_dengan_syarat_bertingkat() -> void:
	assert_eq(BlackMarket.penjual_ids(), ["a", "b", "c", "d"])
	assert_eq(BlackMarket.penjual("a")["syarat_rep"], 0)
	assert_eq(BlackMarket.penjual("c")["syarat_rep"], 50)
	assert_eq(BlackMarket.penjual("d")["syarat_rep"], 75)

func test_penjual_terbuka_sesuai_reputasi() -> void:
	var r := Reputation.baru()
	assert_true(BlackMarket.penjual_terbuka("a", r))
	assert_false(BlackMarket.penjual_terbuka("c", r))
	r.ubah("kolektif_senja", 50)
	assert_true(BlackMarket.penjual_terbuka("c", r))
	assert_false(BlackMarket.penjual_terbuka("d", r))

func test_beli_mengurangi_saldo_dan_memberi_tool() -> void:
	var s := _sesi()
	var hasil := s.market.beli("a1", s)
	assert_true(bool(hasil["ok"]))
	assert_eq(s.economy.saldo, 500 - 400, "Packet Inspector tingkat 1 seharga 400")
	assert_true(s.inventory.punya("packet_inspector"))
	assert_eq(s.inventory.tingkat("packet_inspector"), 1)
	assert_eq(s.inventory.sumber("packet_inspector"), "black_market")
	assert_eq(s.market.sisa("a1"), 4, "stok berkurang satu")

func test_beli_gagal_saldo_tidak_cukup_tanpa_perubahan() -> void:
	var s := _sesi()
	s.economy.bayar(300)  # saldo 200
	var hasil := s.market.beli("a1", s)
	assert_false(bool(hasil["ok"]))
	assert_eq(s.economy.saldo, 200)
	assert_false(s.inventory.punya("packet_inspector"))
	assert_eq(s.market.sisa("a1"), 5, "stok tidak berkurang")

func test_beli_penjual_terkunci_ditolak() -> void:
	var s := _sesi()
	var hasil := s.market.beli("c1", s)
	assert_false(bool(hasil["ok"]))
	assert_eq(s.economy.saldo, 500)

func test_beli_stok_habis_ditolak() -> void:
	var s := _sesi()
	s.economy.tambah(10000)
	s.market.stok["d1"] = 0
	assert_false(bool(s.market.beli("d1", s)["ok"]))

func test_beli_tool_yang_sudah_dimiliki_ditolak() -> void:
	var s := _sesi()
	s.economy.tambah(5000)
	s.market.beli("a1", s)
	assert_false(bool(s.market.beli("a1", s)["ok"]), "tingkat sama sudah dimiliki")

func test_peningkatan_tingkat_lewat_black_market() -> void:
	var s := _sesi()
	s.economy.tambah(5000)
	s.inventory.miliki("packet_inspector", "awal", 1)
	# c2 menjual Packet Inspector tingkat 2 (butuh reputasi 50).
	s.reputation.ubah("kolektif_senja", 50)
	var hasil := s.market.beli("c2", s)
	assert_true(bool(hasil["ok"]))
	assert_eq(s.inventory.tingkat("packet_inspector"), 2)
	assert_eq(s.inventory.sumber("packet_inspector"), "awal", "sumber tetap asal kepemilikan")
	assert_eq(s.economy.saldo, 5500 - 1000)

func test_status_item_sesuai_kepemilikan() -> void:
	var s := _sesi()
	assert_eq(s.market.status_item("a1", s.inventory), "tersedia")
	s.inventory.miliki("packet_inspector", "awal", 1)
	assert_eq(s.market.status_item("a1", s.inventory), "dimiliki")
	s.reputation.ubah("kolektif_senja", 50)
	assert_eq(s.market.status_item("c2", s.inventory), "upgrade")

func test_pulih_stok_berdasarkan_flag() -> void:
	var m := BlackMarket.baru()
	m.stok["b1"] = 0
	m.pulihkan_untuk_flag("flag_lain")
	assert_eq(m.sisa("b1"), 0)
	m.pulihkan_untuk_flag("misi_relay")
	assert_eq(m.sisa("b1"), 2)

func test_stok_bertahan_lewat_to_dict() -> void:
	var s := _sesi()
	s.economy.tambah(1000)
	s.market.beli("a2", s)
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_eq(pulih.market.sisa("a2"), 4)
	assert_eq(pulih.economy.saldo, s.economy.saldo)

func test_bm_daftar_penjual_menampilkan_status() -> void:
	var t := _teks(_sesi().jalankan("bm"))
	assert_true(t.contains("Penjual A"))
	assert_true(t.contains("[butuh reputasi 50]"))

func test_bm_katalog_dan_info() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("bm a")).contains("Packet Inspector"))
	assert_true(_teks(s.jalankan("bm info a1")).contains("Harga: 400 Kr"))

func test_bm_penjual_terkunci_tidak_menampilkan_katalog() -> void:
	assert_true(_teks(_sesi().jalankan("bm c")).contains("Belum terbuka"))

func test_bm_beli_lewat_terminal() -> void:
	var s := _sesi()
	var hasil := s.jalankan("bm beli a1")
	assert_false(_galat(hasil))
	assert_true(_teks(hasil).contains("Dibeli"))
	assert_true(s.inventory.punya("packet_inspector"))

func test_bm_beli_gagal_menampilkan_galat() -> void:
	var s := _sesi()
	assert_true(_galat(s.jalankan("bm beli c1")))
	assert_true(_galat(s.jalankan("bm beli tidak_ada")))

func test_bm_penjual_tidak_dikenal() -> void:
	assert_true(_galat(_sesi().jalankan("bm xyz")))

func test_perintah_bm_tersedia_tanpa_tool() -> void:
	assert_true(_teks(_sesi().jalankan("help")).contains("bm"))
