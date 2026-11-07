extends SceneTree

# Uji antarmuka dengan input sungguhan. Setiap ketukan dikirim sebagai InputEventMouseButton
# (kursor dipindah dulu dengan Input.warp_mouse), dan setiap huruf sebagai InputEventKey.
# Tombol diuji lewat hit-testing GUI, bukan dengan memanggil pressed.emit().
# Dijalankan dengan layar (xvfb, tanpa --headless) dari simpanan yang sudah disiapkan runner.
# Setiap langkah dicatat PASS/FAIL. Langkah yang tidak tercapai dicatat FAIL, tidak dilewati.
#
# STATUS: lulus 28/28 di xvfb (klik mouse dan ketikan keyboard sungguhan lewat Input.parse_input_event).
# Klik memakai koordinat jendela (final transform root), keluar aplikasi lewat tombol X jendela.
# Temuan terbuka: ketikan dibuang setelah perintah ber-Enter sampai kolom diklik (lihat laporan).

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_input_nyata.txt"
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
	var packed: PackedScene = load("res://scenes/main.tscn")
	root_app = packed.instantiate()
	get_root().add_child(root_app)
	await _frames(10)

	# Fokus jendela: tanpa fokus, GUI bisa mengabaikan event mouse. Status dicatat, bukan diasumsikan.
	get_root().get_window().grab_focus()
	await _frames(5)
	_catat("INFO  jendela fokus=%s" % str(DisplayServer.window_is_focused()))

	# 1. Menu utama: lanjutkan simpanan lewat klik sungguhan.
	var menu := await _tunggu_berkas("menu_utama.gd")
	_cek(menu != null, "menu utama muncul")
	if menu == null:
		_selesai()
		return
	await _secs(1.5)
	var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
	_cek(lanjut != null, "tombol Lanjutkan ditemukan")
	if lanjut != null:
		await _klik_nyata(lanjut)
	await _secs(1.5)

	var desk := await _tunggu_berkas("desktop_view.gd")
	_cek(desk != null, "desktop muncul setelah klik Lanjutkan")
	if desk == null:
		_selesai()
		return
	await _shot("desktop")

	# 2. Toko Perangkat: Beli lewat tombol sungguhan.
	await _buka_aplikasi(desk, "toko")
	var toko := _cari_berkas(root_app, "toko_screen.gd")
	_cek(toko != null, "Toko Perangkat terbuka dari ikon")
	if toko != null:
		var saldo_awal: int = _sesi().economy.saldo
		var beli := _cari_tombol(toko, Bahasa.t("toko.beli"))
		_cek(beli != null, "tombol Beli ada dan aktif")
		if beli != null:
			await _klik_nyata(beli)
			await _secs(0.3)
			var saldo_baru: int = _sesi().economy.saldo
			_cek(saldo_baru < saldo_awal, "Beli mengurangi saldo", "(%d -> %d)" % [saldo_awal, saldo_baru])
		await _shot("toko")
		await _kembali_desktop(toko)
	await _secs(0.5)

	# 3. Device Manager: Rakit dan Hubungkan lewat tombol sungguhan.
	await _buka_aplikasi(desk, "perangkat")
	var dm := _cari_berkas(root_app, "device_manager.gd")
	_cek(dm != null, "Device Manager terbuka dari ikon")
	if dm != null:
		var rakit := _cari_tombol(dm, Bahasa.t("perangkat.rakit"))
		if rakit != null:
			await _klik_nyata(rakit)
			await _secs(0.3)
		_cek(_sesi().perangkat.sudah_dirakit(), "Rakit menyelesaikan perakitan")
		var hub := _cari_tombol(dm, Bahasa.t("perangkat.hubungkan"))
		if hub != null:
			await _klik_nyata(hub)
			await _secs(0.3)
		_cek(_sesi().perangkat.terhubung(), "Hubungkan mengaktifkan koneksi")
		await _shot("device_manager")
		await _kembali_desktop(dm)
	await _secs(0.5)

	# 4. Alat Lapangan: target diketik lewat keyboard, lalu Scan lewat klik.
	await _buka_aplikasi(desk, "alat")
	var alat := _cari_berkas(root_app, "alat_screen.gd")
	_cek(alat != null, "Alat Lapangan terbuka dari ikon")
	if alat != null:
		var kolom := _cari_kelas(alat, "LineEdit") as LineEdit
		if kolom != null:
			await _klik_nyata(kolom)
			await _ketik_nyata("10.7.0.8")
			_cek(kolom.text == "10.7.0.8", "target diketik lewat keyboard", "(isi: %s)" % kolom.text)
		var scan := _cari_tombol(alat, Bahasa.t("alat.scan"))
		_cek(scan != null, "tombol Scan IP ada")
		if scan != null:
			await _klik_nyata(scan)
			await _secs(0.3)
		_cek(_teks_label(alat).contains("10.7.0.8"), "hasil Scan menampilkan target")
		await _shot("alat")
		await _kembali_desktop(alat)
	await _secs(0.5)

	# 5. Dompet: saldo tampil sesuai sesi.
	await _buka_aplikasi(desk, "dompet")
	var dompet := _cari_berkas(root_app, "dompet_screen.gd")
	_cek(dompet != null, "Dompet terbuka dari ikon")
	if dompet != null:
		var saldo_tampil := str(_sesi().economy.saldo)
		_cek(_teks_label(dompet).contains(saldo_tampil), "Dompet menampilkan saldo", "(saldo %s)" % saldo_tampil)
		await _shot("dompet")
		await _kembali_desktop(dompet)
	await _secs(0.5)

	# 6. Terminal: apt diketik, lalu Ctrl+C saat prompt Y/n lewat tombol Ctrl sungguhan.
	await _buka_aplikasi(desk, "terminal")
	var term := await _tunggu_berkas("terminal_screen.gd")
	_cek(term != null, "Terminal terbuka dari ikon")
	if term != null:
		var masukan := _cari_kelas(term, "LineEdit") as LineEdit
		await _klik_nyata(masukan)
		await _ketik_nyata("apt install -y john")
		await _enter()
		await _tunggu_idle(term)
		await _secs(0.1)
		_cek(_teks_label(term).contains("Setting up john"), "apt install -y john lewat ketikan")
		# Pilih paket pertama yang belum terpasang di simpanan ini (airodump-ng bisa sudah terpasang).
		var pkt := ""
		for kandidat in ["aircrack-ng", "hashcat", "wireshark", "airodump-ng"]:
			if pkt == "" and not _sesi().repositori.punya(kandidat):
				pkt = kandidat
		_catat("INFO  paket uji prompt Y/n: %s" % pkt)
		# Prasyarat: saldo dinaikkan agar APT sampai ke prompt Y/n (kredit kurang dicek sebelum prompt).
		_sesi().economy.saldo = 999999
		await _ketik_nyata("apt install " + pkt)
		await _enter()
		await _tunggu_idle(term)
		_cek(_teks_label(term).contains("Do you want to continue? [Y/n]"), "prompt Y/n muncul (%s)" % pkt)
		var tombol_ctrl := term.get("_tombol_ctrl") as Button
		_cek(tombol_ctrl != null, "tombol Ctrl ada")
		if tombol_ctrl != null:
			await _klik_nyata(tombol_ctrl)
			await _ketik_nyata("c")
			_catat("INFO  sesudah ketik c: _ctrl=%s fokus=%s teks='%s' busy=%s" % [str(term.get("_ctrl")), str(masukan.has_focus()), masukan.text, str(term.get("_busy"))])
			await _secs(1.0)
			_catat("INFO  sesudah 1 dtk: _ctrl=%s teks='%s' busy=%s" % [str(term.get("_ctrl")), masukan.text, str(term.get("_busy"))])
		_cek(not _sesi().repositori.punya(pkt), "Ctrl+C membatalkan Y/n, %s tidak terpasang" % pkt)
		_cek(_teks_label(term).contains("^C"), "Ctrl+C tampil sebagai ^C")
		# Mode live Airodump-ng: aktifkan monitor lalu jalankan airodump-ng, Ctrl+C dengan klik + keyboard.
		await _ketik_nyata("airmon-ng start wlan0")
		await _enter()
		await _tunggu_idle(term)
		await _ketik_nyata("airodump-ng wlan0mon")
		await _enter()
		await _tunggu_idle(term)
		await _secs(0.5)
		var live_on: bool = term.get("_live") == true
		_cek(live_on, "airodump-ng masuk mode live (wlan0mon)")
		if live_on and tombol_ctrl != null:
			await _klik_nyata(tombol_ctrl)
			await _ketik_nyata("c")
			await _secs(1.0)
			_cek(term.get("_live") == false, "Ctrl+C (klik + keyboard) menghentikan mode live")
			_cek(_teks_label(term).contains("^C"), "Ctrl+C live tampil ^C")
		await _shot("terminal")
	_selesai()

func _selesai() -> void:
	_catat("== HASIL: %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
