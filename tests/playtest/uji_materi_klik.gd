extends SceneTree

# Materi pembelajaran 26 tahap dengan KLIK MOUSE NYATA: Email -> pilih baris -> BACA -> BELAJAR -> cek judul/konsep.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_materi_klik.txt"
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


func _baris_pesan(node: Node, id: String) -> Button:
	var hasil: Button = null
	if node is Button:
		for c in (node as Button).get_signal_connection_list("pressed"):
			var args: Array = c["callable"].get_bound_arguments()
			if args.size() > 0 and String(args[0]) == id:
				hasil = node
	for c in node.get_children():
		var r := _baris_pesan(c, id)
		if r != null:
			hasil = r
	return hasil

func _teks_node(node: Node) -> String:
	var t := ""
	if node is Label:
		t += (node as Label).text + " "
	if node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + " "
	for c in node.get_children():
		t += _teks_node(c)
	return t

func _judul_pesan(p: Dictionary) -> String:
	var k := String(p.get("judul", ""))
	var t := Bahasa.t(k)
	return t if t != k else Bahasa.pilih(k)

# Gulir daftar dengan roda mouse nyata (tanpa mengubah scroll_vertical secara langsung)
# sampai baris terlihat utuh di area gulir.
func _gulir_sampai_terlihat(email: Node, baris: Control) -> void:
	var gulir := _cari_kelas(email, "ScrollContainer") as ScrollContainer
	if gulir == null:
		return
	for i in range(80):
		var area := gulir.get_global_rect()
		var r := baris.get_global_rect()
		if r.position.y >= area.position.y and r.end.y <= area.end.y:
			return
		var pusat := gulir.get_global_transform_with_canvas() * (gulir.size / 2.0)
		var p := get_root().get_final_transform() * pusat
		Input.warp_mouse(p)
		await _frames(2)
		var arah := MOUSE_BUTTON_WHEEL_DOWN if r.end.y > area.end.y else MOUSE_BUTTON_WHEEL_UP
		var w := InputEventMouseButton.new()
		w.button_index = arah
		w.position = p
		w.global_position = p
		w.pressed = true
		Input.parse_input_event(w)
		await _frames(2)
		var lepas := w.duplicate()
		lepas.pressed = false
		Input.parse_input_event(lepas)
		await _frames(4)

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
	var sesi = _sesi()
	# Prasyarat: email tiap tahap normalnya masuk saat tahap selesai. Uji ini memeriksa tampilan
	# materi lewat klik, bukan progres misi, jadi pesan tahap 1-26 dikirim lewat fungsi game yang sama.
	var misi_1: Dictionary = Misi.temukan("misi_1")
	for n in range(1, 27):
		Misi._kirim_tahap(sesi, misi_1, n)
	# Keadaan simpanan akhir (misi selesai): materi tiap tahap terbuka. Tanpa ini tombol BELAJAR nonaktif.
	sesi.misi["misi_1"] = "selesai"
	var data: Array = Misi.pembelajaran("misi_1")
	var lulus_tahap := 0
	for n in range(1, 27):
		var pesan: Dictionary = {}
		for pm in Email.pesan_misi(sesi):
			if int(pm.get("tahap", 0)) == n:
				pesan = pm
		if pesan.is_empty():
			_cek(false, "tahap %d: pesan ada" % n)
			continue
		await _buka_aplikasi(desk, "email")
		var email := await _tunggu_berkas("email_app.gd")
		if email == null:
			_cek(false, "tahap %d: Email terbuka" % n)
			continue
		await _secs(0.4)
		var baris := _baris_pesan(email, String(pesan["id"]))
		if baris == null:
			_cek(false, "tahap %d: baris pesan ada (mungkin di luar layar)" % n)
			await _tutup_jendela()
			continue
		await _gulir_sampai_terlihat(email, baris)
		await _klik_nyata(baris)
		await _secs(0.4)
		var baca := _cari_tombol(email, Bahasa.t("email.baca"))
		if baca != null:
			await _klik_nyata(baca)
			await _secs(0.4)
		var belajar := _cari_tombol(email, Bahasa.t("misi.tombol_belajar"))
		if belajar == null and n == 4:
			await _shot("materi_tahap4_gagal")
		_cek(belajar != null, "tahap %d: tombol BELAJAR ada (klik nyata)" % n)
		if belajar != null:
			await _klik_nyata(belajar)
			await _secs(0.5)
			var m: Dictionary = data[n - 1]
			var teks := _teks_node(email).to_lower()
			var judul := Bahasa.pilih(String(m.get("judul", "")))
			var konsep := Bahasa.pilih(String(m.get("konsep", "")))
			var ok := judul != "" and konsep != "" and teks.contains(judul.left(20).to_lower()) and teks.contains(konsep.left(20).to_lower())
			_cek(ok, "tahap %d: judul+konsep tampil" % n, "(%s)" % judul.left(40))
			if ok:
				lulus_tahap += 1
			var kembali := _cari_tombol(email, Bahasa.t("misi.tombol_kembali"))
			if kembali != null:
				await _klik_nyata(kembali)
				await _secs(0.3)
		await _tutup_jendela()
	_catat("RINGKASAN: %d dari 26 tahap materinya dibuka dengan klik nyata" % lulus_tahap)
	_selesai()

func _tutup_jendela() -> void:
	var t := _cari_tutup(root_app)
	if t != null:
		await _klik_nyata(t)
		await _secs(0.5)

func _selesai() -> void:
	_catat("== HASIL (klik nyata): %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
