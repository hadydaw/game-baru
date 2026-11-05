extends GutTest

# Tahap 3a: saldo Kr, reputasi grup, perintah wallet, dan penyimpanan keadaan ekonomi.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func test_saldo_awal_500() -> void:
	assert_eq(Economy.baru().saldo, 500)

func test_bayar_mengurangi_saldo() -> void:
	var e := Economy.new(500)
	assert_true(e.bayar(200))
	assert_eq(e.saldo, 300)

func test_bayar_melebihi_saldo_ditolak_tanpa_perubahan() -> void:
	var e := Economy.new(100)
	assert_false(e.bayar(101))
	assert_eq(e.saldo, 100, "saldo tidak berubah")

func test_saldo_tidak_pernah_negatif() -> void:
	var e := Economy.new(50)
	assert_false(e.bayar(-5), "harga negatif ditolak")
	assert_eq(e.saldo, 50)
	e.bayar(50)
	assert_eq(e.saldo, 0)
	assert_false(e.bayar(1))
	assert_eq(e.saldo, 0)

func test_tambah_hadiah() -> void:
	var e := Economy.new(0)
	e.tambah(300)
	assert_eq(e.saldo, 300)
	e.tambah(-100)
	assert_eq(e.saldo, 300, "tambah dengan nilai negatif diabaikan")

func test_ambang_reputasi_25_50_75() -> void:
	assert_eq(Reputation.tingkat(0), "tanpa")
	assert_eq(Reputation.tingkat(24), "tanpa")
	assert_eq(Reputation.tingkat(25), "anggota")
	assert_eq(Reputation.tingkat(49), "anggota")
	assert_eq(Reputation.tingkat(50), "menengah")
	assert_eq(Reputation.tingkat(74), "menengah")
	assert_eq(Reputation.tingkat(75), "elite")
	assert_eq(Reputation.tingkat(100), "elite")

func test_reputasi_dibatasi_0_sampai_100() -> void:
	var r := Reputation.baru()
	var g := "kolektif_senja"
	r.ubah(g, 150)
	assert_eq(r.get_nilai(g), 100)
	r.ubah(g, -500)
	assert_eq(r.get_nilai(g), 0)

func test_reputasi_awal_nol_untuk_grup_data() -> void:
	assert_eq(Reputation.baru().get_nilai("kolektif_senja"), 0)
	assert_eq(Bahasa.pilih(Reputation.nama_grup("kolektif_senja")), "Kolektif Senja")

func test_wallet_menampilkan_saldo_dan_reputasi() -> void:
	var s := _sesi()
	s.reputation.ubah("kolektif_senja", 30)
	var t := _teks(s.jalankan("wallet"))
	assert_true(t.contains("Saldo: 500 Kr"))
	assert_true(t.contains("Kolektif Senja: 30 (anggota)"))

func test_wallet_ada_di_manual() -> void:
	assert_true(_teks(_sesi().jalankan("man wallet")).contains("wallet"))
	assert_true(_teks(_sesi().jalankan("help")).contains("wallet"))

func test_keadaan_ekonomi_bertahan_lewat_to_dict() -> void:
	var s := _sesi()
	s.economy.bayar(120)
	s.reputation.ubah("kolektif_senja", 55)
	var d := s.to_dict()
	var pulih := ShellSession.dari_dict(d)
	assert_eq(pulih.economy.saldo, 380)
	assert_eq(pulih.reputation.get_nilai("kolektif_senja"), 55)

func test_save_lama_tanpa_ekonomi_memakai_nilai_awal() -> void:
	var s := _sesi()
	var d := s.to_dict()
	d.erase("ekonomi")
	d.erase("reputasi")
	var pulih := ShellSession.dari_dict(d)
	assert_eq(pulih.economy.saldo, 500)
	assert_eq(pulih.reputation.get_nilai("kolektif_senja"), 0)

func test_sesi_ssh_memakai_saldo_yang_sama() -> void:
	var pemilik := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-xr-x"}
	var dokumen := pemilik.duplicate()
	dokumen["isi"] = {"kunci_arsip.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "arsip:TK-7731", "ukuran": 13}}
	var operator := pemilik.duplicate()
	operator["isi"] = {"dokumen": dokumen}
	var akar := {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x",
		"isi": {"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": operator}}}}
	var s := ShellSession.new(Vfs.new(akar))
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("scan 10.7.0.8")
	s.jalankan("ssh operator@arsip")
	assert_not_null(s.ssh_aktif, "ssh berhasil dengan kunci di filesystem uji")
	s.ssh_aktif.economy.bayar(100)
	assert_eq(s.economy.saldo, 400, "pembayaran dari sesi jarak jauh mengurangi saldo pemain")
	assert_eq(s.ssh_aktif.economy, s.economy, "objek ekonomi sama")
