extends GutTest

# Uji hotbar: favorit selalu tampil, jendela terbuka ikut tampil, dan perilaku ketuk seperti taskbar.

func _status(id: String, aktif: bool, minim: bool) -> Dictionary:
	return {"id": id, "judul": id, "aktif": aktif, "diminimize": minim}

func test_hotbar_menampilkan_favorit_tanpa_jendela() -> void:
	var h := HotBar.new()
	add_child(h)
	h.segarkan([])
	assert_eq(h.jumlah_aplikasi(), HotBar.FAVORIT.size(), "favorit tampil meski belum ada jendela")
	h.free()

func test_jendela_bukan_favorit_ditambahkan_di_belakang() -> void:
	var h := HotBar.new()
	add_child(h)
	h.segarkan([_status("arsip_baru", true, false)])
	assert_eq(h.jumlah_aplikasi(), HotBar.FAVORIT.size() + 1)
	h.free()

func test_jendela_favorit_tidak_duplikat() -> void:
	var h := HotBar.new()
	add_child(h)
	h.segarkan([_status("terminal", true, false)])
	assert_eq(h.jumlah_aplikasi(), HotBar.FAVORIT.size(), "terminal tampil sekali")
	h.free()

func test_tombol_home_memancarkan_sinyal() -> void:
	var h := HotBar.new()
	add_child(h)
	watch_signals(h)
	h.find_child("TombolHome", true, false).pressed.emit()
	assert_signal_emitted(h, "home_diminta")
	h.free()

func test_ketuk_aplikasi_memancarkan_id() -> void:
	var h := HotBar.new()
	add_child(h)
	h.segarkan([])
	watch_signals(h)
	var kolom: Control = h._baris.get_child(1)
	(kolom.get_child(0) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(h, "aplikasi_diketuk", [HotBar.FAVORIT[0]])
	h.free()

# Perilaku ketuk hotbar di DesktopView: buka, fokus, lalu minimize.
func test_ketuk_membuka_aplikasi_yang_belum_terbuka() -> void:
	var d := DesktopView.new()
	add_child(d)
	var m := ManajerJendela.new()
	add_child(m)
	m.atur_area(Rect2(0, 0, 720, 1000), Rect2(0, 0, 720, 1280))
	d.hubungkan_jendela(m)
	watch_signals(d)
	d._ketuk_aplikasi("terminal")
	assert_signal_emitted_with_parameters(d, "buka_aplikasi", ["terminal"])
	m.free()
	d.free()

func test_ketuk_aktif_meminimize_lalu_ketuk_memulihkan() -> void:
	var d := DesktopView.new()
	add_child(d)
	var m := ManajerJendela.new()
	add_child(m)
	m.atur_area(Rect2(0, 0, 720, 1000), Rect2(0, 0, 720, 1280))
	d.hubungkan_jendela(m)
	m.buka("terminal", "Terminal", "res://assets/ikon/aplikasi/app_terminal.png", Control.new())
	d._ketuk_aplikasi("terminal")
	assert_true(m.daftar()[0]["diminimize"], "ketuk jendela aktif meminimize")
	d._ketuk_aplikasi("terminal")
	assert_false(m.daftar()[0]["diminimize"], "ketuk jendela minimized memulihkan")
	m.free()
	d.free()
