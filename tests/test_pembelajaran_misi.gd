extends GutTest

# Materi pembelajaran tiap tahap Misi 1: terpisah dari tugas, lengkap dengan enam bagian,
# tersedia dalam dua bahasa, dan email tahap hanya mengarahkan pemain ke tombol BELAJAR.

const BAGIAN := ["judul", "konsep", "cara_kerja", "contoh", "hubungan", "ringkasan"]

func before_each() -> void:
	Bahasa.kode = "id"

func after_each() -> void:
	Bahasa.kode = "id"

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func test_setiap_tahap_punya_materi_enam_bagian() -> void:
	var jumlah := (Misi.temukan("misi_1")["tahap"] as Array).size()
	var materi := Misi.pembelajaran("misi_1")
	assert_eq(materi.size(), jumlah, "materi ada untuk setiap tahap")
	for i in range(materi.size()):
		for k in BAGIAN:
			var teks := Bahasa.pilih(String(materi[i].get(k, "")))
			assert_true(teks.length() > (3 if k == "judul" else 20), "tahap %d bagian %s terisi" % [i + 1, k])

func test_materi_tersedia_dalam_dua_bahasa() -> void:
	var materi := Misi.pembelajaran("misi_1")
	for i in range(materi.size()):
		for k in BAGIAN:
			Bahasa.kode = "id"
			var id_teks := Bahasa.pilih(String(materi[i].get(k, "")))
			Bahasa.kode = "en"
			var en_teks := Bahasa.pilih(String(materi[i].get(k, "")))
			assert_ne(id_teks, en_teks, "tahap %d bagian %s punya terjemahan" % [i + 1, k])
			assert_true(en_teks.length() > (3 if k == "judul" else 20), "tahap %d bagian %s dalam bahasa Inggris terisi" % [i + 1, k])

func test_materi_tahap_menolak_nomor_di_luar_rentang() -> void:
	assert_true(Misi.materi_tahap("misi_1", 0).is_empty(), "nomor 0 kosong")
	assert_true(Misi.materi_tahap("misi_1", 27).is_empty(), "nomor di atas jumlah tahap kosong")
	assert_true(Bahasa.pilih(String(Misi.materi_tahap("misi_1", 3)["judul"])).contains("Tahap 3"), "nomor 3 memuat tahap 3")

func test_materi_mencakup_perangkat_yang_dipakai() -> void:
	var materi := Misi.pembelajaran("misi_1")
	var adapter := Bahasa.pilih(String(materi[2]["konsep"]))
	assert_true(adapter.contains("Wireless adapter"), "adapter dijelaskan")
	var antena := Bahasa.pilih(String(materi[3]["cara_kerja"]))
	assert_true(antena.contains("dBi"), "antena menjelaskan dBi")

func test_email_tahap_mengarahkan_ke_tombol_belajar() -> void:
	var s := _sesi()
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	var isi := ""
	for p in s.pesan_misi:
		if Bahasa.pilih(String(p["subjek"])).contains("Tahap 1"):
			isi = Bahasa.pilih(String(p["isi"]))
	assert_true(isi.contains("BELAJAR"), "email tahap menyebut tombol BELAJAR")
	assert_false(isi.contains("Penjelasan Konsep"), "materi lengkap tidak masuk ke email")
	assert_false(isi.contains("Cara Kerja"), "cara kerja tidak masuk ke email")

func test_materi_tidak_memuat_instruksi_tugas() -> void:
	# Bagian konsep dan cara kerja menjelaskan, tidak menyuruh pemain mengetik perintah tugas.
	var materi := Misi.pembelajaran("misi_1")
	for i in range(materi.size()):
		var konsep := Bahasa.pilih(String(materi[i]["konsep"]))
		assert_false(konsep.begins_with("Ketik "), "konsep tahap %d bukan instruksi" % (i + 1))
