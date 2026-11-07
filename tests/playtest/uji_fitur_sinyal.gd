extends SceneTree

# Fitur yang sebelumnya belum diuji, lewat jalur layar (sinyal pressed / text_submitted / text_changed
# pada node UI yang hidup). BUKAN input OS. Dicatat sebagai "sinyal layar".
# 1. Pasar (Black Market): pembelian komponen lewat tombol Beli.
# 2. Terminal: airodump-ng mode live dihentikan dengan Ctrl+C sebagai masukan pemain.
# 3. Email: pesan dibuka, ditandai dibaca, dan tombol BELAJAR membuka materi tahapnya.
# Dijalankan langsung di foreground dari simpanan tahap 13.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_fitur_sinyal.txt"

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

# Tombol terlihat dan aktif dengan teks tepat. Kecocokan terakhir menurut urutan pohon.
func _cari_tombol(node: Node, teks: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and not (node as Button).disabled and (node as Button).text.strip_edges() == teks:
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol(c, teks)
		if r != null:
			hasil = r
	return hasil

# Tombol terlihat yang memuat teks tertentu di dalamnya (termasuk teks pada label anak).
func _tombol_memuat(node: Node, teks: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and _teks_node(node).contains(teks):
		hasil = node
	for c in node.get_children():
		var r := _tombol_memuat(c, teks)
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

# Judul pesan berupa kunci bahasa (misal email.panduan.judul) atau teks langsung.
func _judul(p: Dictionary) -> String:
	var k := String(p.get("judul", ""))
	var t := Bahasa.t(k)
	return t if t != k else Bahasa.pilih(k)

# Baris email dicocokkan lewat id pesan yang terikat ke sinyal pressed (_pilih_pesan.bind(id)).
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

func _kumpul_terikat(node: Node, hasil: Array) -> void:
	if node is Button:
		for c in (node as Button).get_signal_connection_list("pressed"):
			var args: Array = c["callable"].get_bound_arguments()
			if args.size() > 0:
				hasil.append(str(args[0]))
	for c in node.get_children():
		_kumpul_terikat(c, hasil)

# Tombol penjual: tombol yang terikat ke _pilih_penjual dengan id penjual tertentu.
func _tombol_penjual(node: Node, pid: String) -> Button:
	var hasil: Button = null
	if node is Button:
		for c in (node as Button).get_signal_connection_list("pressed"):
			var args: Array = c["callable"].get_bound_arguments()
			if args.size() > 0 and String(args[0]) == pid:
				hasil = node
	for c in node.get_children():
		var r := _tombol_penjual(c, pid)
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
	return _teks_node(node)

func _tunggu_terminal(term: Node, batas := 20.0) -> void:
	var t := 0.0
	while t < batas and bool(term.get("_busy")):
		await _secs(0.2)
		t += 0.2

func _buka(desk: Node, id: String, berkas: String) -> Node:
	var ikon: Button = desk.call("_tombol_id", id)
	_cek(ikon != null, "[sinyal layar] ikon %s ada" % id)
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
	var t := _tombol_memuat(app, "Desktop")
	if t != null:
		t.pressed.emit()
		await _secs(0.8)

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

	await _uji_pasar(desk)
	await _uji_ctrl_c_live(desk)
	await _uji_email(desk)
	_selesai()

# --- 1. Pasar: pembelian komponen ---
func _uji_pasar(desk: Node) -> void:
	var pasar := await _buka(desk, "pasar", "pasar_screen.gd")
	if pasar == null:
		return
	var saldo_awal: int = _sesi().economy.saldo
	var komponen := _cari_tombol(pasar, Bahasa.t("pasar.komponen"))
	_cek(komponen != null, "[sinyal layar] Pasar: tombol Komponen ada")
	if komponen != null:
		komponen.pressed.emit()
		await _secs(0.3)
	var beli := _cari_tombol(pasar, Bahasa.t("pasar.beli"))
	_cek(beli != null, "[sinyal layar] Pasar: tombol Beli aktif ada", "(saldo %d)" % saldo_awal)
	if beli != null:
		beli.pressed.emit()
		await _secs(0.4)
		var saldo_baru: int = _sesi().economy.saldo
		_cek(saldo_baru < saldo_awal, "[sinyal layar] Pasar: Beli mengurangi saldo", "(%d -> %d)" % [saldo_awal, saldo_baru])
	# Saldo habis: tombol Beli dinonaktifkan atau pembelian ditolak dengan pesan.
	# Pembelian item dari penjual: prasyarat saldo 5000 dicatat, lalu penjual dipilih dan item pertama dibeli.
	await _tutup(pasar)
	_sesi().economy.saldo = 5000
	var pasar_p := await _buka(desk, "pasar", "pasar_screen.gd")
	if pasar_p != null:
		var penjual := _tombol_penjual(pasar_p, String(BlackMarket.penjual_ids()[0]))
		_cek(penjual != null, "[sinyal layar] Pasar: tombol penjual ada")
		if penjual != null:
			penjual.pressed.emit()
			await _secs(0.3)
		var saldo_p: int = _sesi().economy.saldo
		var beli_item := _cari_tombol(pasar_p, Bahasa.t("pasar.beli"))
		_cek(beli_item != null, "[sinyal layar] Pasar penjual: tombol Beli item aktif")
		if beli_item != null:
			beli_item.pressed.emit()
			await _secs(0.4)
			_cek(_sesi().economy.saldo < saldo_p, "[sinyal layar] Pasar penjual: Beli item mengurangi saldo", "(%d -> %d)" % [saldo_p, _sesi().economy.saldo])
		await _tutup(pasar_p)

	# Prasyarat: saldo diatur nol lalu Pasar dibuka ulang (layar merender ulang tombolnya).
	await _tutup(pasar)
	_sesi().economy.saldo = 0
	var pasar2 := await _buka(desk, "pasar", "pasar_screen.gd")
	if pasar2 != null:
		var komponen2 := _cari_tombol(pasar2, Bahasa.t("pasar.komponen"))
		if komponen2 != null:
			komponen2.pressed.emit()
			await _secs(0.3)
		var beli_kosong := _cari_tombol(pasar2, Bahasa.t("pasar.beli"))
		_cek(beli_kosong != null, "[sinyal layar] Pasar: tombol Beli tetap ada saat saldo nol")
		if beli_kosong != null:
			beli_kosong.pressed.emit()
			await _secs(0.4)
		_cek(_sesi().economy.saldo == 0, "[sinyal layar] Pasar: saldo nol menolak pembelian, saldo tetap 0")
		await _tutup(pasar2)

# --- 2. Ctrl+C pada airodump-ng mode live ---
func _uji_ctrl_c_live(desk: Node) -> void:
	var term := await _buka(desk, "terminal", "terminal_screen.gd")
	if term == null:
		return
	var masukan := _cari_kelas(term, "LineEdit") as LineEdit
	var sesi = _sesi()
	masukan.text = "airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon"
	masukan.text_submitted.emit(masukan.text)
	await _tunggu_terminal(term)
	await _secs(0.5)
	_cek(bool(term.get("_live")) or sesi.live_aktif(), "[sinyal layar] airodump-ng mode live aktif")
	var tombol_ctrl := _cari_tombol(term, "Ctrl")
	if tombol_ctrl != null:
		tombol_ctrl.pressed.emit()
		masukan.text = "c"
		masukan.text_changed.emit("c")
		await _secs(1.0)
	_cek(not bool(term.get("_live")) and not sesi.live_aktif(), "[sinyal layar] Ctrl+C menghentikan mode live")
	_cek(_teks_layar(term).contains("^C"), "[sinyal layar] ^C tampil setelah live dihentikan")
	masukan.text = "whoami"
	masukan.text_submitted.emit(masukan.text)
	await _tunggu_terminal(term)
	_cek(_teks_layar(term).contains(String(sesi.user)), "[sinyal layar] perintah normal berjalan setelah live dihentikan")
	await _tutup(term)

# --- 3. Email: baca, tandai dibaca, dan BELAJAR ---
func _uji_email(desk: Node) -> void:
	var email := await _buka(desk, "email", "email_app.gd")
	if email == null:
		return
	var sesi = _sesi()
	var daftar: Array = Email.daftar(sesi, "masuk")
	_cek(daftar.size() > 0, "[sinyal layar] Email: ada pesan masuk", "(%d pesan)" % daftar.size())
	if daftar.size() > 0:
		var p: Dictionary = daftar[0]
		var judul := _judul(p)
		var baris := _tombol_memuat(email, judul.left(12)) if judul.length() > 0 else null
		_cek(baris != null, "[sinyal layar] Email: baris pesan ditemukan", "(%s)" % judul.left(40))
		if baris != null:
			baris.pressed.emit()
			await _secs(0.4)
		var baca := _cari_tombol(email, Bahasa.t("email.baca"))
		_cek(baca != null, "[sinyal layar] Email: tombol BACA aktif")
		if baca != null:
			baca.pressed.emit()
			await _secs(0.4)
		_cek(Email.sudah_dibaca(sesi, String(p["id"])), "[sinyal layar] Email: pesan tercatat dibaca")
	# Pesan tahap misi dengan materi belajar: tombol BELAJAR harus membuka materi.
	# Email dibuka ulang agar kembali ke daftar (setelah BACA, layar menampilkan pembaca).
	# Pembaca masih terbuka dari BACA sebelumnya: KELUAR kembali ke daftar pesan.
	var keluar := _cari_tombol(email, Bahasa.t("email.keluar"))
	if keluar != null:
		keluar.pressed.emit()
		await _secs(0.4)
	var pesan_tahap: Array = []
	for pm in Email.pesan_misi(sesi):
		if int(pm.get("tahap", 0)) > 0 and not Misi.pembelajaran(String(pm.get("misi", ""))).is_empty() and Email.status(sesi, String(pm["id"])) == "masuk":
			pesan_tahap.append(pm)
	_cek(pesan_tahap.size() > 0, "[sinyal layar] Email: ada pesan tahap dengan materi belajar", "(%d pesan)" % pesan_tahap.size())
	if pesan_tahap.size() > 0:
		var pm: Dictionary = pesan_tahap[0]
		var mat: Array = Misi.pembelajaran(String(pm.get("misi", "")))
		var judul_pm := _judul(pm)
		var baris := _baris_pesan(email, String(pm["id"]))
		if baris != null:
			baris.pressed.emit()
			await _secs(0.4)
		_cek(String(email.get("_pilih")) == String(pm["id"]), "[sinyal layar] Email: pesan tahap terpilih lewat barisnya")
		var baca_tahap := _cari_tombol(email, Bahasa.t("email.baca"))
		if baca_tahap != null:
			baca_tahap.pressed.emit()
			await _secs(0.4)
		var belajar := _cari_tombol(email, Bahasa.t("misi.tombol_belajar"))
		_cek(belajar != null, "[sinyal layar] Email: tombol BELAJAR aktif untuk tahap %d" % int(pm.get("tahap", 0)))
		if belajar != null:
			belajar.pressed.emit()
			await _secs(0.5)
			var contoh := Bahasa.pilih(String(mat[0].get("judul", ""))) if mat.size() > 0 and mat[0] is Dictionary else ""
			_cek(contoh != "" and _teks_layar(email).contains(contoh.left(12)), "[sinyal layar] Email: materi belajar tampil", "(%s)" % contoh.left(40))
	await _tutup(email)

func _selesai() -> void:
	_catat("== HASIL (sinyal layar, bukan input OS): %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
