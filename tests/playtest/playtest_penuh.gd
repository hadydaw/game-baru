extends SceneTree

const UA := preload("res://tests/uji_aplikasi.gd")

# Playtest penuh lewat antarmuka: tombol ditekan dan perintah diketik ke Terminal sungguhan.
# Mode "baru": mulai sesi baru sampai tahap 13, simpan, lalu keluar.
# Mode "lanjut": muat simpanan, selesaikan tahap 14-26, lalu uji hal-hal di luar alur.
# Hasil dicatat ke LOG dan tangkapan layar ke SHOTS.

const SHOTS := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/shots"
const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/log_%s.txt"

var mode := "baru"
var ukuran := "360x640"
var lines: PackedStringArray = []
var bugs: PackedStringArray = []
var root_app: Node
var nomor_shot := 0

func _log(s: String) -> void:
	print(s)
	lines.append(s)

func _bug(s: String) -> void:
	bugs.append(s)
	_log("BUG? " + s)

func _frames(n := 3) -> void:
	for i in range(n):
		await process_frame

func _secs(t: float) -> void:
	await create_timer(t).timeout

func _shot(nama: String) -> void:
	nomor_shot += 1
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png("%s/%s_%s_%02d_%s.png" % [SHOTS, mode, ukuran, nomor_shot, nama])

# Cocokkan teks tepat dulu; bila tidak ada, boleh sebagian (agar "HAPUS" tidak tertukar dengan "MENGHAPUS").
func _cari_tombol(node: Node, teks: String, persis := true) -> Button:
	var b := _cari_tombol_teks(node, teks, true)
	if b == null and not persis:
		b = _cari_tombol_teks(node, teks, false)
	return b

# Kecocokan terakhir menurut urutan pohon: dialog yang ditambahkan belakangan berada di atas.
func _cari_tombol_teks(node: Node, teks: String, persis: bool) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and not (node as Button).disabled:
		var t := (node as Button).text.strip_edges()
		if t == teks or (not persis and t.contains(teks)):
			hasil = node
	for c in node.get_children():
		var r := _cari_tombol_teks(c, teks, persis)
		if r != null:
			hasil = r
	return hasil

func _semua_tombol(node: Node, hasil: Array = []) -> Array:
	if node is Button and (node as Button).is_visible_in_tree():
		hasil.append((node as Button).text)
	for c in node.get_children():
		_semua_tombol(c, hasil)
	return hasil

# ---- Input nyata: klik mouse dan tombol keyboard lewat InputEvent, bukan pressed.emit() ----
func _klik_nyata(c: Control) -> void:
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

# Tombol yang terlihat dengan teks tepat, di luar cakupan node "kecuali" (mis. dialog di atas aplikasi).
func _cari_tombol_di_luar(akar: Node, kecuali: Node, teks: String) -> Button:
	for b in akar.find_children("*", "Button", true, false):
		var tb := b as Button
		if tb.is_visible_in_tree() and not tb.disabled and tb.text.strip_edges() == teks and not kecuali.is_ancestor_of(tb):
			return tb
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

# Menggulir ScrollContainer induk dengan roda mouse sampai baris terlihat utuh.
func _gulir_ke(baris: Control) -> void:
	var gulir: ScrollContainer = null
	var p: Node = baris.get_parent()
	while p != null and gulir == null:
		if p is ScrollContainer:
			gulir = p
		p = p.get_parent()
	if gulir == null:
		return
	for i in range(80):
		var area := gulir.get_global_rect()
		var r := baris.get_global_rect()
		if r.position.y >= area.position.y and r.end.y <= area.end.y:
			return
		var pusat := gulir.get_global_transform_with_canvas() * (gulir.size / 2.0)
		var pos := get_root().get_final_transform() * pusat
		Input.warp_mouse(pos)
		await _frames(2)
		var arah := MOUSE_BUTTON_WHEEL_DOWN if r.end.y > area.end.y else MOUSE_BUTTON_WHEEL_UP
		var w := InputEventMouseButton.new()
		w.button_index = arah
		w.position = pos
		w.global_position = pos
		w.pressed = true
		Input.parse_input_event(w)
		await _frames(2)
		var lepas := w.duplicate()
		lepas.pressed = false
		Input.parse_input_event(lepas)
		await _frames(4)

# Mengisi kolom teks dengan klik lalu ketikan keyboard (hapus isi lama dulu).
func _isi_nyata(kolom: LineEdit, teks: String) -> void:
	await _klik_nyata(kolom)
	for i in range(40):
		await _tekan(KEY_BACKSPACE, 8)
	for ch in teks:
		await _tekan(ch.to_upper().unicode_at(0), ch.unicode_at(0))

func _klik(node: Node, teks: String) -> bool:
	var b := _cari_tombol(node, teks)
	if b == null:
		_log("  [tidak ada tombol] '%s'" % teks)
		return false
	_log("  KLIK '%s'" % teks)
	await _gulir_ke(b)
	await _klik_nyata(b)
	return true

const BERKAS := {"MenuUtama": "menu_utama.gd", "LayarCerita": "layar_cerita.gd", "PilihLokasi": "pilih_lokasi.gd", "PopupSambutan": "popup_sambutan_email.gd", "PusatMisi": "pusat_misi.gd", "EmailApp": "email_app.gd", "NetworkManager": "network_manager.gd"}

func _cari_berkas(node: Node, berkas: String) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("/" + berkas):
		return node
	for c in node.get_children():
		var r := _cari_berkas(c, berkas)
		if r != null:
			return r
	return null

func _tunggu_node(nama: String, batas := 15.0) -> Node:
	var t := 0.0
	while t < batas:
		var n := _cari_berkas(root_app, BERKAS[nama])
		if n != null and n.is_inside_tree():
			return n
		await _secs(0.2)
		t += 0.2
	return null

func _teks_node(node: Node) -> String:
	var t := ""
	if node is Button:
		t += (node as Button).text + "\n"
	if node is Label:
		t += (node as Label).text + "\n"
	if node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + "\n"
	for c in node.get_children():
		t += _teks_node(c)
	return t

# Mencoba beberapa label (Indonesia lalu Inggris) agar uji berlaku untuk kedua bahasa.
func _klik_baris_salah_satu(node: Node, pilihan: Array) -> bool:
	for t in pilihan:
		for b in node.find_children("*", "Button", true, false):
			if (b as Button).is_visible_in_tree() and _teks_node(b).contains(String(t)):
				_log("  KLIK baris '%s'" % String(t))
				await _gulir_ke(b)
				await _klik_nyata(b)
				return true
	_log("  [tidak ada baris] %s" % str(pilihan))
	return false

func _klik_baris(node: Node, teks: String) -> bool:
	return await _klik_baris_salah_satu(node, [teks])

func _ketik(term: Node, cmd: String) -> void:
	_log("  KETIK> " + cmd)
	var m: LineEdit = term.get("_masukan")
	await _klik_nyata(m)
	for ch in cmd:
		await _tekan(ch.to_upper().unicode_at(0), ch.unicode_at(0))
	await _tekan(KEY_ENTER, 10)
	await _frames(2)
	# Tunggu animasi keluaran selesai dan antrean kosong, seperti pemain yang menunggu layar.
	var t := 0.0
	while t < 30.0 and (bool(term.get("_busy")) or not (term.get("_antrean") as Array).is_empty()):
		await _secs(0.1)
		t += 0.1

func _ctrl_c(term: Node) -> void:
	_log("  KETIK> [Ctrl+C]")
	var tombol_ctrl := _cari_tombol(term, "Ctrl")
	if tombol_ctrl != null:
		await _klik_nyata(tombol_ctrl)
	var m: LineEdit = term.get("_masukan")
	await _klik_nyata(m)
	await _tekan(KEY_C, 99)
	await _frames(3)

func _tampil_terminal() -> Node:
	return _cari_berkas(root_app, "terminal_screen.gd")

func _cari_node_kelas(node: Node, kelas: String) -> Node:
	if node.get_class() == kelas or (node.get_script() != null and String(node.get_script().resource_path).ends_with("terminal_screen.gd")):
		return node
	for c in node.get_children():
		var r := _cari_node_kelas(c, kelas)
		if r != null:
			return r
	return null

# Tombol X (win_close) pada jendela aplikasi yang terbuka; yang terakhir di pohon adalah yang paling atas.
func _cari_tutup_jendela(node: Node, berkas_ikon := "win_minimize_normal.png") -> Control:
	var h: Control = null
	if node is TextureButton and (node as TextureButton).is_visible_in_tree() and (node as TextureButton).texture_normal != null and (node as TextureButton).texture_normal.resource_path.ends_with(berkas_ikon):
		h = node
	for c in node.get_children():
		var r := _cari_tutup_jendela(c, berkas_ikon)
		if r != null:
			h = r
	return h

# Pemain meminimalkan jendela yang menutupi desktop sebelum membuka aplikasi lain (status aplikasi tetap).
func _tutup_jendela_aktif() -> void:
	for i in range(4):
		var t := _cari_tutup_jendela(root_app)
		if t == null:
			return
		_log("  KECILKAN JENDELA (–)")
		await _klik_nyata(t)
		await _secs(0.5)

func _buka_app(id: String) -> void:
	await _tutup_jendela_aktif()
	var desk := _cari_berkas(root_app, "desktop_view.gd")
	var ikon: Button = desk.call("_tombol_id", id) if desk != null else null
	if ikon == null:
		_bug("ikon '%s' tidak ada di desktop" % id)
		return
	_log("  BUKA APLIKASI '%s' (ketuk ikon)" % id)
	await _klik_nyata(ikon)
	await _frames(20)

func _sesi():
	return SesiUtama.ambil()

func _initialize() -> void:
	mode = OS.get_environment("PLAY_MODE") if OS.get_environment("PLAY_MODE") != "" else "baru"
	ukuran = OS.get_environment("UKURAN_HP") if OS.get_environment("UKURAN_HP") != "" else "360x640"
	await process_frame
	var packed: PackedScene = load("res://scenes/main.tscn")
	root_app = packed.instantiate()
	get_root().add_child(root_app)
	if mode == "baru":
		await _alur_baru()
	elif mode == "live":
		await _alur_live()
	elif mode == "salin":
		await _alur_salin()
	else:
		await _alur_lanjut()
	var f := FileAccess.open(LOG % mode, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n\nBUG/CATATAN:\n" + "\n".join(bugs) + "\n")
	f.close()
	quit(0)

func _alur_baru() -> void:
	_log("== MODE BARU, ukuran %s ==" % ukuran)
	var menu := await _tunggu_node("MenuUtama")
	if menu == null:
		_bug("menu utama tidak muncul")
		return
	_log("Tombol menu: " + str(_semua_tombol(menu)))
	await _shot("menu")
	await _klik(menu, Bahasa.t("menu.pengaturan"))
	await _shot("pengaturan")
	_log("Tombol pengaturan: " + str(_semua_tombol(menu)))
	await _klik(menu, Bahasa.t("pengaturan.ukuran_besar"))
	await _klik(menu, Bahasa.t("pengaturan.ukuran_sedang"))
	await _klik(menu, Bahasa.NAMA["en"])
	menu = await _tunggu_node("MenuUtama")
	await _shot("pengaturan_en")
	await _klik(menu, Bahasa.t("umum.kembali"))
	await _shot("menu_en")
	_log("  tombol menu setelah English: " + str(_semua_tombol(menu)))
	if _cari_tombol(menu, Bahasa.t("menu.sesi_baru")) == null or _cari_tombol(menu, "> New Session") == null:
		_bug("setelah ganti ke English dan kembali, label menu utama belum English")
	await _klik(menu, Bahasa.t("menu.pengaturan"))
	# Bahasa akhir permainan: BAHASA_UJI=en untuk menguji English, default Indonesia.
	var bahasa_uji := OS.get_environment("BAHASA_UJI") if OS.get_environment("BAHASA_UJI") != "" else "id"
	await _klik(menu, Bahasa.NAMA[bahasa_uji])
	menu = await _tunggu_node("MenuUtama")
	await _klik(menu, Bahasa.t("umum.kembali"))
	if _cari_tombol(menu, Bahasa.t("menu.sesi_baru")) == null:
		_bug("setelah kembali ke bahasa %s, label menu tidak sesuai" % bahasa_uji)
	await _klik(menu, Bahasa.t("menu.login"))
	await _shot("login_kosong")
	var input: LineEdit = menu.get("_input_nama")
	await _isi_nyata(input, "a")
	await _klik(menu, Bahasa.t("umum.simpan"))
	_log("  pesan login salah: '%s'" % String(menu.get("_lbl_error_login").text))
	await _isi_nyata(input, "Pemain_Uji")
	await _klik(menu, Bahasa.t("umum.simpan"))
	_log("  nama profil tersimpan: %s" % Pengaturan.nama_profil())
	await _klik(menu, Bahasa.t("umum.kembali"))
	await _klik(menu, Bahasa.t("menu.sesi_baru"))
	_log("  ada simpanan sebelum sesi baru: %s" % str(Penyimpanan.ada_simpanan()))
	if Penyimpanan.ada_simpanan():
		await _klik(menu, Bahasa.t("dialog.mulai_baru"))
	var cerita := await _tunggu_node("LayarCerita")
	if cerita == null:
		_bug("layar cerita pembuka tidak muncul setelah Sesi Baru")
		return
	var n := 0
	while cerita != null and n < 12 and _cari_tombol(cerita, Bahasa.t("intro.mulai")) == null:
		await _klik(cerita, Bahasa.t("intro.lanjut"))
		n += 1
		await _secs(0.6)
	await _shot("cerita_akhir")
	await _klik(cerita, Bahasa.t("intro.mulai"))
	var pilih := await _tunggu_node("PilihLokasi")
	if pilih == null:
		_bug("layar pilih lokasi tidak muncul")
		return
	await _shot("pilih_lokasi")
	var titik: Dictionary = pilih.get("_titik_negara")
	_log("  jumlah titik negara di peta: %d" % titik.size())
	var kode_negara := "ID" if titik.has("ID") else String(titik.keys()[0])
	_log("  pilih negara %s (ketuk titik di peta)" % kode_negara)
	await _klik_nyata(titik[kode_negara])
	await _frames()
	var kota: Dictionary = pilih.get("_tombol_kota")
	_log("  jumlah kota: %d" % kota.size())
	if kota.size() > 0:
		var k0 = kota.keys()[0]
		_log("  pilih kota %s" % k0)
		await _klik_nyata(kota[k0])
	await _frames()
	await _shot("lokasi_dipilih")
	await _klik(pilih, Bahasa.t("intro.mulai"))
	await _secs(1.5)
	var popup := await _tunggu_node("PopupSambutan", 5.0)
	if popup == null:
		_bug("popup sambutan email tidak muncul di sesi baru")
	else:
		await _shot("popup_sambutan")
		await _klik(popup, Bahasa.t("email.sambutan_ok"))
	_log("Aplikasi email terbuka: %s" % str(_cari_berkas(root_app, "email_app.gd") != null))
	await _shot("desktop_awal")
	await _alur_misi_dan_tahap(1, 13)
	# Simpan dan keluar.
	var s = _sesi()
	Penyimpanan.simpan_sesi(s)
	_log("Simpan tahap 1-13 selesai, tahap aktif = %d" % Misi.tahap_aktif(s, Misi.temukan("misi_1")))

# Uji Salin dan Tempel di Terminal: pilih keluaran, tekan SALIN (klik nyata), lalu TEMPEL ke kolom perintah.
func _alur_salin() -> void:
	_log("== MODE SALIN ==")
	var menu := await _tunggu_node("MenuUtama")
	if menu == null:
		_bug("menu utama tidak muncul")
		return
	if _cari_tombol(menu, Bahasa.t("menu.lanjutkan")) == null:
		# Tanpa simpanan: mulai sesi baru lewat alur penuh, lalu lanjut ke Terminal.
		_log("  tidak ada simpanan, memakai alur baru")
		await _alur_baru()
	else:
		await _klik(menu, Bahasa.t("menu.lanjutkan"))
	await _secs(1.5)
	await _buka_app("terminal")
	var term: Node = null
	var t := 0.0
	while term == null and t < 8.0:
		term = _cari_berkas(root_app, "terminal_screen.gd")
		if term == null:
			await _secs(0.3)
			t += 0.3
	if term == null:
		_bug("terminal tidak terbuka")
		return
	await _ketik(term, "lsusb")
	var keluaran := term.get("_keluaran") as RichTextLabel
	keluaran.select_all()
	await _frames(2)
	_log("  seleksi keluaran: '%s'" % keluaran.get_selected_text().left(40).replace("\n", " | "))
	await _klik(term, Bahasa.t("term.salin"))
	await _frames(2)
	var papan := DisplayServer.clipboard_get()
	_log("  SALIN: papan klip %d karakter, baris pertama '%s'" % [papan.length(), papan.split("\n")[0].left(40)])
	var masukan: LineEdit = term.get("_masukan")
	await _isi_nyata(masukan, "")
	await _klik(term, Bahasa.t("term.tempel"))
	await _frames(2)
	var baris_pertama := papan.split("\n")[0].strip_edges()
	var cocok := masukan.text == baris_pertama and baris_pertama != ""
	_log("  TEMPEL: kolom berisi '%s' (cocok dengan papan klip=%s)" % [masukan.text.left(40), str(cocok)])
	if not cocok:
		_bug("tempel tidak menyisipkan baris pertama papan klip")

func _alur_lanjut() -> void:
	_log("== MODE LANJUT, ukuran %s ==" % ukuran)
	var menu := await _tunggu_node("MenuUtama")
	if menu == null:
		_bug("menu utama tidak muncul")
		return
	await _shot("menu_lanjut")
	await _klik(menu, Bahasa.t("menu.lanjutkan"))
	await _secs(1.5)
	await _shot("setelah_lanjut")
	var s = _sesi()
	_log("Setelah muat: tahap aktif = %d, misi = %s" % [Misi.tahap_aktif(s, Misi.temukan("misi_1")), str(s.misi.get("misi_1",""))])
	await _alur_misi_dan_tahap(14, 26)
	await _probe_email()
	await _probe_terminal()

# Mode live: dari simpanan tahap 13 (monitor aktif), airodump-ng berjalan lalu pemain pindah aplikasi.
func _alur_live() -> void:
	_log("== MODE LIVE, ukuran %s ==" % ukuran)
	var menu := await _tunggu_node("MenuUtama")
	await _klik(menu, Bahasa.t("menu.lanjutkan"))
	await _secs(1.5)
	await _buka_app("terminal")
	var term := _cari_berkas(root_app, "terminal_screen.gd")
	await _ketik(term, "airodump-ng wlan0mon")
	await _secs(1.5)
	var awal: String = _teks_node(term)
	_log("  live awal: %s" % str(term.get("_live")))
	await _shot("live_awal")
	await _buka_app("email")
	await _secs(2.5)
	await _buka_app("terminal")
	await _secs(1.2)
	_log("  live setelah pindah aplikasi dan kembali: %s" % str(term.get("_live")))
	var elapsed_a := (_teks_node(term) as String).count("Elapsed")
	await _shot("live_kembali")
	await _ketik(term, "help")
	_log("  input saat live: antrean=%d" % (term.get("_antrean") as Array).size())
	await _shot("live_input_ditolak")
	await _ctrl_c(term)
	await _secs(1.0)
	_log("  setelah Ctrl+C: live=%s busy=%s" % [str(term.get("_live")), str(term.get("_busy"))])
	await _shot("live_setelah_ctrl_c")

# Pemain membuka E-Mail: baca, kembali, hapus, pulihkan, lalu hapus permanen dengan konfirmasi.
func _probe_email() -> void:
	_log("== PROBE E-MAIL ==")
	await _buka_app("email")
	var email := await _tunggu_node("EmailApp", 3.0)
	if email == null:
		_bug("aplikasi email tidak terbuka")
		return
	_log("  tombol email awal: " + str(_semua_tombol(email)))
	await _klik_baris_salah_satu(email, ["Penting: panduan memulai", "Important: getting started"])
	await _klik(email, Bahasa.t("email.baca"))
	await _shot("email_baca")
	await _klik(email, Bahasa.t("email.keluar"))
	await _klik_baris_salah_satu(email, ["Jangan percaya", "Don't trust"])
	await _klik(email, Bahasa.t("email.hapus"))
	await _shot("email_setelah_hapus")
	await _klik(email, Bahasa.t("email.sampah"))
	await _shot("email_sampah")
	await _klik_baris_salah_satu(email, ["Jangan percaya", "Don't trust"])
	await _klik(email, Bahasa.t("email.baca"))
	await _shot("email_sampah_baca")
	await _klik(email, Bahasa.t("email.pulihkan"))
	await _shot("email_pulih")
	# Setelah dipulihkan, pesan harus kembali ke Masuk. Dicek di tab Masuk, lalu dihapus lagi ke Sampah.
	await _klik(email, Bahasa.t("email.tab_masuk"))
	var masuk_ada := await _klik_baris_salah_satu(email, ["Jangan percaya", "Don't trust"])
	_log("  setelah pulihkan, ada di Masuk: %s" % str(masuk_ada))
	await _klik_baris_salah_satu(email, ["Jangan percaya", "Don't trust"])
	await _klik(email, Bahasa.t("email.baca"))
	await _klik(email, Bahasa.t("email.hapus"))
	await _klik(email, Bahasa.t("email.sampah"))
	await _klik_baris_salah_satu(email, ["Jangan percaya", "Don't trust"])
	await _klik(email, Bahasa.t("email.baca"))
	await _klik(email, Bahasa.t("email.hapus_permanen"))
	await _shot("email_konfirmasi_hapus")
	_log("  tombol konfirmasi: " + str(_semua_tombol(root_app)))
	await _klik(root_app, Bahasa.t("umum.batal"))
	_log("  setelah batal, pesan masih di sampah: %s" % str(_teks_node(email).contains("Jangan percaya") or _teks_node(email).contains("Don't trust")))
	# Konfirmasi: HAPUS di dalam dialog "Hapus permanen?" (bukan tombol HAPUS di pembaca).
	await _klik(email, Bahasa.t("email.hapus_permanen"))
	var konfirmasi := _cari_tombol(email, Bahasa.t("email.hapus_permanen"))
	if konfirmasi == null:
		_bug("dialog konfirmasi hapus permanen tidak muncul")
	else:
		_log("  KLIK konfirmasi 'HAPUS' (dialog)")
		await _klik_nyata(konfirmasi)
		await _secs(0.6)
	await _shot("email_setelah_hapus_permanen")
	_log("  pesan 'Jangan percaya' setelah hapus permanen: %s" % str(_teks_node(email).contains("Jangan percaya") or _teks_node(email).contains("Don't trust")))

# Input yang salah dan keadaan tidak wajar di Terminal, diketik seperti pemain iseng.
func _probe_terminal() -> void:
	_log("== PROBE TERMINAL ==")
	await _buka_app("terminal")
	var term := _cari_berkas(root_app, "terminal_screen.gd")
	var uji := ["", "   ", "xyz", "airodump-ng", "airodump-ng -c", "airodump-ng -c abc wlan0mon", "airodump-ng -t FOO wlan0mon", "airodump-ng -d xx wlan0mon", "airodump-ng wlan0", "airodump-ng -z wlan0mon", "airmon-ng", "airmon-ng stop wlan0mon", "airmon-ng start wlan1", "security", "network-analyzer report", "network-analyzer report LAB-WIFI-99", "network-analyzer verify", "audit", "password-auditor run", "tools", "tools install", "toko beli", "__beli__xyz", "device", "man", "man xyz", "help", "help", "help", "network-analyzer report LAB-WIFI-01", "wifi", "ls", "cd /", "pwd", "echo %s"]
	for c in uji:
		await _ketik(term, c)
	await _shot("terminal_uji_salah")
	_log("  prompt setelah input salah: busy=%s live=%s" % [str(term.get("_busy")), str(term.get("_live"))])
	# Airodump-ng live, lalu pemain membuka aplikasi lain dan kembali. Mode monitor dihidupkan lagi
	# karena daftar input salah di atas sempat mematikannya (airmon-ng stop).
	await _ketik(term, "airmon-ng start wlan0")
	await _ketik(term, "airodump-ng wlan0mon")
	await _secs(1.5)
	_log("  live awal: %s" % str(term.get("_live")))
	await _buka_app("email")
	await _secs(1.5)
	await _buka_app("terminal")
	await _secs(1.2)
	_log("  live setelah pindah aplikasi dan kembali: %s" % str(term.get("_live")))
	await _shot("live_setelah_pindah_app")
	await _ketik(term, "apt list --installed")
	await _ctrl_c(term)
	await _secs(0.5)
	_log("  setelah Ctrl+C: live=%s busy=%s" % [str(term.get("_live")), str(term.get("_busy"))])
	await _ctrl_c(term)
	await _ketik(term, "lsusb")
	await _shot("terminal_setelah_probe")
	var f := FileAccess.open("/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/terminal_probe_%s.txt" % ukuran, FileAccess.WRITE)
	f.store_string((term.get("_keluaran") as RichTextLabel).get_parsed_text())
	f.close()
	_log("  antrean akhir: %d" % (term.get("_antrean") as Array).size())

# Setiap tahap: ketik perintah sesuai email tugas, lalu cek tahap berikutnya.
var PERINTAH := {
	1: ["help"], 2: ["lsusb"], 3: ["__beli__usb_wireless_adapter"], 4: ["__beli__antena_eksternal"],
	5: ["__beli__kabel_usb"], 6: ["__rakit__"], 7: ["apt search driver"], 8: ["apt install driver-ar9271", "y"],
	9: ["__hubungkan__"], 10: ["apt install -y aircrack-ng"],
	11: ["airmon-ng start wlan0", "airodump-ng wlan0mon"], 12: ["__netmgr__"],
	13: ["airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon"], 14: ["apt install -y network-analyzer"],
	15: ["network-analyzer analyze LAB-WIFI-01"], 16: ["man password-auditor"], 17: ["apt install -y password-auditor"],
	18: ["apt list --installed"], 19: ["man aircrack-ng"], 20: ["password-auditor auth LAB-WIFI-01"], 21: ["man airodump-ng"],
	22: ["man john"], 23: ["password-auditor run LAB-WIFI-01"], 24: ["man network-analyzer"],
	25: ["network-analyzer verify LAB-WIFI-01 KUNCI_UJI"], 26: ["network-analyzer report LAB-WIFI-01"],
}

# Catatan keadaan ekonomi: saldo Kr, XP, reputasi, inventaris, dan hadiah yang sudah diambil.
func _snap(tag: String) -> void:
	var s = _sesi()
	_log("  SNAP %s: saldo=%d xp=%d reputasi=%s inventaris=%s hadiah=%s" % [tag, s.economy.saldo, s.xp, JSON.stringify(s.reputation.to_dict()), JSON.stringify(s.inventory.to_dict()), JSON.stringify(s.hadiah_diambil)])

func _alur_misi_dan_tahap(dari: int, sampai: int) -> void:
	var s = _sesi()
	var m := Misi.temukan("misi_1")
	var term_ada := false
	for n in range(dari, sampai + 1):
		var aktif := Misi.tahap_aktif(s, m)
		if aktif != n:
			_bug("tahap aktif %d, seharusnya %d sebelum mengerjakan tahap %d" % [aktif, n, n])
		_log("== TAHAP %d (aktif=%d) ==" % [n, aktif])
		_snap("awal tahap %d" % n)
		if n == 1:
			await _buka_app("misi")
			var misi_app := await _tunggu_node("PusatMisi", 3.0)
			if misi_app == null:
				_bug("aplikasi Misi tidak terbuka")
			else:
				await _klik_baris(misi_app, Bahasa.t("misi.kat.tutorial"))
				await _secs(0.6)
				await _klik_baris_salah_satu(misi_app, ["Tutorial Misi 1", "Tutorial Mission 1"])
				await _shot("pusat_misi_detail")
				await _klik(misi_app, Bahasa.t("misi.tombol_pilih"))
				await _shot("pusat_misi_terpilih")
				await _klik(misi_app, Bahasa.t("misi.tombol_terima"))
				await _shot("pusat_misi_diterima")
			Misi.perbarui(s)
			_log("  Email tahap 1 sudah masuk: %d" % _email_tahap(s, 1))
		if n == 1 or n == 11 or n == 26:
			await _buka_app("email")
			var email := await _tunggu_node("EmailApp", 3.0)
			if email != null:
				await _klik_baris_salah_satu(email, ["Tahap %d:" % n, "Stage %d:" % n])
				await _secs(0.4)
				await _klik(email, Bahasa.t("email.baca"))
				await _secs(0.4)
				_log("  TEKS EMAIL MISI tahap %d: %s" % [n, _teks_node(email).replace("\n", " | ")])
				await _shot("email_misi_tahap_%d" % n)
				await _klik(email, Bahasa.t("misi.tombol_belajar"))
				await _shot("belajar_tahap_%d" % n)
				await _klik(email, Bahasa.t("misi.tombol_kembali"))
				await _klik(email, Bahasa.t("email.keluar"))
		# Pemain mengetuk ikon Terminal agar jendelanya di depan sebelum mengetik.
		await _buka_app("terminal")
		var term := _cari_berkas(root_app, "terminal_screen.gd")
		if term == null:
			_bug("terminal tidak bisa dibuka di tahap %d" % n)
			return
		if n == 11:
			await _ketik(term, PERINTAH[n][0])
			await _ketik(term, PERINTAH[n][1])
			await _secs(2.2)
			await _shot("airodump_live")
			_log("  live aktif: %s" % str(term.get("_live")))
			await _ketik(term, "help")
			await _ctrl_c(term)
			await _secs(1.0)
			_log("  setelah Ctrl+C: live=%s, busy=%s" % [str(term.get("_live")), str(term.get("_busy"))])
			await _shot("airodump_setelah_ctrl_c")
			continue
		for c in PERINTAH[n]:
			c = String(c).replace("KUNCI_UJI", SesiUtama.ambil().wifi.kata_sandi("LAB-WIFI-01"))
			if c == "__netmgr__":
				await _buka_app("netmgr")
				await _shot("netmgr_tahap12")
				continue
			# Aksi aplikasi: Beli lewat aplikasi Toko, Rakit dan Hubungkan lewat Device Manager.
			if c.begins_with("__beli__"):
				await _buka_app("toko")
				var toko := _cari_berkas(root_app, "toko_screen.gd")
				toko.call("_beli", c.substr("__beli__".length()))
				await _frames(5)
				continue
			if c == "__rakit__" or c == "__hubungkan__":
				await _buka_app("perangkat")
				var dm := _cari_berkas(root_app, "device_manager.gd")
				var kunci := "perangkat.rakit" if c == "__rakit__" else "perangkat.hubungkan"
				await _klik_baris(dm, Bahasa.t(kunci))
				await _frames(5)
				continue
			await _ketik(term, c)
			await _secs(0.2)
		if n == 13:
			await _shot("terminal_tahap13")
		Misi.perbarui(s)
		var cek := Misi.tahap_aktif(s, m)
		if cek != n + 1 and not (n == 26 and cek == 0):
			_bug("setelah tahap %d, tahap aktif = %d (diharapkan %d)" % [n, cek, n + 1])
		await _secs(0.3)
	_snap("akhir misi")
	var akhir_s = _sesi()
	_log("Akhir: misi=%s, tahap aktif=%d, hadiah=%s" % [str(akhir_s.misi.get("misi_1","")), Misi.tahap_aktif(akhir_s, m), str(akhir_s.hadiah_diambil.has("misi_1"))])

func _email_tahap(s, n: int) -> int:
	var k := 0
	for p in s.pesan_misi:
		if int(p.get("tahap", 0)) == n:
			k += 1
	return k
