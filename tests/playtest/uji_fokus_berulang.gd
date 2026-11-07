extends SceneTree

# Uji berulang: setelah tiap perintah selesai, ketik perintah berikutnya TANPA klik ulang kolom.
# Mencatat apakah ketikan diterima dan siapa pemilik fokus. Keyboard Godot (bukan keyboard OS).

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_fokus_berulang.txt"
const SHOTS := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/shots"

var lines: PackedStringArray = []
var gagal := 0
var lulus := 0
var root_app: Node

func _catat(s: String) -> void:
	print(s)
	lines.append(s)

func _cek(ok: bool, nama: String, bukti := "") -> void:
	if ok:
		lulus += 1
		_catat("PASS  %s %s" % [nama, bukti])
	else:
		gagal += 1
		_catat("FAIL  %s %s" % [nama, bukti])

func _frames(n := 3) -> void:
	for i in range(n):
		await process_frame

func _secs(t: float) -> void:
	await create_timer(t).timeout

func _sesi():
	return SesiUtama.ambil()

func _cari_berkas(node: Node, berkas: String) -> Node:
	if not is_instance_valid(node):
		return null
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

# Tombol terlihat dan aktif dengan teks tepat. Kecocokan terakhir menurut urutan pohon (lapisan di atas).
func _cari_tombol(node: Node, teks: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and not (node as Button).disabled:
		if (node as Button).text.strip_edges() == teks:
			hasil = node
	for c in node.get_children():
		var r := _cari_tombol(c, teks)
		if r != null:
			hasil = r
	return hasil

func _cari_tombol_berisi(node: Node, bagian: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.contains(bagian):
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol_berisi(c, bagian)
		if r != null:
			hasil = r
	return hasil

func _cari_kelas(node: Node, kelas: String) -> Node:
	if node.is_class(kelas) and node.is_visible_in_tree():
		return node
	for c in node.get_children():
		var r := _cari_kelas(c, kelas)
		if r != null:
			return r
	return null

func _teks_label(node: Node) -> String:
	var t := ""
	if node is Label:
		t += (node as Label).text + "\n"
	elif node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + "\n"
	for c in node.get_children():
		t += _teks_label(c)
	return t

# Klik kiri sungguhan di tengah kontrol: kursor dipindah, lalu tekan dan lepas.
func _klik_nyata(c: Control) -> void:
	# Posisi dihitung ke koordinat jendela fisik: transformasi kanvas lalu transformasi final root
	# (viewport diskalakan terhadap jendela, mis. 0.5 untuk 720x1280 di jendela 360x640).
	var p := get_root().get_final_transform() * (c.get_global_transform_with_canvas() * (c.size / 2.0))
	Input.warp_mouse(p)
	await _frames(3)
	var gerak := InputEventMouseMotion.new()
	gerak.position = p
	gerak.global_position = p
	Input.parse_input_event(gerak)
	await _frames(2)
	var tekan := InputEventMouseButton.new()
	tekan.button_index = MOUSE_BUTTON_LEFT
	tekan.position = p
	tekan.global_position = p
	tekan.pressed = true
	tekan.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(tekan)
	await _frames(2)
	var lepas := tekan.duplicate()
	lepas.pressed = false
	lepas.button_mask = 0
	Input.parse_input_event(lepas)
	await _frames(4)

# Satu tombol keyboard sungguhan. Huruf dikirim dengan kode huruf kapitalnya.
func _tekan_tombol(kode: int, unicode: int) -> void:
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

func _ketik_nyata(teks: String) -> void:
	for ch in teks:
		await _tekan_tombol(ch.to_upper().unicode_at(0), ch.unicode_at(0))

func _enter() -> void:
	await _tekan_tombol(KEY_ENTER, 10)

# Menunggu output Terminal selesai beranimasi (_busy false), agar ketikan berikutnya tidak hilang.
func _tunggu_idle(term: Node, batas := 60.0) -> void:
	var t := 0.0
	await _secs(0.3)
	while t < batas and term.get("_busy") == true:
		await _secs(0.2)
		t += 0.2

func _shot(nama: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("%s/nyata_%s.png" % [SHOTS, nama])

func _buka_aplikasi(desk: Node, id: String) -> void:
	var ikon: Button = desk.call("_tombol_id", id)
	if ikon == null:
		_cek(false, "ikon %s ada di desktop" % id)
		return
	await _klik_nyata(ikon)
	await _secs(1.2)

func _kembali_desktop(app: Node) -> void:
	# Aplikasi berjendela (ManajerJendela): keluar = tombol tutup (X) pada bilah judul jendela,
	# yaitu TextureButton dengan tekstur win_close. Bukan Button berteks "Desktop".
	var t := _cari_tutup(root_app)
	_cek(t != null, "tombol tutup jendela (X) ada di aplikasi")
	if t != null:
		await _klik_nyata(t)
		await _secs(0.8)
		_cek(not app.is_inside_tree() or not app.is_visible_in_tree(), "klik X menutup aplikasi", "(%s)" % app.name)

func _cari_tutup(node: Node) -> Control:
	var h: Control = null
	if node is TextureButton and (node as TextureButton).is_visible_in_tree() and (node as TextureButton).texture_normal != null and (node as TextureButton).texture_normal.resource_path.ends_with("win_close_normal.png"):
		h = node
	for c in node.get_children():
		var r := _cari_tutup(c)
		if r != null:
			h = r
	return h

func _initialize() -> void:
	await process_frame
	root_app = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(root_app)
	var menu := await _tunggu_berkas("menu_utama.gd")
	await _secs(1.0)
	var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
	if lanjut != null:
		await _klik_nyata(lanjut)
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	await _buka_aplikasi(desk, "terminal")
	var term := await _tunggu_berkas("terminal_screen.gd")
	var masukan := _cari_kelas(term, "LineEdit") as LineEdit
	await _klik_nyata(masukan)
	var perintah := ["help", "whoami", "pwd", "ls", "whoami"]
	for k in range(perintah.size()):
		var p: String = perintah[k]
		var sebelum := _teks_label(term).count("$ " + p + "\n") + _teks_label(term).count("$ " + p + " ")
		await _ketik_nyata(p)
		var terketik := masukan.text == p
		await _enter()
		await _tunggu_idle(term)
		await _secs(1.5)
		var sesudah := _teks_label(term).count("$ " + p + "\n") + _teks_label(term).count("$ " + p + " ")
		_catat("INFO  #%d '%s': terketik=%s, dijalankan=%s, fokus=%s" % [k + 1, p, str(terketik), str(sesudah > sebelum), str(masukan.has_focus())])
	_selesai()

func _selesai() -> void:
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0)
