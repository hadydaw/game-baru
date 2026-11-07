extends SceneTree

# Probe: apakah klik mouse nyata memberi fokus pada LineEdit Terminal (dan koordinat benar).
const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_klik_fokus.txt"
var root_app: Node

func _secs(t: float) -> void:
	await create_timer(t).timeout

func _cari(node: Node, berkas: String) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("/" + berkas):
		return node
	for c in node.get_children():
		var r := _cari(c, berkas)
		if r != null:
			return r
	return null

func _cari_kelas(node: Node, kelas: String) -> Node:
	if node.is_class(kelas) and node.is_visible_in_tree():
		return node
	for c in node.get_children():
		var r := _cari_kelas(c, kelas)
		if r != null:
			return r
	return null

func _klik(c: Control) -> void:
	var p := get_root().get_final_transform() * (c.get_global_transform_with_canvas() * (c.size / 2.0))
	Input.warp_mouse(p)
	await process_frame
	await process_frame
	var t := InputEventMouseButton.new()
	t.button_index = MOUSE_BUTTON_LEFT
	t.position = p
	t.global_position = p
	t.pressed = true
	t.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(t)
	await process_frame
	await process_frame
	var l := t.duplicate()
	l.pressed = false
	l.button_mask = 0
	Input.parse_input_event(l)
	await process_frame
	await process_frame

func _tombol_teks(node: Node, teks: String) -> Button:
	var h: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.strip_edges() == teks:
		h = node
	for c in node.get_children():
		var r := _tombol_teks(c, teks)
		if r != null:
			h = r
	return h

func _tombol_berisi(node: Node, bagian: String) -> Button:
	var h: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.contains(bagian):
		h = node
	for c in node.get_children():
		var r := _tombol_berisi(c, bagian)
		if r != null:
			h = r
	return h

func _semua_tombol(node: Node, hasil: Array) -> void:
	if node is Button and (node as Button).is_visible_in_tree():
		hasil.append((node as Button).text)
	for c in node.get_children():
		_semua_tombol(c, hasil)

func _initialize() -> void:
	await process_frame
	root_app = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(root_app)
	for i in range(10):
		await process_frame
	var menu0: Node = null
	var t := 0.0
	while t < 15.0 and menu0 == null:
		menu0 = _cari(root_app, "menu_utama.gd")
		await _secs(0.2)
		t += 0.2
	var hasil := ""
	var ikon_term: Control = null
	var desk := _cari(root_app, "desktop_view.gd")
	var menu := _cari(root_app, "menu_utama.gd")
	hasil += "menu=%s desk=%s\n" % [str(menu != null), str(desk != null)]
	var semua: Array = []
	_semua_tombol(root_app, semua)
	hasil += "tombol terlihat: %s\n" % str(semua)
	var tlogin := _tombol_berisi(root_app, "Login")
	hasil += "tombol login ada=%s\n" % str(tlogin != null)
	if tlogin != null:
		var pk := get_root().get_final_transform() * (tlogin.get_global_transform_with_canvas() * (tlogin.size / 2.0))
		hasil += "titik klik=%s rect_layar=%s jendela=%s final=%s\n" % [str(pk), str(tlogin.get_global_rect()), str(get_root().get_window().size), str(get_root().get_final_transform())]
		var kena := [false]
		tlogin.pressed.connect(func(): kena[0] = true)
		await _klik(tlogin)
		hasil += "pressed Login diterima=%s\n" % str(kena[0])
		await _secs(0.5)
	var masukan := _cari_kelas(root_app, "LineEdit") as LineEdit
	hasil += "LineEdit ditemukan=%s\n" % str(masukan != null)
	if masukan != null:
		hasil += "rect=%s screen=%s\n" % [str(masukan.get_global_rect()), str(get_root().get_final_transform() * (masukan.get_global_transform_with_canvas() * (masukan.size / 2.0)))]
		hasil += "viewport=%s window=%s\n" % [str(get_root().get_visible_rect().size), str(DisplayServer.window_get_size())]
		await _klik(masukan)
		hasil += "fokus setelah klik=%s\n" % str(masukan.has_focus())
		hasil += "tombol login terklik: panel login terlihat=%s\n" % str(masukan.is_visible_in_tree())
	print(hasil)
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string(hasil)
	quit(0)
