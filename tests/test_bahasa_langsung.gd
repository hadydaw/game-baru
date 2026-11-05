extends GutTest

# Pergantian bahasa saat game berjalan: teks yang sudah tampil ikut berubah tanpa restart.

const UJI := "user://uji_bahasa_langsung.json"

func before_each() -> void:
	Pengaturan.berkas_aktif = UJI
	Bahasa.kode = "id"

func after_each() -> void:
	Bahasa.kode = "id"
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))

func test_label_berubah_saat_bahasa_diganti() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var l := Label.new()
	root.add_child(l)
	Bahasa.isi(l, "umum.batal")
	assert_eq(l.text, "Batal")
	Bahasa.set_kode("en")
	assert_eq(l.text, "Cancel")
	Bahasa.set_kode("id")
	assert_eq(l.text, "Batal")

func test_teks_dengan_argumen_ikut_bahasa() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var l := Label.new()
	root.add_child(l)
	Bahasa.isi(l, "pasar.saldo", [5, "x", 2])
	var sebelum := l.text
	Bahasa.set_kode("en")
	assert_ne(l.text, sebelum)

func test_penyegar_dipanggil_saat_bahasa_berganti() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var hitung := [0]
	var l := Label.new()
	root.add_child(l)
	Bahasa.daftar_penyegar(l, func(): hitung[0] += 1)
	assert_eq(hitung[0], 1)
	Bahasa.set_kode("en")
	assert_eq(hitung[0], 2)

func test_ganti_bahasa_tidak_mengubah_pengaturan_lain() -> void:
	Pengaturan.set_ukuran_teks("besar")
	Pengaturan.set_nama_profil("operator")
	Pengaturan.set_bahasa("en")
	assert_eq(Pengaturan.ukuran_teks(), "besar")
	assert_eq(Pengaturan.nama_profil(), "operator")
	assert_eq(Pengaturan.bahasa(), "en")

func test_bolak_balik_id_en_id_tanpa_restart() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var l := Label.new()
	root.add_child(l)
	Bahasa.isi(l, "umum.kembali")
	var awal := l.text
	Bahasa.set_kode("en")
	Bahasa.set_kode("id")
	assert_eq(l.text, awal)
