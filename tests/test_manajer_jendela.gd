extends GutTest

# Uji manajer jendela untuk Android portrait: buka, fokus, minimize, pulihkan, maximize, dan tutup.

const IKON := "res://assets/ikon/aplikasi/app_terminal.png"
const KERJA := Rect2(Vector2(14, 90), Vector2(692, 1000))
const PENUH := Rect2(Vector2(14, 14), Vector2(692, 1252))

var m: ManajerJendela

func before_each() -> void:
	m = ManajerJendela.new()
	add_child(m)
	m.atur_area(KERJA, PENUH)

func after_each() -> void:
	remove_child(m)
	m.free()

func _buka(id: String) -> JendelaAplikasi:
	return m.buka(id, id.capitalize(), IKON, Control.new())

func test_buka_menambah_jendela_dan_menjadi_aktif() -> void:
	_buka("terminal")
	assert_eq(m.jumlah(), 1)
	assert_true(m.ada("terminal"))
	assert_eq(m.aktif(), "terminal")

func test_buka_ulang_memfokuskan_tanpa_duplikasi() -> void:
	_buka("terminal")
	_buka("peta")
	_buka("terminal")
	assert_eq(m.jumlah(), 2, "tidak ada jendela ganda")
	assert_eq(m.aktif(), "terminal", "jendela yang dibuka ulang menjadi aktif")

func test_jendela_mengisi_area_kerja() -> void:
	var j := _buka("terminal")
	assert_eq(j.position, KERJA.position)
	assert_eq(j.size, KERJA.size)

func test_minimize_menyembunyikan_dan_daftar_tetap_ada() -> void:
	var j := _buka("terminal")
	m.minimize("terminal")
	assert_false(j.visible)
	assert_true(j.diminimize)
	assert_true(m.ada("terminal"), "jendela tetap terdaftar di taskbar")
	assert_eq(m.aktif(), "", "tidak ada jendela aktif")

func test_fokus_memulihkan_jendela_yang_diminimize() -> void:
	var j := _buka("terminal")
	m.minimize("terminal")
	m.fokus("terminal")
	assert_true(j.visible)
	assert_false(j.diminimize)
	assert_eq(m.aktif(), "terminal")

func test_fokus_menaikkan_jendela_ke_atas() -> void:
	_buka("terminal")
	_buka("peta")
	m.fokus("terminal")
	assert_eq(m.aktif(), "terminal")
	var terakhir: JendelaAplikasi = m.get_child(m.get_child_count() - 1)
	assert_eq(terakhir.id, "terminal", "jendela aktif tampil paling atas")

func test_minimize_jendela_aktif_memilih_jendela_sebelumnya() -> void:
	_buka("terminal")
	_buka("peta")
	m.minimize("peta")
	assert_eq(m.aktif(), "terminal", "jendela lain yang terlihat menjadi aktif")

func test_maximize_mengisi_layar_penuh_lalu_kembali() -> void:
	var j := _buka("terminal")
	m.toggle_maksimal("terminal")
	assert_true(j.maksimal)
	assert_eq(j.size, PENUH.size)
	m.toggle_maksimal("terminal")
	assert_false(j.maksimal)
	assert_eq(j.size, KERJA.size)

func test_tutup_menghapus_jendela() -> void:
	_buka("terminal")
	_buka("peta")
	m.tutup("terminal")
	assert_false(m.ada("terminal"))
	assert_eq(m.jumlah(), 1)
	assert_eq(m.aktif(), "peta")

func test_tutup_jendela_terakhir_tanpa_aktif() -> void:
	_buka("terminal")
	m.tutup("terminal")
	assert_eq(m.jumlah(), 0)
	assert_eq(m.aktif(), "")

func test_daftar_taskbar_berurutan_dengan_status() -> void:
	_buka("terminal")
	_buka("peta")
	m.minimize("terminal")
	var d := m.daftar()
	assert_eq(d.size(), 2)
	assert_eq(String(d[0]["id"]), "terminal")
	assert_true(bool(d[0]["diminimize"]))
	assert_false(bool(d[0]["aktif"]))
	assert_eq(String(d[1]["id"]), "peta")
	assert_true(bool(d[1]["aktif"]))

func test_atur_area_berlaku_untuk_jendela_terbuka() -> void:
	var j := _buka("terminal")
	var baru := Rect2(Vector2(0, 80), Vector2(720, 1100))
	m.atur_area(baru, Rect2(Vector2(0, 0), Vector2(720, 1280)))
	assert_eq(j.size, baru.size)
