class_name MenuUtama
extends Control

# Menu utama: layar pertama setelah splash. Lima tombol: Sesi Baru, Lanjutkan, Login, Pengaturan, Keluar.
# Semua tampilan dibuat dari kode dan dihitung dari ukuran layar, jadi menyesuaikan HP portrait.
# Sinyal mulai(mode) memberi tahu MainController: "baru" atau "lanjut".

signal mulai(mode: String)
signal keluar_diminta

static func nama_game() -> String:
	return Bahasa.t("menu.nama_game")
const WARNA_LATAR := Color("#070b0e")
const WARNA_HEX := Color(0.18, 0.85, 0.75, 0.07)
const WARNA_TEAL := Color("#2dd4bf")
const WARNA_TEKS_REDUP := Color("#8fa8a4")
const WARNA_BATAS := Color(0.45, 0.6, 0.58)
const WARNA_PANEL := Color(0.05, 0.08, 0.1, 0.96)
const WARNA_OFFLINE := Color("#ff7b72")
const TINGGI_TOMBOL := 96.0
const JARAK_HEX := 46.0
const WARNA_TOMBOL_KUNCI := Color(0.5, 0.56, 0.55, 0.45)

var _aman := Vector4.ZERO
var _margin: MarginContainer
var _kolom: VBoxContainer
var _tombol: Dictionary = {}
var _lbl_status: Label
var _lbl_status_bawah: Label
var _kursor: Label
var _timer_kursor: Timer
var _lingkaran: Control
var _panel_pengaturan: PanelContainer
var _panel_login: PanelContainer
var _input_nama: LineEdit
var _lbl_error_login: Label
var _tombol_ukuran: Dictionary = {}
var _tombol_bahasa: Dictionary = {}
var _lbl_hint_bahasa: Label
var _lbl_hint_pengaturan: Label
var _kotak_hint_bahasa: PanelContainer
var _lbl_contoh: Label
var _dialog_sesi: KonfirmasiPanel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bangun_kolom()
	_bangun_panel_pengaturan()
	_bangun_panel_login()
	_dialog_sesi = KonfirmasiPanel.new()
	_dialog_sesi.diterima.connect(_jalankan_sesi_baru)
	_dialog_sesi.dibatalkan.connect(_dialog_sesi.sembunyikan)
	add_child(_dialog_sesi)
	_timer_kursor = Timer.new()
	_timer_kursor.wait_time = 0.5
	_timer_kursor.timeout.connect(_kedip_kursor)
	add_child(_timer_kursor)
	_timer_kursor.start()
	resized.connect(_susun)
	_susun()
	_segarkan()

func atur_aman(nilai: Vector4) -> void:
	_aman = nilai
	_susun()

func _bangun_kolom() -> void:
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(_margin, 36)
	add_child(_margin)
	_kolom = VBoxContainer.new()
	_kolom.add_theme_constant_override("separation", 18)
	_margin.add_child(_kolom)

	var atas := HBoxContainer.new()
	atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kolom.add_child(atas)
	var kiri := Tema.label("> JTN  v%s" % _versi(), Tema.TEKS, 20)
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(kiri)
	_lbl_status = Tema.label(Bahasa.t("menu.offline"), WARNA_OFFLINE, 20)
	atas.add_child(_lbl_status)

	var judul := Tema.label("> JTN_", WARNA_TEAL, 84)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kolom.add_child(judul)
	_kursor = judul
	var sub := Tema.label(nama_game(), Tema.TEKS, 26)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kolom.add_child(sub)

	_lingkaran = Control.new()
	_lingkaran.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lingkaran.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lingkaran.draw.connect(_gambar_lingkaran.bind(_lingkaran))
	_kolom.add_child(_lingkaran)

	var daftar := VBoxContainer.new()
	daftar.add_theme_constant_override("separation", 16)
	_kolom.add_child(daftar)
	_tambah_tombol(daftar, "sesi_baru", Bahasa.t("menu.sesi_baru"), _aksi_sesi_baru)
	_tambah_tombol(daftar, "lanjutkan", Bahasa.t("menu.lanjutkan"), _aksi_lanjutkan)
	_tambah_tombol(daftar, "login", Bahasa.t("menu.login"), _aksi_login)
	_tambah_tombol(daftar, "pengaturan", Bahasa.t("menu.pengaturan"), _aksi_pengaturan)
	_tambah_tombol(daftar, "keluar", Bahasa.t("menu.keluar"), func(): keluar_diminta.emit())

	var status := PanelContainer.new()
	status.add_theme_stylebox_override("panel", Tema.kotak(WARNA_PANEL, WARNA_BATAS, 1, 10))
	_kolom.add_child(status)
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 14)
	status.add_child(m)
	_lbl_status_bawah = Tema.label("", Tema.TEKS, 22)
	m.add_child(_lbl_status_bawah)

func _tambah_tombol(induk: Control, kunci: String, teks: String, aksi: Callable) -> void:
	var b := Button.new()
	b.text = teks
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, TINGGI_TOMBOL)
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Tema.TEKS)
	b.add_theme_color_override("font_disabled_color", WARNA_TOMBOL_KUNCI)
	b.add_theme_stylebox_override("normal", _gaya_tombol(false))
	b.add_theme_stylebox_override("hover", _gaya_tombol(true))
	b.add_theme_stylebox_override("pressed", _gaya_tombol(true))
	b.add_theme_stylebox_override("disabled", _gaya_tombol(false))
	b.pressed.connect(aksi)
	induk.add_child(b)
	# Garis aksen di tepi kiri tombol, seperti pada referensi desain.
	var aksen := ColorRect.new()
	aksen.color = WARNA_TEAL
	aksen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aksen.anchor_left = 0.0
	aksen.anchor_top = 0.0
	aksen.anchor_right = 0.0
	aksen.anchor_bottom = 1.0
	aksen.offset_right = 6.0
	b.add_child(aksen)
	_tombol[kunci] = b

func _gaya_tombol(aktif: bool) -> StyleBoxFlat:
	var s := Tema.kotak(Color(0.06, 0.1, 0.12) if not aktif else Color(0.06, 0.16, 0.17), WARNA_TEAL if aktif else WARNA_BATAS, 2 if aktif else 1, 8)
	s.content_margin_left = 40.0
	return s

func _bangun_panel_pengaturan() -> void:
	_panel_pengaturan = _bangun_panel(Bahasa.t("pengaturan.judul"))
	var kolom: VBoxContainer = _kolom_panel(_panel_pengaturan)
	kolom.add_theme_constant_override("separation", 18)

	# Teks Terminal: pilihan ukuran dan contoh hasilnya.
	kolom.add_child(_judul_seksi(Bahasa.t("pengaturan.teks_terminal")))
	var ukuran := []
	for kunci in ["kecil", "sedang", "besar"]:
		ukuran.append({"kunci": kunci, "teks": Bahasa.t("pengaturan.ukuran_" + kunci)})
	kolom.add_child(_segmen(ukuran, _pilih_ukuran, _tombol_ukuran))
	_lbl_contoh = Tema.label(Bahasa.t("pengaturan.contoh"), Tema.TEKS, 26)
	_lbl_contoh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(_kotak_info(_lbl_contoh))
	_lbl_hint_pengaturan = Tema.label(Bahasa.t("pengaturan.berlaku_terminal"), Tema.TEKS_REDUP, 20)
	_lbl_hint_pengaturan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(_lbl_hint_pengaturan)

	# Bahasa antarmuka. Kode bahasa ditampilkan agar mudah dikenali.
	kolom.add_child(_judul_seksi(Bahasa.t("pengaturan.bahasa")))
	var bahasa := []
	for kode in Bahasa.KODE:
		bahasa.append({"kunci": kode, "teks": Bahasa.NAMA[kode], "ikon": Bahasa.BENDERA[kode]})
	kolom.add_child(_segmen(bahasa, _pilih_bahasa, _tombol_bahasa, 22))
	_lbl_hint_bahasa = Tema.label("", Tema.TEKS_REDUP, 20)
	_lbl_hint_bahasa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kotak_hint_bahasa = _kotak_info(_lbl_hint_bahasa)
	_kotak_hint_bahasa.visible = false
	kolom.add_child(_kotak_hint_bahasa)

	var kembali := _tombol_biasa(Bahasa.t("umum.kembali"))
	kembali.pressed.connect(_tutup_panel)
	kolom.add_child(kembali)

func _judul_seksi(teks: String) -> Label:
	return Tema.label(teks.to_upper(), Tema.TEAL, 20)

# Kotak info bergaya Desktop: latar gelap dengan batas tipis, dipakai untuk contoh dan keterangan.
func _kotak_info(isi: Control) -> PanelContainer:
	var k := PanelContainer.new()
	k.add_theme_stylebox_override("panel", Tema.kotak(Color(0.03, 0.05, 0.06), WARNA_BATAS, 1, 10))
	k.add_child(isi)
	return k

# Pilihan segmen: satu tombol aktif berwarna teal, sisanya gelap.
func _segmen(pilihan: Array, aksi: Callable, simpan: Dictionary, ukuran_huruf := 24) -> HBoxContainer:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	for p in pilihan:
		var b := Button.new()
		b.text = String(p["teks"])
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", ukuran_huruf)
		if p.has("ikon"):
			b.icon = load(String(p["ikon"])) as Texture2D
			b.expand_icon = true
			b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(aksi.bind(p["kunci"]))
		baris.add_child(b)
		simpan[p["kunci"]] = b
	return baris

func _tandai_segmen(simpan: Dictionary, aktif: String) -> void:
	for kunci in simpan:
		var b: Button = simpan[kunci]
		var on: bool = String(kunci) == aktif
		b.add_theme_stylebox_override("normal", _gaya_segmen(on))
		b.add_theme_stylebox_override("hover", _gaya_segmen(true))
		b.add_theme_stylebox_override("pressed", _gaya_segmen(true))
		b.add_theme_color_override("font_color", Tema.TEKS if on else Tema.TEKS_REDUP)

func _gaya_segmen(aktif: bool) -> StyleBoxFlat:
	return Tema.kotak(Color(0.06, 0.2, 0.2) if aktif else Color(0.06, 0.1, 0.12), WARNA_TEAL if aktif else WARNA_BATAS, 2 if aktif else 1, 10)

func _bangun_panel_login() -> void:
	_panel_login = _bangun_panel(Bahasa.t("login.judul"))
	var kolom: VBoxContainer = _kolom_panel(_panel_login)
	kolom.add_child(Tema.label(Bahasa.t("login.petunjuk"), Tema.TEKS, 24))
	_input_nama = LineEdit.new()
	_input_nama.custom_minimum_size = Vector2(0, 80)
	_input_nama.max_length = Pengaturan.NAMA_MAKS
	_input_nama.placeholder_text = Bahasa.t("login.contoh")
	_input_nama.add_theme_font_size_override("font_size", 28)
	kolom.add_child(_input_nama)
	_lbl_error_login = Tema.label("", Tema.AMBER, 20)
	_lbl_error_login.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(_lbl_error_login)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kolom.add_child(baris)
	var batal := _tombol_biasa(Bahasa.t("umum.batal"))
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.pressed.connect(_tutup_panel)
	baris.add_child(batal)
	var simpan := _tombol_biasa(Bahasa.t("umum.simpan"))
	simpan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simpan.pressed.connect(_simpan_login)
	baris.add_child(simpan)

# Panel overlay: menutupi layar dengan latar gelap, kartu di tengah. Isinya diambil lewat _kolom_panel.
func _bangun_panel(judul: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", Tema.kotak(WARNA_LATAR, WARNA_LATAR, 0, 0))
	p.visible = false
	add_child(p)
	var luar := MarginContainer.new()
	Tema.margin_seragam(luar, 48)
	luar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(luar)
	var tumpuk := VBoxContainer.new()
	luar.add_child(tumpuk)
	var atas := Control.new()
	atas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tumpuk.add_child(atas)
	var kartu := PanelContainer.new()
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartu.add_theme_stylebox_override("panel", Tema.kotak(WARNA_PANEL, Tema.TEAL, 2, 14))
	tumpuk.add_child(kartu)
	var bawah := Control.new()
	bawah.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tumpuk.add_child(bawah)
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 24)
	kartu.add_child(m)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 16)
	m.add_child(kolom)
	kolom.add_child(Tema.label("> " + judul, Tema.TEAL, 34))
	p.set_meta("kolom", kolom)
	return p

func _kolom_panel(p: PanelContainer) -> VBoxContainer:
	return p.get_meta("kolom") as VBoxContainer

func _tombol_biasa(teks: String) -> Button:
	var b := Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(0, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", _gaya_tombol(false))
	b.add_theme_stylebox_override("hover", _gaya_tombol(true))
	b.add_theme_stylebox_override("pressed", _gaya_tombol(true))
	return b

# Tombol Lanjutkan hanya aktif bila ada simpanan. Login menampilkan nama profil bila sudah diatur.
func _segarkan() -> void:
	(_tombol["lanjutkan"] as Button).disabled = not Penyimpanan.ada_simpanan()
	var nama := Pengaturan.nama_profil()
	(_tombol["login"] as Button).text = "> Login  ·  " + nama if nama != "" else Bahasa.t("menu.login")
	_tandai_segmen(_tombol_ukuran, Pengaturan.ukuran_teks())
	_tandai_segmen(_tombol_bahasa, Bahasa.kode)
	if is_instance_valid(_lbl_contoh):
		_lbl_contoh.add_theme_font_size_override("font_size", Pengaturan.ukuran_font())
	if (_tombol["lanjutkan"] as Button).disabled:
		_set_status(Bahasa.t("menu.status_belum_simpanan"))
	else:
		_set_status(Bahasa.t("menu.status_siap"))

func _set_status(teks: String) -> void:
	_lbl_status_bawah.text = "> " + teks

func _aksi_sesi_baru() -> void:
	if Penyimpanan.ada_simpanan():
		_dialog_sesi.atur_aman(_aman)
		_dialog_sesi.tampil(Bahasa.t("dialog.sesi_baru_judul"), Bahasa.t("dialog.sesi_baru_isi"), Bahasa.t("dialog.mulai_baru"), Bahasa.t("umum.batal"))
	else:
		_jalankan_sesi_baru()

func _jalankan_sesi_baru() -> void:
	Penyimpanan.arsipkan()
	SesiUtama.reset()
	TerminalScreen.reset_sesi()
	mulai.emit("baru")

func _aksi_lanjutkan() -> void:
	if not Penyimpanan.ada_simpanan():
		_segarkan()
		return
	mulai.emit("lanjut")

func _aksi_login() -> void:
	_input_nama.text = Pengaturan.nama_profil()
	_lbl_error_login.text = ""
	_tampil_panel(_panel_login)
	_input_nama.grab_focus()

func _aksi_pengaturan() -> void:
	_tampil_panel(_panel_pengaturan)

func _pilih_bahasa(kode: String) -> void:
	if Pengaturan.set_bahasa(kode):
		_lbl_hint_bahasa.text = Bahasa.t("pengaturan.bahasa_diganti")
		_kotak_hint_bahasa.visible = true
		_segarkan()

func _pilih_ukuran(kunci: String) -> void:
	if Pengaturan.set_ukuran_teks(kunci):
		_segarkan()
		_set_status(Bahasa.t("pengaturan.ukuran_disimpan") % kunci)

func _simpan_login() -> void:
	var nama := _input_nama.text.strip_edges()
	if not Pengaturan.nama_valid(nama):
		_lbl_error_login.text = Bahasa.t("login.nama_salah")
		return
	if not Pengaturan.set_nama_profil(nama):
		_lbl_error_login.text = Bahasa.t("login.gagal")
		return
	_tutup_panel()
	_segarkan()
	_set_status(Bahasa.t("login.berhasil") % nama)

func _tampil_panel(p: PanelContainer) -> void:
	_tutup_panel()
	_margin.visible = false
	p.visible = true

func _tutup_panel() -> void:
	_panel_login.visible = false
	_panel_pengaturan.visible = false
	_margin.visible = true

func _kedip_kursor() -> void:
	# Kursor berkedip di judul, seperti pada tampilan terminal.
	if _kursor != null:
		_kursor.modulate.a = 0.35 if _kursor.modulate.a > 0.5 else 1.0

func _susun() -> void:
	if _margin == null:
		return
	_margin.add_theme_constant_override("margin_top", int(_aman.y) + 36)
	_margin.add_theme_constant_override("margin_bottom", int(_aman.w) + 36)
	_margin.add_theme_constant_override("margin_left", int(_aman.x) + 36)
	_margin.add_theme_constant_override("margin_right", int(_aman.z) + 36)
	queue_redraw()
	if _lingkaran != null:
		_lingkaran.queue_redraw()

func _versi() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "1.0.0"))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), WARNA_LATAR)
	# Pola hexagonal tipis sebagai latar, dihitung ulang hanya saat ukuran berubah.
	var r := JARAK_HEX
	var lebar := r * sqrt(3.0)
	var baris := 0
	var y := -r
	while y < size.y + r:
		var geser := lebar * 0.5 if baris % 2 == 1 else 0.0
		var x := -lebar + geser
		while x < size.x + lebar:
			_gambar_hex(Vector2(x, y), r)
			x += lebar
		y += r * 1.5
		baris += 1

func _gambar_hex(pusat: Vector2, r: float) -> void:
	var titik := PackedVector2Array()
	for i in range(7):
		var sudut := PI / 6.0 + TAU * float(i) / 6.0
		titik.append(pusat + Vector2(cos(sudut), sin(sudut)) * r)
	draw_polyline(titik, WARNA_HEX, 1.0, true)

# Lingkaran jaringan di tengah: cincin, busur terang, dan node yang terhubung.
func _gambar_lingkaran(c: Control) -> void:
	var pusat := c.size * 0.5
	var r := minf(c.size.x, c.size.y) * 0.42
	if r <= 0.0:
		return
	for k in [1.0, 0.78, 0.56, 0.34]:
		c.draw_arc(pusat, r * k, 0.0, TAU, 96, Color(WARNA_TEAL, 0.18 + 0.05 * (1.0 - k)), 1.5, true)
	for busur in [[-1.9, -0.6], [0.3, 1.5], [2.2, 2.9], [3.5, 4.4], [4.9, 5.6]]:
		c.draw_arc(pusat, r * 0.96, busur[0], busur[1], 32, WARNA_TEAL, 6.0, true)
	c.draw_arc(pusat, r * 0.56, 0.9, 2.0, 24, WARNA_TEAL, 5.0, true)
	c.draw_arc(pusat, r * 0.34, 3.9, 4.8, 24, WARNA_TEAL, 5.0, true)
	var node: Array[Vector2] = [Vector2(0.9, -0.2), Vector2(-0.8, 0.5), Vector2(0.4, 0.8), Vector2(-0.3, -0.9), Vector2(1.05, 0.7)]
	for i in range(node.size()):
		var p: Vector2 = pusat + node[i] * r
		c.draw_line(pusat, p, Color(WARNA_TEAL, 0.35), 1.5, true)
		c.draw_circle(p, 5.0 if i != 0 else 9.0, WARNA_TEAL)
	c.draw_circle(pusat, 6.0, Color(WARNA_TEAL, 0.8))
