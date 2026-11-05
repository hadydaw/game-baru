extends GutTest

# Tahap 3e: hadiah misi (sekali per flag), unlock tool lewat misi, grup, penemuan, dan hadiah kontak.

func _sesi() -> ShellSession:
	var operator := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {
		"catatan_relay.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----",
			"isi": "Relay berada di 10.7.0.4.", "penemuan": "catatan_relay", "ukuran": 25},
	}}
	var akar := {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
		"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": operator}}}}
	return ShellSession.new(Vfs.new(akar))

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func test_misi_memberi_hadiah_kredit_dan_reputasi() -> void:
	var s := _sesi()
	var r := Hadiah.selesaikan_misi(s, "misi_relay")
	assert_true(bool(r["hadiah"]))
	assert_eq(s.economy.saldo, 800, "500 awal + 300 hadiah")
	assert_eq(s.reputation.get_nilai("kolektif_senja"), 10)

func test_hadiah_hanya_sekali_per_flag() -> void:
	var s := _sesi()
	Hadiah.selesaikan_misi(s, "misi_relay")
	var kedua := Hadiah.selesaikan_misi(s, "misi_relay")
	assert_false(bool(kedua["hadiah"]))
	assert_eq(s.economy.saldo, 800, "saldo tidak bertambah dua kali")
	assert_eq(s.reputation.get_nilai("kolektif_senja"), 10)

func test_misi_membuka_node_dan_memulihkan_stok_pasar() -> void:
	var s := _sesi()
	s.market.stok["b1"] = 0
	Hadiah.selesaikan_misi(s, "misi_relay")
	assert_true(s.jaringan.progres.has("misi_relay"))
	assert_eq(s.market.sisa("b1"), 2, "stok pulih karena flag misi")

func test_misi_memberi_tool_dan_membuka_unlock() -> void:
	var s := _sesi()
	s.inventory.miliki("network_scanner", "awal", 1)
	var r := Hadiah.selesaikan_misi(s, "misi_relay")
	assert_true(s.inventory.punya("network_scanner"))
	assert_eq(s.inventory.tingkat("network_scanner"), 2, "tool awal dinaikkan oleh hadiah")
	assert_eq(s.inventory.sumber("crypt_decoder"), "misi", "crypt decoder terbuka oleh flag misi")
	assert_true(s.inventory.punya("crypt_decoder"))
	assert_true((r["unlock"] as Array).has("crypt_decoder"))

func test_hadiah_kontak_membuka_tool_tingkat_2() -> void:
	var s := _sesi()
	Hadiah.selesaikan_misi(s, "misi_relay")
	assert_true(s.jaringan.progres.has("kontak:makelar"))
	assert_eq(s.inventory.tingkat("packet_inspector"), 2)
	assert_eq(s.inventory.sumber("packet_inspector"), "hadiah_kontak")

func test_unlock_grup_saat_reputasi_mencapai_ambang() -> void:
	var s := _sesi()
	assert_false(s.inventory.punya("password_analyzer"))
	s.reputation.ubah("kolektif_senja", 25)
	UnlockRules.evaluasi(s)
	assert_true(s.inventory.punya("password_analyzer"))
	assert_eq(s.inventory.sumber("password_analyzer"), "grup")

func test_unlock_penemuan_saat_berkas_dibaca() -> void:
	var s := _sesi()
	assert_false(s.inventory.punya("signal_tracer"))
	s.jalankan("cat catatan_relay.txt")
	assert_true(s.inventory.punya("signal_tracer"))
	assert_eq(s.inventory.sumber("signal_tracer"), "penemuan")

func test_unlock_tidak_memberi_tool_dua_kali() -> void:
	var s := _sesi()
	s.jalankan("cat catatan_relay.txt")
	var kedua := UnlockRules.evaluasi(s)
	assert_false(kedua.has("signal_tracer"))

func test_status_hadiah_dan_unlock_bertahan() -> void:
	var s := _sesi()
	Hadiah.selesaikan_misi(s, "misi_relay")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.hadiah_diambil.has("misi_relay"))
	assert_true(pulih.jaringan.progres.has("misi_relay"))
	assert_true(pulih.inventory.punya("crypt_decoder"))
	var r := Hadiah.selesaikan_misi(pulih, "misi_relay")
	assert_false(bool(r["hadiah"]), "hadiah tidak diberikan ulang setelah dimuat")

func test_flag_tanpa_hadiah_tetap_membuka_node() -> void:
	var s := _sesi()
	var r := Hadiah.selesaikan_misi(s, "misi_tanpa_hadiah")
	assert_false(bool(r["hadiah"]))
	assert_true(s.jaringan.progres.has("misi_tanpa_hadiah"))

func test_tool_yang_sudah_dibeli_tidak_diturunkan_unlock() -> void:
	var s := _sesi()
	s.inventory.miliki("packet_inspector", "black_market", 3)
	Hadiah.selesaikan_misi(s, "misi_relay")
	assert_eq(s.inventory.tingkat("packet_inspector"), 3, "unlock tingkat 2 tidak menurunkan tingkat 3")
