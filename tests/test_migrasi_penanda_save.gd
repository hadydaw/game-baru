extends GutTest

# Save lama menyimpan penanda dua-bahasa sebagai karakter kontrol. Saat dimuat, penanda itu dirapikan
# menjadi penanda cetak, dan teks pengirim tetap tampil sesuai bahasa.

func after_each() -> void:
	Bahasa.kode = "id"

func _ada_kontrol(teks: String) -> bool:
	for i in range(teks.length()):
		if teks.unicode_at(i) < 32:
			return true
	return false

func test_save_lama_dirapikan_saat_dimuat() -> void:
	var d := {"pesan_misi": [{"misi": "misi_1", "dari": "\u0001Agensi\u0002Agency\u0003", "subjek": "\u0001Tahap 1\u0002Stage 1\u0003", "isi": "x", "dilaporkan": false, "tahap": 1.0}]}
	var s := ShellSession.dari_dict(d)
	var p: Dictionary = s.pesan_misi[0]
	assert_false(_ada_kontrol(String(p["dari"])), "pengirim tidak lagi memakai karakter kontrol")
	assert_false(_ada_kontrol(String(p["subjek"])), "subjek tidak lagi memakai karakter kontrol")
	Bahasa.kode = "en"
	assert_eq(Bahasa.pilih(String(p["dari"])), "Agency")
	Bahasa.kode = "id"
	assert_eq(Bahasa.pilih(String(p["dari"])), "Agensi")
