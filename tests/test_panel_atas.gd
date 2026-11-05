extends GutTest

# Uji panel atas Desktop: saldo dari sesi, ikon notifikasi, tanggal, dan tombol menu aplikasi.

var p: PanelAtas

func before_each() -> void:
	SesiUtama.reset()
	p = PanelAtas.new()
	add_child(p)

func after_each() -> void:
	remove_child(p)
	p.free()
	SesiUtama.reset()

func _sesi(saldo: int = 500) -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))
	s.economy.saldo = saldo
	return s

func _tombol_logo() -> TextureButton:
	return p.find_children("*", "TextureButton", true, false)[0]

func test_format_tanggal_indonesia() -> void:
	var w := {"weekday": 4, "day": 5, "month": 11, "year": 2026}
	assert_eq(PanelAtas.format_tanggal(w), "Kam, 5 Nov 2026")

func test_saldo_mengikuti_sesi_bukan_nilai_tetap() -> void:
	SesiUtama.sesi = _sesi(730)
	p.segarkan()
	assert_eq(p._saldo.text, "Kr 730", "saldo dibaca dari ekonomi pemain")

func test_saldo_berubah_setelah_segarkan() -> void:
	var s := _sesi(500)
	SesiUtama.sesi = s
	p.segarkan()
	s.economy.saldo = 120
	p.segarkan()
	assert_eq(p._saldo.text, "Kr 120")

func test_notifikasi_kosong_tanpa_misi_aktif() -> void:
	SesiUtama.sesi = _sesi()
	p.segarkan()
	assert_eq(p._notif.texture.resource_path, "res://assets/ikon/sistem/sys_notifikasi_kosong.png")

func test_notifikasi_pesan_saat_misi_aktif() -> void:
	var s := _sesi()
	s.misi["misi_1"] = "aktif"
	SesiUtama.sesi = s
	p.segarkan()
	assert_eq(p._notif.texture.resource_path, "res://assets/ikon/sistem/sys_notifikasi_pesan.png")

func test_notifikasi_kosong_setelah_misi_selesai() -> void:
	var s := _sesi()
	s.misi["misi_1"] = "selesai"
	SesiUtama.sesi = s
	p.segarkan()
	assert_false(PanelAtas.ada_misi_aktif(s))
	assert_eq(p._notif.texture.resource_path, "res://assets/ikon/sistem/sys_notifikasi_kosong.png")

func test_tombol_logo_memancarkan_menu_aplikasi() -> void:
	SesiUtama.sesi = _sesi()
	watch_signals(p)
	_tombol_logo().pressed.emit()
	assert_signal_emitted(p, "menu_aplikasi_diminta")

func test_jam_dan_tanggal_terisi() -> void:
	SesiUtama.sesi = _sesi()
	p.segarkan()
	assert_true(p._jam.text.length() == 5 and p._jam.text.contains(":"), "format jam HH:MM")
	assert_false(p._tanggal.text.is_empty(), "tanggal terisi")
