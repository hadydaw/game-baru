extends GutTest

# Uji integrasi Tab di layar Terminal: tombol Tab di keyboard virtual JTN, Tab dari keyboard fisik/HP,
# posisi kursor, daftar pilihan, dan memastikan Tab tidak menjalankan perintah.

func before_each() -> void:
	TerminalScreen._sesi_bersama = null
	TerminalScreen._buffer_bersama = ""
	TerminalScreen._scroll_bersama = 0.0
	TerminalScreen._ikut_bawah_bersama = true
	var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
	var data: Dictionary = JSON.parse_string(isi)
	SesiUtama.sesi = ShellSession.new(Vfs.new(data["/"]))

func _buka() -> TerminalScreen:
	var layar := TerminalScreen.new()
	add_child(layar)
	return layar

func _tutup(layar: TerminalScreen) -> void:
	remove_child(layar)
	layar.free()

func _ketik(layar: TerminalScreen, teks: String, kursor: int = -1) -> void:
	layar._masukan.text = teks
	layar._masukan.caret_column = teks.length() if kursor < 0 else kursor

func _tab_fisik(layar: TerminalScreen) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_TAB
	ev.physical_keycode = KEY_TAB
	ev.pressed = true
	layar._tekan_masukan(ev)

func test_tombol_tab_melengkapi_perintah() -> void:
	var layar := _buka()
	_ketik(layar, "ca")
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "cat ")
	assert_eq(layar._masukan.caret_column, 4, "kursor di akhir hasil")
	_tutup(layar)

func test_tombol_tab_tidak_menjalankan_perintah() -> void:
	var layar := _buka()
	_ketik(layar, "ca")
	var riwayat := SesiUtama.sesi.riwayat.size()
	layar._tekan_tombol("Tab")
	assert_eq(SesiUtama.sesi.riwayat.size(), riwayat, "Tab tidak menambah riwayat")
	assert_eq(layar._masukan.text, "cat ", "teks belum dijalankan, masih di kolom perintah")
	_tutup(layar)

func test_tab_fisik_menjalankan_autocomplete_bukan_pindah_fokus() -> void:
	var layar := _buka()
	_ketik(layar, "cd dok")
	_tab_fisik(layar)
	assert_eq(layar._masukan.text, "cd dokumen/")
	_tutup(layar)

func test_tab_mempertahankan_teks_setelah_kursor() -> void:
	var layar := _buka()
	_ketik(layar, "cat dokumen/jad xyz", "cat dokumen/ja".length())
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "cat dokumen/jadwal.txt d xyz", "teks sesudah kursor dipertahankan")
	assert_eq(layar._masukan.caret_column, "cat dokumen/jadwal.txt ".length(), "kursor tetap di akhir bagian yang dilengkapi")
	_tutup(layar)

func test_tab_tanpa_kecocokan_tidak_mengubah_teks() -> void:
	var layar := _buka()
	_ketik(layar, "zzz")
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "zzz")
	_tutup(layar)

func test_banyak_kecocokan_menampilkan_daftar() -> void:
	var layar := _buka()
	_ketik(layar, "c")
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "c", "awalan bersama tidak bertambah")
	var teks := layar._keluaran.get_parsed_text()
	assert_true(teks.contains("cat") and teks.contains("cd") and teks.contains("clear"), "daftar pilihan ditampilkan")
	_tutup(layar)

func test_tab_tidak_mengubah_masukan_saat_teks_kosong_dan_aman() -> void:
	var layar := _buka()
	_ketik(layar, "")
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "", "tanpa kata, teks tetap kosong")
	_tutup(layar)

func test_saat_ssh_aktif_tab_memakai_sesi_jarak_jauh() -> void:
	var layar := _buka()
	var jauh := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
		"rahasia.txt": {"tipe": "file", "pemilik": "root", "grup": "root", "izin": "rw-r--r--", "isi": "x", "ukuran": 1}}}))
	jauh.cwd = "/"
	SesiUtama.sesi.ssh_aktif = jauh
	_ketik(layar, "cat rah")
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "cat rahasia.txt ", "berkas di server jarak jauh dilengkapi")
	SesiUtama.sesi.ssh_aktif = null
	_tutup(layar)

func test_saat_airodump_hidup_tab_diabaikan() -> void:
	var layar := _buka()
	_ketik(layar, "ca")
	layar._live = true
	layar._tekan_tombol("Tab")
	assert_eq(layar._masukan.text, "ca", "input shell tidak diproses saat airodump-ng berjalan")
	layar._live = false
	_tutup(layar)

func test_saat_perintah_berjalan_daftar_tidak_dicetak() -> void:
	var layar := _buka()
	_ketik(layar, "c")
	var keluaran_sebelum := layar._keluaran.get_parsed_text()
	layar._busy = true
	layar._tekan_tombol("Tab")
	layar._busy = false
	assert_eq(layar._keluaran.get_parsed_text(), keluaran_sebelum, "daftar pilihan tidak bercampur dengan animasi")
	_tutup(layar)
