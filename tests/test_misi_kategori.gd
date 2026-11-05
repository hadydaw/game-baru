extends GutTest

# Misi Tersedia: sembilan kategori dengan ikon, misi dikelompokkan per kategori, dan terjemahan lengkap.

func after_each() -> void:
	Bahasa.kode = "id"

func test_sembilan_kategori_dengan_ikon() -> void:
	assert_eq(Misi.KATEGORI.size(), 9)
	for k in Misi.KATEGORI:
		var path := Misi.ikon_kategori(String(k["kunci"]))
		assert_true(ResourceLoader.exists(path), "ikon ada: %s" % path)

func test_misi_pertama_ada_di_tutorial() -> void:
	var tutorial := Misi.daftar_kategori("tutorial")
	assert_eq(tutorial.size(), 1)
	assert_eq(String(tutorial[0]["id"]), "misi_1")

func test_kategori_lain_kosong_dan_tidak_error() -> void:
	for k in Misi.KATEGORI:
		var kunci := String(k["kunci"])
		if kunci == "tutorial":
			continue
		assert_eq(Misi.daftar_kategori(kunci).size(), 0, kunci)

func test_judul_kategori_punya_dua_bahasa() -> void:
	for k in Misi.KATEGORI:
		Bahasa.kode = "id"
		var a := Bahasa.t(String(k["judul"]))
		Bahasa.kode = "en"
		var b := Bahasa.t(String(k["judul"]))
		assert_ne(a, String(k["judul"]))
		assert_ne(b, String(k["judul"]))
		if String(k["judul"]) != "misi.kat.hacktivism" and String(k["judul"]) != "misi.kat.tutorial":
			assert_ne(a, b, String(k["judul"]))

func test_pusat_misi_tampilkan_kisi_lalu_daftar() -> void:
	var p := PusatMisi.new()
	add_child_autofree(p)
	assert_true(p._kisi_wrap.visible)
	p._pilih_kategori("tutorial")
	p._tampil_daftar = "tutorial"
	p._segarkan_semua()
	assert_false(p._kisi_wrap.visible)
	assert_true(p._daftar_wrap.visible)
	p._tampil_daftar = ""
	p._segarkan_semua()
	assert_true(p._kisi_wrap.visible)
