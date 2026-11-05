extends GutTest

# Regresi: tujuan "Jalankan perintah help di terminal" harus tercatat, tampil selesai di layar misi,
# dan tetap selesai setelah save lalu muat ulang.

func before_each() -> void:
	Bahasa.kode = "id"

func _sesi() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	return s

func _tujuan_help_selesai(s: ShellSession) -> bool:
	var m := Misi.temukan("misi_1")
	for t in Misi.tahap_progres(s, m)[0]["tujuan"]:
		if String(t["teks"]).contains("help"):
			return bool(t["selesai"])
	return false

func test_help_mencatat_flag_dan_centang() -> void:
	var s := _sesi()
	assert_false(_tujuan_help_selesai(s))
	s.jalankan("help")
	assert_true(s.jaringan.progres.has("cmd:help"), "flag cmd:help harus tercatat")
	assert_true(_tujuan_help_selesai(s), "tujuan help harus tampil selesai")

func test_help_bertahan_setelah_muat_ulang() -> void:
	var s := _sesi()
	s.jalankan("help")
	var d := s.to_dict()
	var muat := ShellSession.dari_dict(d)
	assert_true(muat.jaringan.progres.has("cmd:help"))
	assert_true(_tujuan_help_selesai(muat))
