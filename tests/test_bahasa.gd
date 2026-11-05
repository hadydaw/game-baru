extends GutTest

# Bahasa antarmuka: default Indonesia, pilihan tersimpan, dan terjemahan dengan cadangan Indonesia.

const UJI := "user://uji_bahasa.json"

func before_each() -> void:
	Pengaturan.berkas_aktif = UJI
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))
	Bahasa.kode = Bahasa.KODE_AWAL

func after_each() -> void:
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))
	Pengaturan.berkas_aktif = Pengaturan.BERKAS
	Bahasa.kode = Bahasa.KODE_AWAL

func test_default_bahasa_indonesia() -> void:
	assert_eq(Pengaturan.bahasa(), "id")
	assert_eq(Bahasa.t("pengaturan.bahasa"), "Bahasa")

func test_pilih_english_tersimpan_dan_aktif() -> void:
	assert_true(Pengaturan.set_bahasa("en"))
	assert_eq(Pengaturan.bahasa(), "en")
	assert_eq(Bahasa.kode, "en")
	assert_eq(Bahasa.t("pengaturan.bahasa"), "Language")

func test_bahasa_tidak_dikenal_ditolak() -> void:
	assert_false(Pengaturan.set_bahasa("fr"))
	assert_eq(Pengaturan.bahasa(), "id")

func test_bahasa_dimuat_ulang_dari_berkas() -> void:
	Pengaturan.set_bahasa("en")
	Bahasa.kode = Bahasa.KODE_AWAL
	Bahasa.muat_dari_pengaturan()
	assert_eq(Bahasa.kode, "en")

func test_berkas_rusak_bahasa_kembali_ke_default() -> void:
	var f := FileAccess.open(UJI, FileAccess.WRITE)
	f.store_string('{"bahasa": "xx"}')
	f.close()
	assert_eq(Pengaturan.bahasa(), "id")

func test_bahasa_tidak_menimpa_pengaturan_lain() -> void:
	Pengaturan.set_nama_profil("agen_07")
	Pengaturan.set_ukuran_teks("besar")
	Pengaturan.set_bahasa("en")
	assert_eq(Pengaturan.nama_profil(), "agen_07")
	assert_eq(Pengaturan.ukuran_teks(), "besar")

func test_kunci_tanpa_terjemahan_memakai_indonesia() -> void:
	Bahasa.kode = "en"
	assert_eq(Bahasa.t("kunci_tidak_ada"), "kunci_tidak_ada", "kunci tak dikenal dikembalikan apa adanya")
