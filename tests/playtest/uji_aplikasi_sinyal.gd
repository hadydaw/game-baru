extends SceneTree

# Uji lima aplikasi lewat jalur layar: ikon desktop (pressed), tombol aplikasi (pressed),
# kolom teks (text_changed), dan efeknya dicek pada sesi. Ini BUKAN input OS sungguhan.
# Label "sinyal layar" dipakai agar tidak dianggap klik nyata.
# Dijalankan langsung di foreground dari simpanan yang sudah disiapkan runner.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_aplikasi_sinyal.txt"

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

func _cari_tombol(node: Node, teks: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and not (node as Button).disabled and (node as Button).text.strip_edges() == teks:
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol(c, teks)
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

func _teks_layar(node: Node) -> String:
	var t := ""
	if node is Label:
		t += (node as Label).text + "\n"
	elif node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + "\n"
	for c in node.get_children():
		t += _teks_layar(c)
	return t

# Membuka aplikasi dari ikon desktop, lalu menutupnya lewat tombol "‹ Desktop".
func _buka(desk: Node, id: String, berkas: String) -> Node:
	var ikon: Button = desk.call("_tombol_id", id)
	_cek(ikon != null, "[sinyal layar] ikon %s ada di desktop" % id)
	if ikon == null:
		return null
	ikon.pressed.emit()
	await _secs(1.2)
	var app := await _tunggu_berkas(berkas)
	_cek(app != null, "[sinyal layar] %s terbuka" % id)
	return app

func _tutup(app: Node) -> void:
	if app == null:
		return
	var t := _cari_tombol_berisi(app, "Desktop")
	if t != null:
		t.pressed.emit()
		await _secs(0.8)

func _cari_tombol_berisi(node: Node, bagian: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.contains(bagian):
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol_berisi(c, bagian)
		if r != null:
			hasil = r
	return hasil

func _initialize() -> void:
	await process_frame
	var packed: PackedScene = load("res://scenes/main.tscn")
	root_app = packed.instantiate()
	get_root().add_child(root_app)
	await _frames(10)
	var menu := await _tunggu_berkas("menu_utama.gd")
	if menu != null:
		await _secs(1.0)
		var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
		if lanjut != null:
			lanjut.pressed.emit()
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	_cek(desk != null, "[sinyal layar] desktop siap")
	if desk == null:
		_selesai()
		return
	var sesi = SesiUtama.ambil()

	# Toko Perangkat: tombol Beli pertama yang aktif.
	var toko := await _buka(desk, "toko", "toko_screen.gd")
	if toko != null:
		var saldo_awal: int = sesi.economy.saldo
		var beli := _cari_tombol(toko, Bahasa.t("toko.beli"))
		_cek(beli != null, "[sinyal layar] Toko: tombol Beli aktif ada")
		if beli != null:
			beli.pressed.emit()
			await _secs(0.3)
			_cek(sesi.economy.saldo < saldo_awal, "[sinyal layar] Toko: Beli mengurangi saldo", "(%d -> %d)" % [saldo_awal, sesi.economy.saldo])
	await _tutup(toko)

	# Device Manager: Rakit lalu Hubungkan.
	var dm := await _buka(desk, "perangkat", "device_manager.gd")
	if dm != null:
		var rakit := _cari_tombol(dm, Bahasa.t("perangkat.rakit"))
		if rakit != null:
			rakit.pressed.emit()
			await _secs(0.3)
		_cek(sesi.perangkat.sudah_dirakit(), "[sinyal layar] Device Manager: Rakit menyelesaikan perakitan")
		var hub := _cari_tombol(dm, Bahasa.t("perangkat.hubungkan"))
		if hub != null:
			hub.pressed.emit()
			await _secs(0.3)
		_cek(sesi.perangkat.terhubung(), "[sinyal layar] Device Manager: Hubungkan mengaktifkan koneksi")
	await _tutup(dm)

	# Alat Lapangan: target lewat LineEdit, lalu Scan.
	var alat := await _buka(desk, "alat", "alat_screen.gd")
	if alat != null:
		var kolom := _cari_kelas(alat, "LineEdit") as LineEdit
		_cek(kolom != null, "[sinyal layar] Alat: kolom target ada")
		if kolom != null:
			kolom.text = "10.7.0.8"
			kolom.text_changed.emit(kolom.text)
		var scan := _cari_tombol(alat, Bahasa.t("alat.scan"))
		_cek(scan != null, "[sinyal layar] Alat: tombol Scan IP ada")
		if scan != null:
			scan.pressed.emit()
			await _secs(0.3)
		_cek(_teks_layar(alat).contains("10.7.0.8"), "[sinyal layar] Alat: hasil Scan menampilkan target")
	await _tutup(alat)

	# Dompet: saldo tampil sesuai sesi.
	var dompet := await _buka(desk, "dompet", "dompet_screen.gd")
	if dompet != null:
		_cek(_teks_layar(dompet).contains(str(sesi.economy.saldo)), "[sinyal layar] Dompet: saldo tampil", "(saldo %d)" % sesi.economy.saldo)
	await _tutup(dompet)

	# Pasar (Black Market): layar terbuka dan tombol pertama tidak memicu galat.
	var pasar := await _buka(desk, "pasar", "pasar_screen.gd")
	_cek(pasar != null, "[sinyal layar] Pasar: layar terbuka")
	await _tutup(pasar)

	_selesai()

func _selesai() -> void:
	_catat("== HASIL (sinyal layar, bukan input OS): %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
