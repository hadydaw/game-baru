extends GutTest

# Pindah ikon Desktop: urutan mengikuti Pengaturan, pindah menyimpan susunan, reset kembali ke awal.

const UJI := "user://uji_desktop_ikon.json"

var d: DesktopView

func before_each() -> void:
	Pengaturan.berkas_aktif = UJI
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))
	SesiUtama.reset()
	d = DesktopView.new()
	add_child(d)

func after_each() -> void:
	remove_child(d)
	d.free()
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))
	Pengaturan.berkas_aktif = Pengaturan.BERKAS
	SesiUtama.reset()

func _urutan_grid() -> Array:
	var hasil: Array = []
	for c in d._grid.get_children():
		hasil.append(String(c.get_meta("id")))
	return hasil

func test_urutan_bawaan_mengikuti_daftar_aplikasi() -> void:
	assert_eq(_urutan_grid(), DesktopView.urutan_id())
	assert_eq(_urutan_grid().size(), DesktopView.APLIKASI.size())

func test_urutan_mengikuti_pengaturan() -> void:
	Pengaturan.set_susunan_desktop(["log", "terminal"])
	var baru := DesktopView.new()
	add_child(baru)
	var hasil: Array = []
	for c in baru._grid.get_children():
		hasil.append(String(c.get_meta("id")))
	remove_child(baru)
	baru.free()
	assert_eq(hasil[0], "log")
	assert_eq(hasil[1], "terminal")
	assert_eq(hasil.size(), DesktopView.APLIKASI.size(), "aplikasi lain tetap ada")

func test_pindah_ikon_mengubah_urutan_dan_menyimpan() -> void:
	assert_true(d._pindahkan_ikon("log", 0))
	assert_eq(_urutan_grid()[0], "log")
	assert_eq(Pengaturan.susunan_desktop()[0], "log", "susunan tersimpan")

func test_pindah_ikon_bertahan_setelah_desktop_dibuat_ulang() -> void:
	d._pindahkan_ikon("misi", 1)
	var kedua := DesktopView.new()
	add_child(kedua)
	assert_eq(String(kedua._grid.get_child(1).get_meta("id")), "misi")
	remove_child(kedua)
	kedua.free()

func test_pindah_ikon_tidak_dikenal_ditolak() -> void:
	assert_false(d._pindahkan_ikon("tidak_ada", 0))
	assert_eq(_urutan_grid(), DesktopView.urutan_id())

func test_reset_mengembalikan_urutan_bawaan() -> void:
	d._pindahkan_ikon("log", 0)
	Pengaturan.reset_susunan_desktop()
	var kedua := DesktopView.new()
	add_child(kedua)
	var hasil: Array = []
	for c in kedua._grid.get_children():
		hasil.append(String(c.get_meta("id")))
	remove_child(kedua)
	kedua.free()
	assert_eq(hasil, DesktopView.APLIKASI.map(func(a): return a["id"]))

func test_tekan_tahan_memicu_mode_pindah() -> void:
	var t := d._tombol_id("terminal")
	d._tahan_id = "terminal"
	d._mulai_pindah()
	assert_eq(d._pindah_id, "terminal")
	assert_true(d._tahan_terpicu, "ketuk berikutnya diabaikan")
	d._selesai_pindah(t.get_global_rect().get_center())
	assert_eq(d._pindah_id, "")
	assert_eq(_urutan_grid()[0], "terminal", "lepas di tempat sendiri tidak mengubah urutan")

func test_ketuk_biasa_tetap_membuka_aplikasi() -> void:
	watch_signals(d)
	d._ketuk_sel("peta")
	assert_signal_emitted_with_parameters(d, "buka_aplikasi", ["peta"])

func test_ketuk_setelah_tekan_tahan_tidak_membuka_aplikasi() -> void:
	watch_signals(d)
	d._tahan_terpicu = true
	d._ketuk_sel("peta")
	assert_signal_not_emitted(d, "buka_aplikasi")
