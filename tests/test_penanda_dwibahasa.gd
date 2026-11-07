extends GutTest

# Penanda dua-bahasa harus cetak (tidak memakai karakter kontrol) agar save tetap JSON standar,
# dan penanda lama (karakter kontrol) tetap bisa dibaca serta dirapikan saat save dimuat.

func after_each() -> void:
	Bahasa.kode = "id"

func _ada_kontrol(teks: String) -> bool:
	for i in range(teks.length()):
		var c := teks.unicode_at(i)
		if c < 32:
			return true
	return false

func test_dua_tidak_memakai_karakter_kontrol() -> void:
	var t := Bahasa.dua("Agensi", "Agency")
	assert_false(_ada_kontrol(t), "penanda dua-bahasa tidak boleh karakter kontrol")
	var json := JSON.stringify({"dari": t})
	var parser := JSON.new()
	assert_eq(parser.parse(json), OK, "hasil stringify bisa diurai ulang")

func test_pilih_sesuai_bahasa_aktif() -> void:
	var t := Bahasa.dua("Agensi", "Agency")
	Bahasa.kode = "id"
	assert_eq(Bahasa.pilih(t), "Agensi")
	Bahasa.kode = "en"
	assert_eq(Bahasa.pilih(t), "Agency")

func test_penanda_lama_tetap_dibaca() -> void:
	var lama := "\u0001Agensi\u0002Agency\u0003"
	Bahasa.kode = "en"
	assert_eq(Bahasa.pilih(lama), "Agency")
	Bahasa.kode = "id"
	assert_eq(Bahasa.pilih(lama), "Agensi")

func test_rapikan_menghapus_karakter_kontrol() -> void:
	var lama := "\u0001Agensi\u0002Agency\u0003"
	var rapi := Bahasa.rapikan(lama)
	assert_false(_ada_kontrol(rapi), "setelah dirapikan tidak ada karakter kontrol")
	assert_eq(rapi, Bahasa.dua("Agensi", "Agency"))
