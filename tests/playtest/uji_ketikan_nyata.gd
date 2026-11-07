extends SceneTree

# Probe ketikan keyboard nyata: event InputEventKey dikirim lewat Input.parse_input_event ke
# LineEdit Terminal yang sudah berfokus. Jika teks berubah, masukan keyboard sampai ke GUI.
# Tidak memanggil text_submitted/text_changed secara langsung.
# Dijalankan di foreground dari simpanan tahap 13.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_ketikan_nyata.txt"

var root_app: Node
var hasil: PackedStringArray = []

func _catat(s: String) -> void:
	print(s)
	hasil.append(s)

func _frames(n := 3) -> void:
	for i in range(n):
		await process_frame

func _secs(t: float) -> void:
	await create_timer(t).timeout

func _cari_berkas(node: Node, berkas: String) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("/" + berkas):
		return node
	for c in node.get_children():
		var r := _cari_berkas(c, berkas)
		if r != null:
			return r
	return null

func _tunggu_berkas(berkas: String, batas := 15.0) -> Node:
	var t := 0.0
	while t < batas:
		var n := _cari_berkas(root_app, berkas)
		if n != null and n.is_inside_tree():
			return n
		await _secs(0.2)
		t += 0.2
	return null

func _cari_kelas(node: Node, kelas: String) -> Node:
	if node.is_class(kelas) and node.is_visible_in_tree():
		return node
	for c in node.get_children():
		var r := _cari_kelas(c, kelas)
		if r != null:
			return r
	return null

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
	await _frames(1)

func _initialize() -> void:
	await process_frame
	root_app = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(root_app)
	await _frames(10)
	var menu := await _tunggu_berkas("menu_utama.gd")
	await _secs(1.0)
	var lanjut: Button = null
	if menu != null:
		var t := _cari_kelas(menu, "Button")
		lanjut = t as Button
	# Tombol Lanjutkan dicari dari daftar tombol menu.
	lanjut = _tombol_teks(menu, Bahasa.t("menu.lanjutkan")) if menu != null else null
	if lanjut != null:
		lanjut.pressed.emit()
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	var ikon: Button = desk.call("_tombol_id", "terminal") if desk != null else null
	if ikon != null:
		ikon.pressed.emit()
	await _secs(1.2)
	var term := await _tunggu_berkas("terminal_screen.gd")
	var masukan := _cari_kelas(term, "LineEdit") as LineEdit if term != null else null
	if masukan == null:
		_catat("FAIL  kolom Terminal tidak ditemukan")
		_selesai(1)
		return
	masukan.grab_focus()
	await _frames(3)
	_catat("INFO  kolom berfokus=%s" % str(masukan.has_focus()))
	var awal := masukan.text
	for ch in "whoami":
		await _tekan(ch.to_upper().unicode_at(0), ch.unicode_at(0))
	_catat("INFO  teks setelah ketikan keyboard: '%s' (awal '%s')" % [masukan.text, awal])
	var ok := masukan.text == "whoami"
	_catat(("PASS" if ok else "FAIL") + "  ketikan keyboard nyata sampai ke LineEdit")
	_selesai(0 if ok else 1)

func _tombol_teks(node: Node, teks: String) -> Button:
	var h: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.strip_edges() == teks:
		h = node
	for c in node.get_children():
		var r := _tombol_teks(c, teks)
		if r != null:
			h = r
	return h

func _selesai(kode: int) -> void:
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(hasil) + "\n")
	quit(kode)
