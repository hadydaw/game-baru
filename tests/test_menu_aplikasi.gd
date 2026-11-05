extends GutTest

# Menu Aplikasi: kategori, pencarian, buka aplikasi, dan tombol Keluar ke Menu Utama.

var m: MenuAplikasi

func before_each() -> void:
	Bahasa.kode = "id"
	m = MenuAplikasi.new()
	add_child(m)

func after_each() -> void:
	remove_child(m)
	m.free()

func test_kategori_sistem_default() -> void:
	assert_eq(m.daftar_terlihat(), ["terminal", "berkas", "log"])

func test_pindah_kategori_menampilkan_aplikasinya() -> void:
	m._pilih_kategori("jaringan")
	assert_eq(m.daftar_terlihat(), ["peta", "tools"])
	m._pilih_kategori("pasar")
	assert_eq(m.daftar_terlihat(), ["pasar", "misi"])
	m._pilih_kategori("komunitas")
	assert_eq(m.daftar_terlihat(), ["forum", "email"])

func test_semua_aplikasi_punya_kategori() -> void:
	var semua := []
	for k in MenuAplikasi.KATEGORI:
		semua.append_array(k["apl"])
	semua.sort()
	var daftar := []
	for a in DesktopView.APLIKASI:
		daftar.append(a["id"])
	daftar.sort()
	assert_eq(semua, daftar, "setiap aplikasi tampil di tepat satu kategori")

func test_cari_mencocokkan_nama_dari_semua_kategori() -> void:
	m._cari.text = "jaring"
	m._saat_cari("jaring")
	assert_eq(m.daftar_terlihat(), ["peta"], "Peta Jaringan cocok")

func test_cari_tanpa_hasil_menampilkan_pesan() -> void:
	m._cari.text = "xyzzy"
	m._saat_cari("xyzzy")
	assert_eq(m.daftar_terlihat().size(), 0)
	assert_eq(m._grid.get_child_count(), 1, "label kosong tampil")

func test_ketuk_aplikasi_memancarkan_id() -> void:
	watch_signals(m)
	m._grid.get_child(1).pressed.emit()
	assert_signal_emitted_with_parameters(m, "buka_aplikasi", ["berkas"])

func test_tombol_keluar_memancarkan_keluar() -> void:
	watch_signals(m)
	var keluar: Button = m.find_children("*", "Button", true, false).back()
	keluar.pressed.emit()
	assert_signal_emitted(m, "keluar_diminta")

func test_latar_diketuk_meminta_tutup() -> void:
	watch_signals(m)
	var latar: ColorRect = m.get_child(0)
	var klik := InputEventMouseButton.new()
	klik.button_index = MOUSE_BUTTON_LEFT
	klik.pressed = true
	latar.gui_input.emit(klik)
	assert_signal_emitted(m, "tutup_diminta")
