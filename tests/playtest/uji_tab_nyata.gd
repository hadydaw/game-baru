extends SceneTree

# Uji Tab dengan input nyata di Terminal: ketikan keyboard dikirim lewat Input.parse_input_event,
# lalu tombol Tab layar diklik dengan event mouse sungguhan. Tidak memanggil fungsi internal untuk input.
# Jalankan tanpa --headless (xvfb) agar layout dan klik berfungsi.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_tab_nyata.txt"

var hasil: PackedStringArray = []

func _catat(s: String) -> void:
	print(s)
	hasil.append(s)

func _frames(n := 3) -> void:
	for i in range(n):
		await process_frame

func _tekan_huruf(huruf: String) -> void:
	var k := InputEventKey.new()
	k.keycode = huruf.unicode_at(0) as Key
	k.physical_keycode = k.keycode
	k.unicode = huruf.unicode_at(0)
	k.pressed = true
	Input.parse_input_event(k)
	await _frames(1)
	var l := k.duplicate()
	l.pressed = false
	Input.parse_input_event(l)
	await _frames(1)

func _tekan_tab_fisik() -> void:
	var k := InputEventKey.new()
	k.keycode = KEY_TAB
	k.physical_keycode = KEY_TAB
	k.pressed = true
	Input.parse_input_event(k)
	await _frames(2)
	var l := k.duplicate()
	l.pressed = false
	Input.parse_input_event(l)
	await _frames(2)

func _cari_tombol(node: Node, teks: String) -> Button:
	if node is Button and (node as Button).text == teks and (node as Button).is_visible_in_tree():
		return node
	for c in node.get_children():
		var r := _cari_tombol(c, teks)
		if r != null:
			return r
	return null

func _klik_tengah(b: Control) -> void:
	var pusat := b.get_global_rect().get_center()
	var tekan := InputEventMouseButton.new()
	tekan.button_index = MOUSE_BUTTON_LEFT
	tekan.pressed = true
	tekan.position = pusat
	tekan.global_position = pusat
	Input.parse_input_event(tekan)
	await _frames(2)
	var lepas := tekan.duplicate()
	lepas.pressed = false
	Input.parse_input_event(lepas)
	await _frames(3)

func _initialize() -> void:
	await process_frame
	var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
	var data: Dictionary = JSON.parse_string(isi)
	SesiUtama.sesi = ShellSession.new(Vfs.new(data["/"]))
	TerminalScreen._sesi_bersama = null
	var layar := TerminalScreen.new()
	get_root().add_child(layar)
	await _frames(6)
	layar._masukan.grab_focus()
	await _frames(2)

	_catat("== ketik 'ca' lewat keyboard")
	await _tekan_huruf("c")
	await _tekan_huruf("a")
	_catat("  teks sebelum Tab: '%s'" % layar._masukan.text)

	_catat("== Tab fisik")
	await _tekan_tab_fisik()
	_catat("  teks setelah Tab fisik: '%s'" % layar._masukan.text)
	_catat("  fokus masih di kolom perintah: %s" % str(layar._masukan.has_focus()))
	var riwayat_sebelum := SesiUtama.sesi.riwayat.size()

	_catat("== kosongkan lalu ketik 'cd dok' dan klik tombol Tab di layar")
	layar._masukan.text = "cd dok"
	layar._masukan.caret_column = 6
	await _frames(2)
	var tombol := _cari_tombol(layar, "Tab")
	if tombol == null:
		_catat("  BUG: tombol Tab tidak ditemukan di layar")
	else:
		await _klik_tengah(tombol)
		_catat("  teks setelah klik Tab: '%s'" % layar._masukan.text)
	_catat("  riwayat tidak berubah oleh Tab: %s" % str(SesiUtama.sesi.riwayat.size() == riwayat_sebelum))

	_catat("== sampel Wireshark: pasang wireshark dulu, lalu ketik jalur dan Tab")
	SesiUtama.sesi.jalankan("apt install -y wireshark")
	layar._masukan.text = "wireshark -r /usr/sh"
	layar._masukan.caret_column = layar._masukan.text.length()
	await _frames(2)
	await _tekan_tab_fisik()
	_catat("  teks: '%s'" % layar._masukan.text)

	var f := FileAccess.open(LOG, FileAccess.WRITE)
	f.store_string("\n".join(hasil) + "\n")
	f.close()
	quit(0)
