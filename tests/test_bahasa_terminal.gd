extends GutTest

# Kunci terminal harus berbeda teksnya antara ID dan EN, dan kembali ke ID setelah diganti.
func after_each() -> void:
	Bahasa.set_kode("id")

func test_kunci_terminal_berganti_bahasa() -> void:
	Bahasa.set_kode("id")
	var id_teks := Bahasa.t("term.siap")
	Bahasa.set_kode("en")
	var en_teks := Bahasa.t("term.siap")
	assert_ne(id_teks, en_teks)
	assert_true(en_teks.contains("Terminal ready"))
	assert_true(id_teks.contains("Terminal siap"))

func test_kunci_tanpa_terjemahan_tidak_kosong() -> void:
	for k in ["term.siap", "wifi.akses"]:
		assert_true(Bahasa.KAMUS.has(k))
		assert_false(String(Bahasa.KAMUS[k]["en"]).is_empty())
		assert_false(String(Bahasa.KAMUS[k]["id"]).is_empty())
