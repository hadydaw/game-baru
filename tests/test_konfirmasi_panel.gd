extends GutTest

# Komponen dialog konfirmasi JTN: teks dan tombol terisi, sinyal benar, dan tetap di dalam layar HP.

func _panel(ukuran: Vector2) -> KonfirmasiPanel:
	var wadah := Control.new()
	wadah.size = ukuran
	add_child(wadah)
	var p := KonfirmasiPanel.new()
	wadah.add_child(p)
	p.atur_aman(Vector4.ZERO)
	return p

func test_tampil_mengisi_teks_dan_menampilkan_panel() -> void:
	var p := _panel(Vector2(1080, 1920))
	await get_tree().process_frame
	assert_false(p.visible, "tersembunyi sebelum dipanggil")
	p.tampil("Judul uji", "Isi uji", "Ya uji", "Tidak uji")
	assert_true(p.visible)
	assert_eq(p._judul.text, "Judul uji")
	assert_eq(p._isi.text, "Isi uji")
	assert_eq(p._tombol_ya.text, "Ya uji")
	assert_eq(p._tombol_batal.text, "Tidak uji")
	p.get_parent().free()

func test_tombol_memancarkan_sinyal_yang_benar() -> void:
	var p := _panel(Vector2(1080, 1920))
	await get_tree().process_frame
	p.tampil("a", "b", "c", "d")
	watch_signals(p)
	p._tombol_ya.pressed.emit()
	assert_signal_emitted(p, "diterima")
	assert_signal_not_emitted(p, "dibatalkan")
	p._tombol_batal.pressed.emit()
	assert_signal_emitted(p, "dibatalkan")
	p.get_parent().free()

func test_sembunyikan_menutup_panel() -> void:
	var p := _panel(Vector2(1080, 1920))
	await get_tree().process_frame
	p.tampil("a", "b", "c", "d")
	p.sembunyikan()
	assert_false(p.visible)
	p.get_parent().free()

func test_teks_panjang_membungkus_dan_tetap_di_layar() -> void:
	for ukuran in [Vector2(1080, 1920), Vector2(720, 1280), Vector2(1080, 2340)]:
		var p := _panel(ukuran)
		await get_tree().process_frame
		p.tampil("Mulai sesi baru?", "Simpanan lama tidak dihapus permanen. Ia dipindahkan ke arsip di perangkat, lalu sesi dimulai dari awal. " .repeat(3), "Mulai Baru", "Batal")
		await get_tree().process_frame
		await get_tree().process_frame
		var r := p._tombol_ya.get_global_rect()
		assert_true(r.position.x >= 0 and r.end.x <= ukuran.x, "tombol Ya di dalam lebar %s" % ukuran)
		assert_true(r.end.y <= ukuran.y, "tombol Ya di dalam tinggi %s" % ukuran)
		assert_true(p._isi.get_global_rect().end.x <= ukuran.x, "teks tidak melebar keluar %s" % ukuran)
		assert_true(p._tombol_ya.get_global_rect().size.y >= 80, "tombol cukup tinggi untuk disentuh")
		p.get_parent().free()
