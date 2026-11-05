extends GutTest

# E-Mail pemain: status pesan, sampah, sambutan sekali, penyimpanan, dan terjemahan dua bahasa.

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func after_each() -> void:
	Bahasa.kode = "id"

func test_dua_pesan_awal_di_kotak_masuk() -> void:
	var s := _sesi()
	assert_eq(Email.daftar(s, "masuk").size(), 2)
	assert_eq(Email.jumlah_belum_dibaca(s), 2)

func test_baca_menandai_sudah_dibaca() -> void:
	var s := _sesi()
	Email.tandai_dibaca(s, "panduan")
	assert_true(Email.sudah_dibaca(s, "panduan"))
	assert_eq(Email.jumlah_belum_dibaca(s), 1)

func test_hapus_pindah_ke_sampah_dan_bisa_dipulihkan() -> void:
	var s := _sesi()
	Email.pindah_ke_sampah(s, "mira")
	assert_eq(Email.daftar(s, "masuk").size(), 1)
	assert_eq(Email.daftar(s, "sampah").size(), 1)
	Email.pulihkan(s, "mira")
	assert_eq(Email.daftar(s, "masuk").size(), 2)

func test_hapus_permanen_tidak_muncul_lagi() -> void:
	var s := _sesi()
	Email.pindah_ke_sampah(s, "mira")
	Email.hapus_permanen(s, "mira")
	assert_eq(Email.daftar(s, "sampah").size(), 0)
	assert_eq(Email.daftar(s, "masuk").size(), 1)

func test_sambutan_hanya_sekali() -> void:
	var s := _sesi()
	assert_false(Email.sambutan_sudah_tampil(s))
	Email.tandai_sambutan(s)
	assert_true(Email.sambutan_sudah_tampil(s))

func test_status_email_bertahan_setelah_save() -> void:
	var s := _sesi()
	Email.tandai_dibaca(s, "panduan")
	Email.pindah_ke_sampah(s, "mira")
	Email.tandai_sambutan(s)
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(Email.sudah_dibaca(pulih, "panduan"))
	assert_eq(Email.status(pulih, "mira"), "sampah")
	assert_true(Email.sambutan_sudah_tampil(pulih))

func test_semua_teks_email_punya_dua_bahasa() -> void:
	for p in Email.PESAN:
		for kunci in [p["dari"], p["judul"], p["isi"]]:
			Bahasa.kode = "id"
			var id_teks := Bahasa.t(String(kunci))
			Bahasa.kode = "en"
			var en_teks := Bahasa.t(String(kunci))
			assert_ne(id_teks, String(kunci), "id ada untuk %s" % kunci)
			assert_ne(en_teks, String(kunci), "en ada untuk %s" % kunci)
			if String(kunci).ends_with(".dari"):
				continue  # nama pengirim boleh sama di kedua bahasa
			assert_ne(id_teks, en_teks, "terjemahan berbeda untuk %s" % kunci)

func test_pengirim_dan_judul_berganti_bahasa_langsung() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var l := Label.new()
	root.add_child(l)
	Bahasa.isi(l, "email.judul")
	Bahasa.kode = "id"
	Bahasa.set_kode("en")
	assert_eq(l.text, "E-Mail")
	Bahasa.set_kode("id")
	assert_eq(l.text, "E-Mail")
