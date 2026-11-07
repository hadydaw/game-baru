extends SceneTree

# Wireshark dengan KLIK dan KETIKAN NYATA: apt install lewat Terminal, tshark dan wireshark di Terminal,
# daftar paket, rincian, bytes, filter (benar dan salah), statistik, capture simulasi, simpan, buka lagi,
# flag misi, dan penutupan jendela. Dijalankan di foreground dengan xvfb.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_wireshark.txt"
const SHOTS := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/shots"
const CONTOH_LAN := "/usr/share/wireshark/samples/lab-jaringan-umum.simcap"
const CONTOH_WIFI := "/usr/share/wireshark/samples/lab-wifi-01-handshake.simcap"

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

func _cari_tutup(node: Node) -> Control:
	var h: Control = null
	if node is TextureButton and (node as TextureButton).is_visible_in_tree() and (node as TextureButton).texture_normal != null and (node as TextureButton).texture_normal.resource_path.ends_with("win_close_normal.png"):
		h = node
	for c in node.get_children():
		var r := _cari_tutup(c)
		if r != null:
			h = r
	return h

func _teks_node(node: Node) -> String:
	var t := ""
	if node is Label:
		t += (node as Label).text + " "
	if node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + " "
	if node is Tree:
		var akar := (node as Tree).get_root()
		if akar != null:
			var it := akar.get_first_child()
			while it != null:
				for k in range((node as Tree).columns):
					t += it.get_text(k) + " "
				it = it.get_next()
	for c in node.get_children():
		t += _teks_node(c)
	return t

# Klik kiri sungguhan pada titik layar (koordinat global kanvas).
func _klik_titik(p: Vector2) -> void:
	var titik := get_root().get_final_transform() * p
	Input.warp_mouse(titik)
	await _frames(3)
	var gerak := InputEventMouseMotion.new()
	gerak.position = titik
	gerak.global_position = titik
	Input.parse_input_event(gerak)
	await _frames(2)
	var tekan := InputEventMouseButton.new()
	tekan.button_index = MOUSE_BUTTON_LEFT
	tekan.position = titik
	tekan.global_position = titik
	tekan.pressed = true
	tekan.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(tekan)
	await _frames(2)
	var lepas := tekan.duplicate()
	lepas.pressed = false
	lepas.button_mask = 0
	Input.parse_input_event(lepas)
	await _frames(4)

func _klik_nyata(c: Control) -> void:
	await _klik_titik(c.get_global_transform_with_canvas() * (c.size / 2.0))

# Klik baris Tree: gulir ke baris dulu, lalu klik di tengah area barisnya.
func _klik_baris(tree: Tree, item: TreeItem) -> void:
	tree.scroll_to_item(item)
	await _frames(4)
	var area := tree.get_item_area_rect(item, 0)
	await _klik_titik(tree.get_global_transform_with_canvas() * (area.position + Vector2(area.size.x * 0.3, area.size.y / 2.0)))

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

func _tunggu_idle(term: Node, batas := 60.0) -> void:
	var t := 0.0
	await _secs(0.3)
	while t < batas and term.get("_busy") == true:
		await _secs(0.2)
		t += 0.2

func _perintah(term: Node, teks: String) -> void:
	await _ketik_nyata(teks)
	await _enter()
	await _tunggu_idle(term)
	await _secs(0.4)

func _shot(nama: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("%s/wireshark_%s.png" % [SHOTS, nama])

func _buka_aplikasi(desk: Node, id: String) -> void:
	var ikon: Button = desk.call("_tombol_id", id)
	if ikon == null:
		_cek(false, "ikon %s ada di desktop" % id)
		return
	await _klik_nyata(ikon)
	await _secs(1.2)

func _cari_tombol_teks_di(node: Node, teks: String) -> Button:
	return _cari_tombol(node, teks)

# Menyiapkan sesi uji: saldo cukup untuk memasang paket, lalu simpanan diperbarui.
func _siapkan_sesi() -> void:
	var s = _sesi()
	s.economy.saldo = 5000
	Penyimpanan.simpan_sesi(s)

func _initialize() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(SHOTS)
	_siapkan_sesi()
	root_app = load("res://scenes/main.tscn").instantiate()
	get_root().add_child(root_app)
	var menu := await _tunggu_berkas("menu_utama.gd")
	await _secs(1.0)
	var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
	_cek(lanjut != null, "tombol Lanjutkan ada di menu")
	if lanjut != null:
		await _klik_nyata(lanjut)
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	_cek(desk != null, "desktop tampil")
	if desk == null:
		_selesai()
		return

	# 1. Terminal: pasang Wireshark dan TShark lewat APT.
	await _buka_aplikasi(desk, "terminal")
	var term := await _tunggu_berkas("terminal_screen.gd")
	_cek(term != null, "Terminal terbuka lewat ikon desktop")
	await _secs(1.0)
	var masukan: LineEdit = term.get("_masukan")
	await _klik_nyata(masukan)
	await _perintah(term, "apt install -y wireshark")
	await _perintah(term, "apt install -y tshark")
	_cek(_sesi().repositori.punya("wireshark"), "apt install wireshark (klik/ketik nyata)")
	_cek(_sesi().repositori.punya("tshark"), "apt install tshark (klik/ketik nyata)")
	await _perintah(term, "tshark -r %s -Y http" % CONTOH_LAN)
	_cek(_teks_node(term).contains("HTTP"), "tshark -Y http menampilkan paket HTTP di Terminal")
	await _shot("terminal_tshark")

	# 2. Buka Wireshark dari Terminal.
	await _perintah(term, "wireshark -r %s" % CONTOH_LAN)
	var ws := await _tunggu_berkas("wireshark_app.gd")
	_cek(ws != null, "wireshark -r membuka jendela Wireshark")
	if ws == null:
		_selesai()
		return
	await _secs(1.5)
	var daftar: Tree = ws.get("_daftar")
	var akar := daftar.get_root()
	var jumlah := akar.get_child_count() if akar != null else 0
	_cek(jumlah == 15, "daftar paket menampilkan 15 baris", "(%d)" % jumlah)
	await _shot("daftar")

	# 3. Pilih paket dan lihat rincian dan bytes.
	await _klik_baris(daftar, akar.get_children()[3])
	var model = ws.get("_model")
	_cek(model.terpilih == 3, "klik baris ke-4 memilih paket (SYN)", "(terpilih=%d)" % model.terpilih)
	var rincian: Tree = ws.get("_rincian")
	_cek(rincian.get_root().get_child_count() >= 4, "rincian protokol punya lapisan", "(%d)" % rincian.get_root().get_child_count())
	var bytes: RichTextLabel = ws.get("_bytes")
	_cek(bytes.get_parsed_text().contains("0000"), "panel bytes menampilkan heks baris pertama")
	var lapisan_ip := rincian.get_root().get_children()[1]
	await _klik_baris(rincian, lapisan_ip)
	_cek(bytes.get_parsed_text().contains("0010") or bytes.get_parsed_text().contains("0000"), "klik lapisan IP menyorot bytes")
	await _shot("rincian")

	# 4. Filter tampilan dengan ketikan nyata.
	var filter: LineEdit = ws.get("_filter")
	await _klik_nyata(filter)
	await _ketik_nyata("tcp.port == 80")
	await _enter()
	await _secs(0.3)
	_cek(model.tampil.size() == 7, "filter 'tcp.port == 80' menampilkan 7 paket", "(%d)" % model.tampil.size())
	await _shot("filter_port")
	await _klik_nyata(filter)
	filter.text = ""
	await _ketik_nyata("tcp.port ==")
	await _enter()
	await _secs(0.3)
	_cek(String(ws.get("_galat")).contains("belum diisi") or String(ws.get("_galat")).contains("missing"), "filter tanpa nilai menampilkan galat jelas", "(%s)" % String(ws.get("_galat")))
	_cek(model.tampil.size() == 15, "filter yang galat tidak mengosongkan daftar")
	await _shot("filter_galat")

	# 5. Kata kunci: POST dengan kata sandi, lalu buka rincian untuk misi.
	await _klik_nyata(filter)
	filter.text = ""
	await _ketik_nyata("http.request.method == \"POST\"")
	await _enter()
	await _secs(0.3)
	_cek(model.tampil.size() == 1, "filter POST menampilkan 1 paket", "(%d)" % model.tampil.size())
	var akar2 := daftar.get_root()
	await _klik_baris(daftar, akar2.get_children()[0])
	var progres: Array = _sesi().jaringan.progres
	_cek(progres.has("wireshark:kredensial"), "paket POST dengan kata sandi membuka flag misi wireshark:kredensial")

	# 6. Hapus filter lewat tombol Hapus, lalu statistik.
	var hapus := _cari_tombol(ws, Bahasa.t("wireshark.hapus"))
	await _klik_nyata(hapus)
	await _secs(0.3)
	_cek(model.tampil.size() == 15, "tombol Hapus mengembalikan 15 paket")
	var statistik := _cari_tombol(ws, Bahasa.t("wireshark.statistik"))
	await _klik_nyata(statistik)
	await _secs(0.5)
	var lapisan_overlay: Control = ws.get("_overlay")
	_cek(lapisan_overlay.visible, "tombol Statistik membuka panel statistik")
	_cek(_teks_node(lapisan_overlay).contains("Protocol Hierarchy") or _teks_node(lapisan_overlay).contains("Hierarki"), "panel statistik memuat hierarki protokol")
	await _shot("statistik")
	await _klik_nyata(_cari_tombol(lapisan_overlay, Bahasa.t("wireshark.tutup")))
	await _secs(0.3)
	_cek(not lapisan_overlay.visible, "tombol Tutup menutup statistik")

	# 7. Capture simulasi dari eth0.
	await _klik_nyata(_cari_tombol(ws, Bahasa.t("wireshark.mulai")))
	await _secs(0.4)
	await _klik_nyata(_cari_tombol(lapisan_overlay, "eth0"))
	await _secs(0.5)
	_cek(model.menangkap, "tombol Mulai lalu eth0 memulai capture")
	var t := 0.0
	while model.menangkap and t < 15.0:
		await _secs(0.5)
		t += 0.5
	_cek(not model.menangkap and model.paket.size() == 15, "capture simulasi selesai dengan 15 paket", "(%d)" % model.paket.size())
	_cek(progres.has("wireshark:tangkap"), "capture membuka flag misi wireshark:tangkap")
	await _shot("setelah_capture")

	# 8. Simpan hasil capture ke folder rumah, lalu buka lagi.
	await _klik_nyata(_cari_tombol(ws, Bahasa.t("wireshark.simpan")))
	await _secs(0.4)
	await _klik_nyata(_cari_tombol(lapisan_overlay, Bahasa.t("wireshark.simpan")))
	await _secs(0.5)
	var home: String = _sesi().home
	var simpanan: Dictionary = _sesi().fs.ambil(home + "/Capture-eth0.simcap")
	_cek(not simpanan.is_empty(), "simpan menulis Capture-eth0.simcap di folder rumah")
	await _klik_nyata(_cari_tombol(ws, Bahasa.t("wireshark.buka")))
	await _secs(0.4)
	await _klik_nyata(_cari_tombol(lapisan_overlay, "Capture-eth0.simcap"))
	await _secs(0.5)
	_cek(model.judul == "Capture-eth0.simcap" and model.paket.size() == 15, "buka berkas simpanan memuat 15 paket dari Capture-eth0.simcap", "(%s, %d)" % [model.judul, model.paket.size()])

	# 9. Tutup jendela, lalu buka dua berkas kedua lewat Terminal: pemeriksaan EAPOL.
	var tutup := _cari_tutup(root_app)
	_cek(tutup != null, "tombol X jendela Wireshark ada")
	if tutup != null:
		await _klik_nyata(tutup)
		await _secs(0.8)
	await _klik_nyata(masukan)
	await _perintah(term, "wireshark -r %s" % CONTOH_WIFI)
	var ws2 := await _tunggu_berkas("wireshark_app.gd")
	_cek(ws2 != null, "wireshark -r berkas handshake membuka jendela")
	if ws2 != null:
		await _secs(1.2)
		var model2 = ws2.get("_model")
		var filter2: LineEdit = ws2.get("_filter")
		await _klik_nyata(filter2)
		await _ketik_nyata("eapol")
		await _enter()
		await _secs(0.3)
		_cek(model2.tampil.size() == 4, "filter eapol menampilkan 4 pesan handshake", "(%d)" % model2.tampil.size())
		_cek(_sesi().jaringan.progres.has("wireshark:handshake"), "filter eapol membuka flag misi wireshark:handshake")
		await _shot("handshake")

	# 10. Petunjuk misi dan penyimpanan.
	var misi := Misi.temukan("misi_1")
	var petunjuk := Misi.petunjuk_ditemukan(_sesi(), misi)
	_cek(petunjuk.size() >= 3, "petunjuk Wireshark muncul di misi setelah flag terbuka", "(%d)" % petunjuk.size())
	Penyimpanan.simpan_sesi(_sesi())
	var muat := Penyimpanan.muat()
	_cek(not muat.is_empty(), "progres tersimpan dapat dimuat ulang")
	_selesai()

func _selesai() -> void:
	_catat("RINGKASAN: lulus=%d gagal=%d" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit()
