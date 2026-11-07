extends GutTest

# Perintah man dan pesan galatnya hanya menampilkan satu bahasa, sesuai bahasa aktif.

func after_each() -> void:
	Bahasa.kode = "id"

func _tanpa_penanda(t: String) -> bool:
	return not (t.contains(Bahasa.PEMBUKA) or t.contains(Bahasa.PEMISAH) or t.contains(Bahasa.PENUTUP))

func test_semua_man_satu_bahasa_id() -> void:
	Bahasa.kode = "id"
	for k in Teks.MAN.keys():
		var t := Bahasa.pilih(Teks.man(String(k)))
		assert_true(_tanpa_penanda(t), "man %s tanpa penanda" % k)
		assert_eq(t, String(Teks.MAN[k]), "man %s memakai teks Indonesia" % k)

func test_semua_man_satu_bahasa_en() -> void:
	Bahasa.kode = "en"
	for k in Teks.MAN.keys():
		var t := Bahasa.pilih(Teks.man(String(k)))
		assert_true(_tanpa_penanda(t), "man %s tanpa penanda (en)" % k)
		assert_eq(t, String(Teks.MAN_EN.get(k, Teks.MAN[k])), "man %s memakai teks Inggris" % k)

func test_galat_man_satu_bahasa() -> void:
	Bahasa.kode = "id"
	var id := Bahasa.pilih(Teks.t("man.tidak_ada"))
	assert_false(id.contains("manual entry"), "galat id tidak memuat teks Inggris")
	Bahasa.kode = "en"
	var en := Bahasa.pilih(Teks.t("man.tidak_ada"))
	assert_false(en.contains("Tidak ada"), "galat en tidak memuat teks Indonesia")

func test_tiap_kunci_teks_punya_dua_bahasa() -> void:
	for k in Teks.ID.keys():
		assert_false(String(Teks.ID[k]).is_empty(), "kunci %s tidak kosong" % k)
		if Teks.EN.has(k):
			assert_false(String(Teks.EN[k]).is_empty(), "kunci %s (en) tidak kosong" % k)
