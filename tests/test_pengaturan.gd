extends GutTest

# Pengaturan perangkat dan nama profil. Berkas diganti ke berkas uji agar tidak menimpa pengaturan pemain.

const UJI := "user://uji_pengaturan.json"

func before_each() -> void:
	Pengaturan.berkas_aktif = UJI
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))

func after_each() -> void:
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))
	Pengaturan.berkas_aktif = Pengaturan.BERKAS

func test_nilai_awal() -> void:
	assert_eq(Pengaturan.ukuran_teks(), "sedang")
	assert_eq(Pengaturan.ukuran_font(), 26)
	assert_eq(Pengaturan.nama_profil(), "")

func test_ukuran_font_sesuai_pilihan() -> void:
	assert_true(Pengaturan.set_ukuran_teks("kecil"))
	assert_eq(Pengaturan.ukuran_font(), 22)
	assert_true(Pengaturan.set_ukuran_teks("besar"))
	assert_eq(Pengaturan.ukuran_font(), 30)

func test_ukuran_tidak_dikenal_ditolak() -> void:
	assert_false(Pengaturan.set_ukuran_teks("raksasa"))
	assert_eq(Pengaturan.ukuran_teks(), "sedang")

func test_nama_valid_dan_tidak_valid() -> void:
	assert_true(Pengaturan.nama_valid("abc"))
	assert_true(Pengaturan.nama_valid("agen_07"))
	assert_true(Pengaturan.nama_valid("a".repeat(16)))
	assert_false(Pengaturan.nama_valid("ab"))
	assert_false(Pengaturan.nama_valid("a".repeat(17)))
	assert_false(Pengaturan.nama_valid("a b"))
	assert_false(Pengaturan.nama_valid("agen-07"))
	assert_false(Pengaturan.nama_valid(""))

func test_nama_tersimpan_dan_dibaca_ulang() -> void:
	assert_true(Pengaturan.set_nama_profil("agen_07"))
	assert_eq(Pengaturan.nama_profil(), "agen_07")

func test_nama_tidak_valid_tidak_mengubah_profil() -> void:
	Pengaturan.set_nama_profil("agen_07")
	assert_false(Pengaturan.set_nama_profil("x"))
	assert_eq(Pengaturan.nama_profil(), "agen_07")

func test_nama_dan_ukuran_saling_tidak_menimpa() -> void:
	Pengaturan.set_nama_profil("agen_07")
	Pengaturan.set_ukuran_teks("besar")
	assert_eq(Pengaturan.nama_profil(), "agen_07")
	assert_eq(Pengaturan.ukuran_teks(), "besar")

func test_berkas_rusak_memakai_nilai_awal() -> void:
	var f := FileAccess.open(UJI, FileAccess.WRITE)
	f.store_string("{ bukan json")
	f.close()
	assert_eq(Pengaturan.ukuran_teks(), "sedang")
	assert_eq(Pengaturan.nama_profil(), "")

func test_posisi_desktop_awal_kosong() -> void:
	assert_eq(Pengaturan.posisi_desktop(), {})

func test_posisi_desktop_tersimpan_dan_dibaca_ulang() -> void:
	assert_true(Pengaturan.set_posisi_desktop({"misi": [1, 2]}))
	assert_eq(Pengaturan.posisi_desktop(), {"misi": [1, 2]})

func test_posisi_desktop_membuang_id_asing_koordinat_keluar_dan_sel_ganda() -> void:
	Pengaturan.set_posisi_desktop({"misi": [1, 1], "xxx": [0, 0], "peta": [9, 0], "log": [1, 1]})
	assert_eq(Pengaturan.posisi_desktop(), {"misi": [1, 1]})

func test_posisi_desktop_berkas_rusak_diabaikan() -> void:
	var f := FileAccess.open(UJI, FileAccess.WRITE)
	f.store_string('{"posisi_desktop": [1, 2]}')
	f.close()
	assert_eq(Pengaturan.posisi_desktop(), {})

func test_reset_posisi_desktop() -> void:
	Pengaturan.set_posisi_desktop({"misi": [1, 1]})
	assert_true(Pengaturan.reset_posisi_desktop())
	assert_eq(Pengaturan.posisi_desktop(), {})

func test_posisi_tidak_menimpa_pengaturan_lain() -> void:
	Pengaturan.set_nama_profil("agen_07")
	Pengaturan.set_ukuran_teks("besar")
	Pengaturan.set_posisi_desktop({"log": [0, 1]})
	assert_eq(Pengaturan.nama_profil(), "agen_07")
	assert_eq(Pengaturan.ukuran_teks(), "besar")
