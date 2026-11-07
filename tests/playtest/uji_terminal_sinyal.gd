extends SceneTree

# Uji Terminal lewat jalur masukan layar, bukan pemanggilan fungsi langsung:
# - teks dimasukkan ke LineEdit masukan lalu sinyal text_submitted / text_changed dipancarkan,
#   sama seperti LineEdit menanggapi ketikan dan Enter;
# - tombol Ctrl dan ketukan berikutnya lewat sinyal pressed tombol itu.
# Ini BUKAN input OS: tidak ada event mouse/keyboard sungguhan. Hasilnya dicatat dengan label
# "sinyal layar" supaya tidak dianggap klik nyata.
# Dijalankan langsung di foreground dari simpanan yang sudah disiapkan runner.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_terminal_sinyal.txt"

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

# Menunggu animasi output Terminal selesai (busy = false), seperti pemain yang menunggu layar.
func _tunggu_terminal(term: Node, batas := 20.0) -> void:
	var t := 0.0
	while t < batas and bool(term.get("_busy")):
		await _secs(0.2)
		t += 0.2

func _cari_kelas(node: Node, kelas: String) -> Node:
	if node.is_class(kelas) and node.is_visible_in_tree():
		return node
	for c in node.get_children():
		var r := _cari_kelas(c, kelas)
		if r != null:
			return r
	return null

func _cari_tombol(node: Node, teks: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.strip_edges() == teks:
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol(c, teks)
		if r != null:
			hasil = r
	return hasil

func _teks_layar(node: Node) -> String:
	var t := ""
	if node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + "\n"
	for c in node.get_children():
		t += _teks_layar(c)
	return t

func _initialize() -> void:
	await process_frame
	var packed: PackedScene = load("res://scenes/main.tscn")
	root_app = packed.instantiate()
	get_root().add_child(root_app)
	await _frames(10)
	var menu := await _tunggu_berkas("menu_utama.gd")
	_cek(menu != null, "[sinyal layar] menu utama muncul")
	if menu == null:
		_selesai()
		return
	var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
	_cek(lanjut != null, "[sinyal layar] tombol Lanjutkan ada")
	if lanjut != null:
		lanjut.pressed.emit()
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	_cek(desk != null, "[sinyal layar] desktop siap")
	if desk == null:
		_selesai()
		return
	var ikon: Button = desk.call("_tombol_id", "terminal")
	ikon.pressed.emit()
	await _secs(1.2)
	var term := await _tunggu_berkas("terminal_screen.gd")
	_cek(term != null, "[sinyal layar] Terminal terbuka")
	if term == null:
		_selesai()
		return
	var masukan := _cari_kelas(term, "LineEdit") as LineEdit
	var sesi = SesiUtama.ambil()

	# Enter pada "apt install aircrack-ng": prompt Y/n harus muncul dan belum memasang apa pun.
	_cek(not sesi.repositori.punya("wireshark"), "[sinyal layar] wireshark belum terpasang di simpanan uji")
	masukan.text = "apt install wireshark"
	masukan.text_submitted.emit(masukan.text)
	await _tunggu_terminal(term)
	await _secs(0.5)
	_cek(_teks_layar(term).contains("Do you want to continue? [Y/n]"), "[sinyal layar] prompt Y/n muncul")
	_cek(not sesi.repositori.punya("wireshark"), "[sinyal layar] belum terpasang sebelum dijawab")

	# Ctrl lalu C: tombol Ctrl ditekan (pressed), lalu huruf c masuk ke LineEdit (text_changed).
	var tombol_ctrl := _cari_tombol(term, "Ctrl")
	_cek(tombol_ctrl != null, "[sinyal layar] tombol Ctrl ada")
	if tombol_ctrl != null:
		tombol_ctrl.pressed.emit()
		masukan.text = "c"
		masukan.text_changed.emit("c")
		await _secs(1.0)
	_cek(not sesi.konfirmasi_tertunda.is_valid(), "[sinyal layar] Ctrl+C membersihkan prompt Y/n")
	_cek(not sesi.repositori.punya("wireshark"), "[sinyal layar] Ctrl+C tidak memasang wireshark")
	_cek(_teks_layar(term).contains("^C"), "[sinyal layar] ^C tampil di layar")

	# Perintah berikutnya tetap berjalan normal setelah prompt dibatalkan.
	masukan.text = "whoami"
	masukan.text_submitted.emit(masukan.text)
	await _tunggu_terminal(term)
	_cek(_teks_layar(term).contains(String(sesi.user)), "[sinyal layar] whoami berjalan setelah Ctrl+C", "(user: %s)" % sesi.user)
	_selesai()

func _selesai() -> void:
	_catat("== HASIL (sinyal layar, bukan input OS): %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
