class_name EmailApp
extends Control

# Aplikasi E-Mail: kotak masuk, sampah, dan pembaca pesan. Semua teks memakai kunci Bahasa
# sehingga ikut berganti saat bahasa diganti. Status pesan disimpan di sesi lewat Email.

const LATAR := Color("#080c10")
const LATAR_KARTU := Color(0.04, 0.07, 0.09, 1.0)
const LATAR_BELUM := Color(0.05, 0.16, 0.17, 1.0)
const TEKS_ISI := Color("#d6ebe7")
const IKON := "res://assets/ikon/aplikasi/app_email.png"

var _sesi: ShellSession
var _tab := "masuk"
var _pilih := ""
var _pembaca := false
var _tab_masuk: Button
var _tab_sampah: Button
var _lbl_jumlah: Label
var _kolom_baris: VBoxContainer
var _gulir_daftar: ScrollContainer
var _area_pembaca: VBoxContainer
var _bawah: HBoxContainer

func _ready() -> void:
	_sesi = SesiUtama.ambil()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var latar := ColorRect.new()
	latar.color = LATAR
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(m, 24)
	add_child(m)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 16)
	m.add_child(kolom)

	# Header: ikon, judul, dan jumlah pesan belum dibaca.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	kolom.add_child(header)
	var ikon := TextureRect.new()
	ikon.texture = load(IKON) as Texture2D
	ikon.custom_minimum_size = Vector2(64, 64)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(ikon)
	var judul_kolom := VBoxContainer.new()
	judul_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	judul_kolom.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(judul_kolom)
	var judul := Tema.label("", Tema.TEAL, 34)
	judul_kolom.add_child(judul)
	Bahasa.isi(judul, "email.judul")
	_lbl_jumlah = Tema.label("", Tema.TEKS_REDUP, 22)
	judul_kolom.add_child(_lbl_jumlah)
	Bahasa.daftar_penyegar(_lbl_jumlah, _tulis_jumlah)

	# Tab: Masuk dan Sampah dengan garis bawah pada tab aktif.
	var tab := HBoxContainer.new()
	tab.add_theme_constant_override("separation", 0)
	kolom.add_child(tab)
	_tab_masuk = _tombol_tab("email.tab_masuk")
	_tab_masuk.pressed.connect(_ganti_tab.bind("masuk"))
	tab.add_child(_tab_masuk)
	_tab_sampah = _tombol_tab("email.tab_sampah")
	_tab_sampah.pressed.connect(_ganti_tab.bind("sampah"))
	tab.add_child(_tab_sampah)

	# Area daftar dan area pembaca bergantian. Pembaca punya gulir sendiri agar isi pesan tidak terpotong.
	_gulir_daftar = ScrollContainer.new()
	_gulir_daftar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gulir_daftar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(_gulir_daftar)
	_kolom_baris = VBoxContainer.new()
	_kolom_baris.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom_baris.add_theme_constant_override("separation", 14)
	_gulir_daftar.add_child(_kolom_baris)

	_area_pembaca = VBoxContainer.new()
	_area_pembaca.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area_pembaca.add_theme_constant_override("separation", 14)
	_area_pembaca.visible = false
	kolom.add_child(_area_pembaca)

	_bawah = HBoxContainer.new()
	_bawah.add_theme_constant_override("separation", 12)
	kolom.add_child(_bawah)

	_segarkan()

# Menyusun ulang daftar atau pembaca sesuai keadaan. Dipanggil setiap ada perubahan.
func _segarkan() -> void:
	_gaya_tab(_tab_masuk, _tab == "masuk")
	_gaya_tab(_tab_sampah, _tab == "sampah")
	_tulis_jumlah()
	for c in _kolom_baris.get_children():
		c.queue_free()
	for c in _area_pembaca.get_children():
		c.queue_free()
	for c in _bawah.get_children():
		c.queue_free()
	_gulir_daftar.visible = not _pembaca
	_area_pembaca.visible = _pembaca
	if _pembaca:
		_bangun_pembaca()
	else:
		_bangun_daftar()

# Jumlah pesan belum dibaca. Dihitung ulang juga saat bahasa berganti.
func _tulis_jumlah() -> void:
	var belum := Email.jumlah_belum_dibaca(_sesi)
	_lbl_jumlah.text = Bahasa.t("email.belum_dibaca") % belum if belum > 0 else ""

func _ganti_tab(tab: String) -> void:
	_tab = tab
	_pilih = ""
	_pembaca = false
	_segarkan()

func _bangun_daftar() -> void:
	var daftar := Email.daftar(_sesi, _tab)
	if daftar.is_empty():
		var kosong := Tema.label("", Tema.TEKS_REDUP, 26)
		kosong.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kosong.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kosong.custom_minimum_size = Vector2(0, 240)
		kosong.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_kolom_baris.add_child(kosong)
		Bahasa.isi(kosong, "email.kosong" if _tab == "masuk" else "email.sampah_kosong")
	for p in daftar:
		_kolom_baris.add_child(_baris(p))
	var baca := _tombol_aksi("email.baca", Tema.TEAL)
	baca.pressed.connect(_aksi_baca)
	_bawah.add_child(baca)
	var hapus := _tombol_aksi("email.hapus_permanen" if _tab == "sampah" else "email.hapus", Tema.TEKS_REDUP)
	hapus.pressed.connect(_aksi_hapus_daftar)
	_bawah.add_child(hapus)

# Satu baris pesan: titik kuning untuk pesan belum dibaca, pengirim kecil, lalu judul.
func _baris(p: Dictionary) -> Control:
	var id := String(p["id"])
	var terpilih := _pilih == id
	var belum := _tab == "masuk" and not Email.sudah_dibaca(_sesi, id)
	var tombol := Button.new()
	tombol.focus_mode = Control.FOCUS_NONE
	# Sentuhan geser diteruskan ke daftar agar bisa scroll ke atas dan bawah; ketuk tetap memilih pesan.
	tombol.mouse_filter = Control.MOUSE_FILTER_PASS
	tombol.custom_minimum_size = Vector2(0, 150)
	tombol.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var warna := LATAR_BELUM if belum else LATAR_KARTU
	var batas := Tema.AMBER if terpilih else (Tema.TEAL if belum else Color(0.2, 0.3, 0.3))
	tombol.add_theme_stylebox_override("normal", Tema.kotak(warna, batas, 2 if terpilih or belum else 1, 14))
	tombol.add_theme_stylebox_override("hover", Tema.kotak(warna, Tema.AMBER, 2, 14))
	tombol.add_theme_stylebox_override("pressed", Tema.kotak(warna, Tema.AMBER, 2, 14))
	tombol.add_theme_stylebox_override("focus", Tema.kotak(warna, Tema.AMBER, 2, 14))

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	tombol.add_child(pad)
	var baris := HBoxContainer.new()
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_theme_constant_override("separation", 18)
	pad.add_child(baris)

	var titik := Tema.label("●" if belum else " ", Tema.AMBER, 28)
	titik.custom_minimum_size = Vector2(22, 0)
	baris.add_child(titik)

	var isi := VBoxContainer.new()
	isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.add_theme_constant_override("separation", 8)
	baris.add_child(isi)
	var pengirim := Tema.label("", Tema.TEAL if belum else Tema.TEKS_REDUP, 22)
	isi.add_child(pengirim)
	_pasang_pengirim(pengirim, p)
	var judul := Tema.label("", Tema.TEKS, 26)
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.add_child(judul)
	_teks_pesan(judul, p, "judul")

	tombol.pressed.connect(_pilih_pesan.bind(id))
	return tombol

# Baris pengirim dihitung ulang setiap bahasa berganti: label bahasa + nama pengirim dari kunci.
func _pasang_pengirim(label: Label, p: Dictionary) -> void:
	Bahasa.daftar_penyegar(label, func():
		if is_instance_valid(label):
			label.text = "%s : %s" % [Bahasa.t("email.dari"), Bahasa.t(String(p["dari"]))])

# Pesan bawaan memakai kunci bahasa; pesan misi sudah dua-bahasa dan disusun ulang saat bahasa berganti.
func _teks_pesan(label: Label, p: Dictionary, kunci: String) -> void:
	if bool(p.get("mentah", false)):
		Bahasa.daftar_penyegar(label, func():
			if is_instance_valid(label):
				label.text = Bahasa.pilih(String(p[kunci])))
	else:
		Bahasa.isi(label, String(p[kunci]))

func _pilih_pesan(id: String) -> void:
	_pilih = id
	_segarkan()

func _aksi_baca() -> void:
	if _pilih == "":
		_hint("email.pilih")
		return
	Email.tandai_dibaca(_sesi, _pilih)
	_pembaca = true
	_segarkan()

func _aksi_hapus_daftar() -> void:
	if _pilih == "":
		_hint("email.pilih")
		return
	if _tab == "masuk":
		Email.pindah_ke_sampah(_sesi, _pilih)
	else:
		Email.hapus_permanen(_sesi, _pilih)
	_pilih = ""
	_simpan()
	_segarkan()

# Pembaca: kartu header dengan pengirim dan judul, isi pesan dalam area gulir, lalu tombol aksi.
func _bangun_pembaca() -> void:
	var p := Email.cari(_pilih, _sesi)
	if p.is_empty():
		_pembaca = false
		_segarkan()
		return
	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(LATAR_KARTU, Tema.TEAL, 2, 16))
	_area_pembaca.add_child(kartu)
	var pad := MarginContainer.new()
	Tema.margin_seragam(pad, 22)
	kartu.add_child(pad)
	var kepala := VBoxContainer.new()
	kepala.add_theme_constant_override("separation", 10)
	pad.add_child(kepala)
	var pengirim := Tema.label("", Tema.TEAL, 24)
	pengirim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kepala.add_child(pengirim)
	_pasang_pengirim(pengirim, p)
	var judul := Tema.label("", Tema.TEKS, 30)
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kepala.add_child(judul)
	_teks_pesan(judul, p, "judul")

	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_area_pembaca.add_child(gulir)
	var isi_pad := MarginContainer.new()
	isi_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi_pad.add_theme_constant_override("margin_left", 6)
	isi_pad.add_theme_constant_override("margin_right", 14)
	gulir.add_child(isi_pad)
	var isi := Tema.label("", TEKS_ISI, 26)
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.add_theme_constant_override("line_spacing", 10)
	isi_pad.add_child(isi)
	_teks_pesan(isi, p, "isi")

	var keluar := _tombol_aksi("email.keluar", Tema.TEKS_REDUP)
	keluar.pressed.connect(func():
		_pembaca = false
		_segarkan())
	_bawah.add_child(keluar)
	if _tab == "sampah":
		var pulih := _tombol_aksi("email.pulihkan", Tema.TEAL)
		pulih.pressed.connect(func():
			Email.pulihkan(_sesi, _pilih)
			_pembaca = false
			_pilih = ""
			_simpan()
			_segarkan())
		_bawah.add_child(pulih)
		var permanen := _tombol_aksi("email.hapus_permanen", Tema.AMBER)
		permanen.pressed.connect(func():
			Email.hapus_permanen(_sesi, _pilih)
			_pembaca = false
			_pilih = ""
			_simpan()
			_segarkan())
		_bawah.add_child(permanen)
	else:
		var hapus := _tombol_aksi("email.hapus", Tema.AMBER)
		hapus.pressed.connect(func():
			Email.pindah_ke_sampah(_sesi, _pilih)
			_pembaca = false
			_pilih = ""
			_simpan()
			_segarkan())
		_bawah.add_child(hapus)

func _hint(kunci: String) -> void:
	var l := Tema.label("", Tema.AMBER, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kolom_baris.add_child(l)
	Bahasa.isi(l, kunci)

func _simpan() -> void:
	Penyimpanan.simpan_sesi(_sesi)

func _tombol_tab(kunci: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 76)
	b.add_theme_font_size_override("font_size", 28)
	Bahasa.isi(b, kunci)
	return b

func _gaya_tab(b: Button, aktif: bool) -> void:
	b.add_theme_color_override("font_color", Tema.TEAL if aktif else Tema.TEKS_REDUP)
	b.add_theme_color_override("font_hover_color", Tema.TEAL)
	var garis := StyleBoxFlat.new()
	garis.bg_color = Color(0, 0, 0, 0)
	garis.border_color = Tema.TEAL if aktif else Color(0.15, 0.25, 0.25)
	garis.border_width_bottom = 4 if aktif else 2
	b.add_theme_stylebox_override("normal", garis)
	b.add_theme_stylebox_override("hover", garis)
	b.add_theme_stylebox_override("pressed", garis)

func _tombol_aksi(kunci: String, warna_batas: Color) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", Tema.TEKS)
	b.add_theme_stylebox_override("normal", Tema.kotak(Color(0.05, 0.1, 0.12), warna_batas, 2, 16))
	b.add_theme_stylebox_override("hover", Tema.kotak(Color(0.08, 0.18, 0.2), warna_batas, 2, 16))
	b.add_theme_stylebox_override("pressed", Tema.kotak(Color(0.08, 0.18, 0.2), warna_batas, 2, 16))
	Bahasa.isi(b, kunci)
	return b
