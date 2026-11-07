extends SceneTree

# Materi pembelajaran untuk SETIAP tahap (1-26) lewat aplikasi Email, dengan jalur sinyal layar:
# pilih baris pesan (id terikat ke sinyal pressed), tekan BACA, tekan BELAJAR, lalu periksa
# bahwa judul dan konsep materi tahap itu tampil. Bukan input OS.
# Dijalankan dari simpanan akhir (misi selesai, semua pesan tahap sudah masuk).

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_materi_semua_tahap.txt"

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
	if node is Button:
		t += (node as Button).text + " "
	if node is Label:
		t += (node as Label).text + " "
	if node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + " "
	for c in node.get_children():
		t += _teks_node(c)
	return t

func _buka(desk: Node, id: String, berkas: String) -> Node:
	var ikon: Button = desk.call("_tombol_id", id)
	if ikon == null:
		return null
	ikon.pressed.emit()
	await _secs(1.0)
	return await _tunggu_berkas(berkas)

func _judul_pesan(p: Dictionary) -> String:
	var k := String(p.get("judul", ""))
	var t := Bahasa.t(k)
	return t if t != k else Bahasa.pilih(k)

func _initialize() -> void:
	await process_frame
	var packed: PackedScene = load("res://scenes/main.tscn")
	root_app = packed.instantiate()
	get_root().add_child(root_app)
	await _frames(10)
	if OS.get_environment("BAHASA") == "en":
		Bahasa.kode = "en"
	var menu := await _tunggu_berkas("menu_utama.gd")
	if menu != null:
		await _secs(1.0)
		var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
		if lanjut != null:
			lanjut.pressed.emit()
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	_cek(desk != null, "[sinyal layar] desktop siap (simpanan selesai)")
	if desk == null:
		_selesai()
		return

	var sesi = _sesi()
	var data: Array = Misi.pembelajaran("misi_1")
	_cek(data.size() == 26, "materi tersedia untuk 26 tahap", "(%d)" % data.size())

	var lulus_tahap := 0
	for n in range(1, 27):
		var pesan: Dictionary = {}
		for pm in Email.pesan_misi(sesi):
			if int(pm.get("tahap", 0)) == n:
				pesan = pm
		if pesan.is_empty():
			_cek(false, "tahap %d: pesan email ada" % n)
			continue
		var email := await _buka(desk, "email", "email_app.gd")
		if email == null:
			_cek(false, "tahap %d: Email terbuka" % n)
			continue
		# Keluar dari pembaca atau materi sebelumnya agar daftar tampil.
		for kunci in ["misi.tombol_kembali", "email.keluar"]:
			var k := _cari_tombol(email, Bahasa.t(kunci))
			if k != null:
				k.pressed.emit()
				await _secs(0.3)
		var baris := _baris_pesan(email, String(pesan["id"]))
		_cek(baris != null, "tahap %d: baris pesan ditemukan" % n)
		if baris == null:
			await _tutup(email, desk)
			continue
		baris.pressed.emit()
		await _secs(0.3)
		var baca := _cari_tombol(email, Bahasa.t("email.baca"))
		if baca != null:
			baca.pressed.emit()
			await _secs(0.3)
		var belajar := _cari_tombol(email, Bahasa.t("misi.tombol_belajar"))
		_cek(belajar != null, "tahap %d: tombol BELAJAR aktif" % n)
		if belajar != null:
			belajar.pressed.emit()
			await _secs(0.4)
			var m: Dictionary = data[n - 1]
			var teks := _teks_node(email)
			var judul := Bahasa.pilih(String(m.get("judul", "")))
			var konsep := Bahasa.pilih(String(m.get("konsep", "")))
			var ok_judul := judul != "" and teks.to_lower().contains(judul.left(20).to_lower())
			var ok_konsep := konsep != "" and teks.to_lower().contains(konsep.left(20).to_lower())
			_cek(ok_judul, "tahap %d: judul materi tampil" % n, "(%s)" % judul.left(40))
			_cek(ok_konsep, "tahap %d: konsep materi tampil" % n, "(%s)" % konsep.left(40))
			if ok_judul and ok_konsep:
				lulus_tahap += 1
		await _tutup(email, desk)
	_catat("RINGKASAN: %d dari 26 tahap materinya lulus dibuka lewat UI" % lulus_tahap)
	_selesai()

func _tutup(app: Node, desk: Node) -> void:
	if app == null:
		return
	var kembali: Button = null
	for kunci in ["misi.tombol_kembali"]:
		var k := _cari_tombol(app, Bahasa.t(kunci))
		if k != null:
			kembali = k
	if kembali != null:
		kembali.pressed.emit()
		await _secs(0.3)
	var d := _cari_tombol_berisi(app, "Desktop")
	if d != null:
		d.pressed.emit()
		await _secs(0.6)

func _cari_tombol_berisi(node: Node, bagian: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.contains(bagian):
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol_berisi(c, bagian)
		if r != null:
			hasil = r
	return hasil

func _selesai() -> void:
	_catat("== HASIL (sinyal layar, bukan input OS): %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
