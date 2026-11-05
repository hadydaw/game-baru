extends GutTest

# Setiap tahap misi 1 membawa pengetahuan dunia nyata, dan email tahap menampilkannya.

func before_each() -> void:
	Bahasa.kode = "id"

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func test_setiap_tahap_misi_1_punya_pengetahuan() -> void:
	var m := Misi.temukan("misi_1")
	assert_eq((m["tahap"] as Array).size(), 10, "misi 1 punya 10 tahap")
	for t in m["tahap"]:
		assert_true(String(t.get("pengetahuan", "")).length() > 40, "pengetahuan terisi: " + String(t["judul"]))

func test_email_tahap_menampilkan_pengetahuan() -> void:
	var s := _sesi()
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	var email_tahap_1 := ""
	for p in s.pesan_misi:
		if String(p["subjek"]).contains("Tahap 1"):
			email_tahap_1 = String(p["isi"])
	assert_true(email_tahap_1.contains("Pengetahuan:"), "email tahap 1 memuat pengetahuan")
	assert_true(email_tahap_1.contains("help"), "isi pengetahuan tahap 1 tampil")
