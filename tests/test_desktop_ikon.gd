extends GutTest

# Pindah ikon Desktop: ikon diletakkan bebas di sel grid, posisi tersimpan, dan reset kembali ke awal.

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

func _desktop_baru() -> DesktopView:
	var x := DesktopView.new()
	add_child(x)
	return x

func _buang(x: DesktopView) -> void:
	remove_child(x)
	x.free()

func _pusat_sel(sel: Vector2i) -> Vector2:
	return d._area.get_global_rect().position + Vector2((sel.x + 0.5) * d._cw, (sel.y + 0.5) * d._ch)

func test_posisi_awal_berurutan_dari_kiri_atas() -> void:
	assert_eq(d._posisi["terminal"], Vector2i(0, 0))
	assert_eq(d._posisi["tools"], Vector2i(3, 0))
	assert_eq(d._posisi["misi"], Vector2i(2, 1))
	assert_eq(d._posisi.size(), DesktopView.APLIKASI.size())

func test_posisi_tersimpan_dipakai_saat_desktop_dibuat_ulang() -> void:
	Pengaturan.set_posisi_desktop({"log": [2, 2]})
	var x := _desktop_baru()
	assert_eq(x._posisi["log"], Vector2i(2, 2))
	_buang(x)

func test_ikon_diletakkan_di_sel_kosong_dan_tetap_di_sana() -> void:
	assert_true(d._pindahkan_ke("log", Vector2i(3, 2)))
	assert_eq(d._posisi["log"], Vector2i(3, 2))
	var x := _desktop_baru()
	assert_eq(x._posisi["log"], Vector2i(3, 2), "setelah dibuat ulang tetap di tempat")
	_buang(x)

func test_sel_terisi_dicari_sel_kosong_terdekat() -> void:
	# Baris 0 dan 1 penuh, dan (0,2) ditempati E-Mail. Sel kosong terdekat dari (0,0) adalah (1,2).
	d._pindahkan_ke("log", Vector2i(0, 0))
	assert_eq(d._posisi["log"], Vector2i(1, 2))
	assert_eq(d._posisi["terminal"], Vector2i(0, 0), "ikon yang sudah ada tidak berpindah")

func test_lepas_di_luar_grid_masuk_sel_tepi_terdekat() -> void:
	var sel := d._sel_di_bawah(Vector2(-500, -500))
	assert_eq(sel, Vector2i(0, 0))
	d._pindahkan_ke("log", sel)
	assert_eq(d._posisi["log"], Vector2i(1, 2), "tidak kembali ke posisi lama")

func test_reset_mengembalikan_posisi_awal() -> void:
	d._pindahkan_ke("log", Vector2i(3, 2))
	assert_true(Pengaturan.reset_posisi_desktop())
	var x := _desktop_baru()
	assert_eq(x._posisi["log"], Vector2i(3, 1))
	_buang(x)

func test_pindah_ikon_tidak_dikenal_ditolak() -> void:
	assert_false(d._pindahkan_ke("tidak_ada", Vector2i(0, 0)))

func test_tekan_tahan_memicu_mode_pindah() -> void:
	d._tahan_id = "terminal"
	d._mulai_pindah()
	assert_eq(d._pindah_id, "terminal")
	assert_true(d._tahan_terpicu, "ketuk berikutnya diabaikan")
	d._selesai_pindah(_pusat_sel(Vector2i(0, 0)))
	assert_eq(d._pindah_id, "")
	assert_eq(d._posisi["terminal"], Vector2i(0, 0), "lepas di tempat sendiri tidak mengubah posisi")

func test_ikon_mengikuti_pointer_dan_penanda_menunjukkan_sel_tujuan() -> void:
	d._tahan_id = "log"
	d._mulai_pindah()
	assert_not_null(d._hantu, "salinan ikon dibuat")
	assert_not_null(d._penanda, "penanda sel dibuat")
	var pos := _pusat_sel(Vector2i(3, 2))
	d._sorot_tujuan(pos)
	assert_almost_eq(d._hantu.global_position, pos - d._hantu.size * 0.5, Vector2(1, 1), "salinan berada di bawah jari")
	assert_eq(d._penanda.position, Vector2(3 * d._cw, 2 * d._ch), "penanda di sel tujuan")
	d._selesai_pindah(pos)
	assert_null(d._hantu, "salinan dihapus setelah lepas")
	assert_eq(d._posisi["log"], Vector2i(3, 2))

func test_ketuk_biasa_tetap_membuka_aplikasi() -> void:
	watch_signals(d)
	d._ketuk_sel("peta")
	assert_signal_emitted_with_parameters(d, "buka_aplikasi", ["peta"])

func test_ketuk_setelah_tekan_tahan_tidak_membuka_aplikasi() -> void:
	watch_signals(d)
	d._tahan_terpicu = true
	d._ketuk_sel("peta")
	assert_signal_not_emitted(d, "buka_aplikasi")

func test_reset_susunan_terdengar_di_panel_pengaturan() -> void:
	var m := MenuUtama.new()
	add_child(m)
	await get_tree().process_frame
	m._aksi_atur_ulang_ikon()
	assert_true(m._lbl_hint_pengaturan.text.contains("dikembalikan"), "umpan balik terlihat di panel")
	remove_child(m)
	m.free()
