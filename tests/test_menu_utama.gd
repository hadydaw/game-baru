extends GutTest

# Menu utama: urutan tombol, Lanjutkan (cek simpanan), Sesi Baru (konfirmasi dan arsip), Login, Pengaturan, Keluar.
# Semua berkas simpanan dan pengaturan memakai jalur uji.

const SIMPANAN := "user://uji_menu_simpanan.json"
const PENGATURAN := "user://uji_menu_pengaturan.json"

var _menu: MenuUtama

func _hapus(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _hapus_semua_uji() -> void:
	_hapus(SIMPANAN)
	_hapus(SIMPANAN + ".bak")
	_hapus(PENGATURAN)
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	for f in dir.get_files():
		if String(f).begins_with("uji_menu_simpanan.json.") or String(f).begins_with("uji_menu_simpanan.json.bak.lama"):
			dir.remove(String(f))

func before_each() -> void:
	Penyimpanan.berkas_aktif = SIMPANAN
	Pengaturan.berkas_aktif = PENGATURAN
	_hapus_semua_uji()
	SesiUtama.reset()

func after_each() -> void:
	if is_instance_valid(_menu):
		_menu.free()
	_hapus_semua_uji()
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	Pengaturan.berkas_aktif = Pengaturan.BERKAS
	SesiUtama.reset()

func _buat_menu() -> MenuUtama:
	_menu = MenuUtama.new()
	_menu.size = Vector2(1080, 1920)
	add_child(_menu)
	return _menu

func _simpan_contoh() -> void:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))
	Penyimpanan.simpan_sesi(s, SIMPANAN)

func _teks_tombol(m: Node) -> Array:
	var hasil: Array = []
	for anak in m.find_children("*", "Button", true, false):
		var t := String((anak as Button).text)
		if t.begins_with("> "):
			hasil.append(t)
	return hasil

func test_lima_tombol_sesuai_urutan() -> void:
	var m := _buat_menu()
	assert_eq(_teks_tombol(m), ["> Sesi Baru", "> Lanjutkan", "> Login", "> Pengaturan", "> Keluar"])

func test_lanjutkan_nonaktif_tanpa_simpanan() -> void:
	var m := _buat_menu()
	assert_true((m._tombol["lanjutkan"] as Button).disabled)

func test_lanjutkan_aktif_dengan_simpanan() -> void:
	_simpan_contoh()
	var m := _buat_menu()
	assert_false((m._tombol["lanjutkan"] as Button).disabled)

func test_lanjutkan_memberi_sinyal_lanjut() -> void:
	_simpan_contoh()
	var m := _buat_menu()
	watch_signals(m)
	m._aksi_lanjutkan()
	assert_signal_emitted_with_parameters(m, "mulai", ["lanjut"])

func test_sesi_baru_tanpa_simpanan_langsung_mulai() -> void:
	var m := _buat_menu()
	watch_signals(m)
	m._aksi_sesi_baru()
	assert_signal_emitted_with_parameters(m, "mulai", ["baru"])

func test_sesi_baru_dengan_simpanan_meminta_konfirmasi_dulu() -> void:
	_simpan_contoh()
	var m := _buat_menu()
	watch_signals(m)
	m._aksi_sesi_baru()
	assert_signal_not_emitted(m, "mulai", "belum ada mulai sebelum konfirmasi")
	assert_true(FileAccess.file_exists(SIMPANAN), "simpanan belum diarsipkan sebelum konfirmasi")

func test_sesi_baru_mengarsipkan_simpanan_lama() -> void:
	_simpan_contoh()
	var m := _buat_menu()
	watch_signals(m)
	m._jalankan_sesi_baru()
	assert_signal_emitted_with_parameters(m, "mulai", ["baru"])
	assert_false(FileAccess.file_exists(SIMPANAN), "simpanan utama dipindahkan")
	assert_false(Penyimpanan.ada_simpanan(SIMPANAN), "tidak ada simpanan aktif setelah sesi baru")
	var dir := DirAccess.open("user://")
	var ada_arsip := false
	for f in dir.get_files():
		if String(f).begins_with("uji_menu_simpanan.json.lama-"):
			ada_arsip = true
	assert_true(ada_arsip, "arsip simpanan lama tersimpan dengan akhiran waktu")

func test_arsipkan_tanpa_simpanan_tidak_melakukan_apa_apa() -> void:
	assert_eq(Penyimpanan.arsipkan(SIMPANAN), "")

func test_login_nama_valid_disimpan_dan_tampil() -> void:
	var m := _buat_menu()
	m._input_nama.text = "agen_07"
	m._simpan_login()
	assert_eq(Pengaturan.nama_profil(), "agen_07")
	assert_true((m._tombol["login"] as Button).text.contains("agen_07"))

func test_login_nama_tidak_valid_menampilkan_galat() -> void:
	var m := _buat_menu()
	m._input_nama.text = "ab"
	m._simpan_login()
	assert_eq(Pengaturan.nama_profil(), "")
	assert_false(m._lbl_error_login.text.is_empty())

func test_pengaturan_ukuran_teks_disimpan() -> void:
	var m := _buat_menu()
	m._pilih_ukuran("besar")
	assert_eq(Pengaturan.ukuran_teks(), "besar")
	assert_eq(Pengaturan.ukuran_font(), 30)

func test_keluar_memberi_sinyal() -> void:
	var m := _buat_menu()
	watch_signals(m)
	(m._tombol["keluar"] as Button).pressed.emit()
	assert_signal_emitted(m, "keluar_diminta")

func test_terminal_memakai_ukuran_teks_pengaturan() -> void:
	Pengaturan.set_ukuran_teks("besar")
	TerminalScreen.reset_sesi()
	var layar := TerminalScreen.new()
	add_child(layar)
	assert_eq(layar._keluaran.get_theme_font_size("normal_font_size"), 30)
	remove_child(layar)
	layar.free()
	TerminalScreen.reset_sesi()
