extends SceneTree

# Uji autocomplete Tab dengan input nyata: nmap tidak muncul sebelum apt install, lalu muncul dan opsinya
# ditawarkan setelah dipasang. Semua ketikan dan Tab lewat Input.parse_input_event; tangkapan layar disimpan.
# Jalankan dengan xvfb (tanpa --headless) agar layout dan rendering berfungsi.

const DIR_SHOT := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/shots"
const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_tab_nmap.txt"

var hasil: PackedStringArray = []

func _catat(s: String) -> void:
	print(s)
	hasil.append(s)

func _frames(n := 3) -> void:
	for i in range(n):
		await process_frame

func _tekan(kode: int, unicode: int) -> void:
	var k := InputEventKey.new()
	k.keycode = kode as Key
	k.physical_keycode = kode as Key
	k.unicode = unicode
	k.pressed = true
	Input.parse_input_event(k)
	await _frames(1)
	var l := k.duplicate()
	l.pressed = false
	Input.parse_input_event(l)
	await _frames(2)

func _ketik(teks: String) -> void:
	for i in range(teks.length()):
		var c := teks.unicode_at(i)
		var kode := KEY_SPACE if c == 32 else (KEY_MINUS if c == 45 else c)
		await _tekan(kode, c)

func _shot(nama: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png("%s/tab_%s.png" % [DIR_SHOT, nama])
	_catat("  tangkapan: tab_%s.png" % nama)

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

	_catat("== nmap belum dipasang: ketik 'nma' lalu Tab")
	await _ketik("nma")
	await _tekan(KEY_TAB, 0)
	_catat("  teks: '%s' (harus tetap 'nma')" % layar._masukan.text)
	_catat("  nmap terpasang: %s" % str(SesiUtama.sesi.repositori.punya("nmap")))
	await _shot("01_nmap_belum_dipasang")

	_catat("== kosongkan, ketik 'apt install -y nmap' lalu Enter")
	layar._masukan.text = ""
	layar._masukan.caret_column = 0
	await _frames(2)
	await _ketik("apt install -y nmap")
	await _tekan(KEY_ENTER, 0)
	# Tunggu sampai apt selesai dan animasinya berhenti, seperti pemain yang menunggu prompt kembali.
	var t := 0
	while layar._busy and t < 600:
		await _frames(5)
		t += 1
	await _frames(5)
	_catat("  nmap terpasang: %s" % str(SesiUtama.sesi.repositori.punya("nmap")))
	await _shot("02_setelah_apt_install")

	_catat("== ketik 'nma' lalu Tab")
	layar._masukan.text = ""
	layar._masukan.caret_column = 0
	await _frames(2)
	await _ketik("nma")
	await _tekan(KEY_TAB, 0)
	_catat("  teks: '%s' (harus 'nmap ')" % layar._masukan.text)

	_catat("== ketik '-' lalu Tab (opsi nmap)")
	await _ketik("-")
	await _tekan(KEY_TAB, 0)
	_catat("  teks: '%s'" % layar._masukan.text)
	_catat("  daftar opsi: %s" % layar._keluaran.get_parsed_text().right(200).replace("\n", " | "))
	await _shot("03_opsi_nmap")

	var f := FileAccess.open(LOG, FileAccess.WRITE)
	f.store_string("\n".join(hasil) + "\n")
	f.close()
	quit(0)
