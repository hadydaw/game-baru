class_name PilihLokasi
extends Control

# Layar pemilihan lokasi awal pemain: ketuk negara di peta, pilih kota, lalu tekan Mulai.
# Titik negara dan daftar kota dibaca dari data/lokasi/negara.json lewat Lokasi.

signal selesai(kode_negara: String, kode_kota: String)
signal kembali

const RASIO_PETA := 887.0 / 1774.0
const UKURAN_TITIK := 56.0

var _aman := Vector4.ZERO
var _negara := ""
var _kota := ""
var _peta_wrap: Control
var _titik_negara: Dictionary = {}   # kode negara -> Button
var _lbl_status: Label
var _lbl_hint: Label
var _daftar_kota: VBoxContainer
var _gulir: ScrollContainer
var _tombol_mulai: Button
var _tombol_kota: Dictionary = {}    # kode kota -> Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var latar := TextureRect.new()
	latar.texture = load("res://assets/wallpaper/wp_potret.png") as Texture2D
	latar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	latar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var redup := ColorRect.new()
	redup.color = Color(0.02, 0.03, 0.04, 0.85)
	redup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(redup)
	_bangun()
	_segarkan()

func atur_aman(nilai: Vector4) -> void:
	_aman = nilai
	var m := get_node_or_null("Margin") as MarginContainer
	if m:
		m.add_theme_constant_override("margin_left", int(_aman.x) + 28)
		m.add_theme_constant_override("margin_top", int(_aman.y) + 24)
		m.add_theme_constant_override("margin_right", int(_aman.z) + 28)
		m.add_theme_constant_override("margin_bottom", int(_aman.w) + 24)

func _bangun() -> void:
	var m := MarginContainer.new()
	m.name = "Margin"
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_bottom", 24)
	add_child(m)

	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 16)
	m.add_child(kolom)

	var judul := Tema.label(Bahasa.t("intro.judul"), Tema.TEAL, 28)
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(judul)

	# Peta: lebar penuh, tinggi mengikuti rasio aset. Titik negara diletakkan dengan koordinat relatif.
	_peta_wrap = Control.new()
	_peta_wrap.custom_minimum_size = Vector2(0, 300)
	_peta_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_child(_peta_wrap)
	var gambar := TextureRect.new()
	gambar.texture = load("res://assets/peta/peta_dunia.png") as Texture2D
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_SCALE
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gambar.name = "Gambar"
	_peta_wrap.add_child(gambar)
	gambar.anchor_right = 1.0
	gambar.anchor_bottom = 0.0
	for n in Lokasi.semua_negara():
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.text = "●"
		b.add_theme_font_size_override("font_size", 36)
		b.custom_minimum_size = Vector2(UKURAN_TITIK, UKURAN_TITIK)
		b.size = Vector2(UKURAN_TITIK, UKURAN_TITIK)
		b.tooltip_text = Lokasi.nama_negara(String(n["kode"]))
		var kode := String(n["kode"])
		b.pressed.connect(_pilih_negara.bind(kode))
		_peta_wrap.add_child(b)
		_titik_negara[kode] = b
	_peta_wrap.resized.connect(_susun_peta)

	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 18))
	kolom.add_child(kartu)
	var isi_kartu := VBoxContainer.new()
	isi_kartu.add_theme_constant_override("separation", 6)
	kartu.add_child(isi_kartu)
	_lbl_status = Tema.label("", Tema.TEKS, 26)
	_lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi_kartu.add_child(_lbl_status)
	_lbl_hint = Tema.label("", Tema.TEKS_REDUP, 22)
	_lbl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi_kartu.add_child(_lbl_hint)

	_gulir = ScrollContainer.new()
	_gulir.custom_minimum_size = Vector2(0, 240)
	_gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(_gulir)
	_daftar_kota = VBoxContainer.new()
	_daftar_kota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar_kota.add_theme_constant_override("separation", 10)
	_gulir.add_child(_daftar_kota)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	kolom.add_child(baris)
	var kembali_btn := _tombol("intro.kembali_pilih", Tema.TEKS_REDUP, Tema.kotak(Color(0.06, 0.09, 0.11), Tema.TEKS_REDUP, 2, 18))
	kembali_btn.pressed.connect(func(): kembali.emit())
	kembali_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(kembali_btn)
	_tombol_mulai = _tombol("intro.mulai", Color("#06201c"), Tema.kotak(Tema.TEAL, Tema.TEAL, 0, 18))
	_tombol_mulai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_mulai.pressed.connect(_mulai)
	baris.add_child(_tombol_mulai)

func _tombol(kunci: String, warna: Color, gaya: StyleBoxFlat) -> Button:
	var b := Button.new()
	b.text = Bahasa.t(kunci)
	b.custom_minimum_size = Vector2(0, 96.0)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", warna)
	b.add_theme_stylebox_override("normal", gaya)
	b.add_theme_stylebox_override("hover", gaya)
	b.add_theme_stylebox_override("pressed", gaya)
	b.add_theme_stylebox_override("disabled", Tema.kotak(Color(0.12, 0.14, 0.15), Color(0.3, 0.35, 0.35), 2, 18))
	return b

# Menempatkan gambar peta dan titik negara sesuai ukuran area peta saat ini.
func _susun_peta() -> void:
	var lebar := _peta_wrap.size.x
	var tinggi := lebar * RASIO_PETA
	_peta_wrap.custom_minimum_size = Vector2(0, tinggi)
	var gambar := _peta_wrap.get_node("Gambar") as TextureRect
	gambar.size = Vector2(lebar, tinggi)
	for n in Lokasi.semua_negara():
		var kode := String(n["kode"])
		var b := _titik_negara.get(kode) as Button
		if b == null:
			continue
		var pusat := Vector2(float(n["x"]) * lebar, float(n["y"]) * tinggi)
		b.position = pusat - Vector2(UKURAN_TITIK, UKURAN_TITIK) * 0.5
		_gaya_titik(b, kode == _negara)

func _gaya_titik(b: Button, aktif: bool) -> void:
	var merah := Color("#ff4d4d") if not aktif else Color("#ff7070")
	b.add_theme_color_override("font_color", merah)
	b.add_theme_color_override("font_hover_color", Color("#ff7070"))
	b.add_theme_color_override("font_pressed_color", Color("#ff7070"))
	b.add_theme_font_size_override("font_size", 44 if aktif else 34)

func _pilih_negara(kode: String) -> void:
	_negara = kode
	_kota = ""
	_segarkan()

func _pilih_kota(kode: String) -> void:
	_kota = kode
	_segarkan()

func _mulai() -> void:
	if _negara == "" or _kota == "":
		return
	selesai.emit(_negara, _kota)

# Membangun ulang daftar kota dan status sesuai pilihan saat ini.
func _segarkan() -> void:
	for n in Lokasi.semua_negara():
		_gaya_titik(_titik_negara[String(n["kode"])], String(n["kode"]) == _negara)
	for c in _daftar_kota.get_children():
		c.queue_free()
	_tombol_kota.clear()
	if _negara == "":
		_lbl_status.text = Bahasa.t("intro.pilih_negara_dulu")
		_lbl_hint.text = ""
		_tombol_mulai.disabled = true
		return
	var negara := Lokasi.cari_negara(_negara)
	var nama_negara := Lokasi.nama_negara(_negara)
	for k in negara.get("kota", []):
		var kode := String(k["kode"])
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 88)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "  " + Lokasi.nama_kota(_negara, kode)
		b.add_theme_font_size_override("font_size", 28)
		var aktif := kode == _kota
		var warna := Tema.AMBER if aktif else Tema.TEKS
		b.add_theme_color_override("font_color", warna)
		b.add_theme_stylebox_override("normal", Tema.kotak(Color(0.08, 0.12, 0.14, 0.95), Tema.AMBER if aktif else Tema.TEAL, 2 if aktif else 1, 16))
		b.add_theme_stylebox_override("hover", Tema.kotak(Color(0.1, 0.16, 0.18, 0.95), Tema.AMBER, 2, 16))
		b.add_theme_stylebox_override("pressed", Tema.kotak(Color(0.1, 0.16, 0.18, 0.95), Tema.AMBER, 2, 16))
		b.pressed.connect(_pilih_kota.bind(kode))
		_daftar_kota.add_child(b)
		_tombol_kota[kode] = b
	if _kota == "":
		_lbl_status.text = nama_negara
		_lbl_hint.text = Bahasa.t("intro.pilih_kota")
		_tombol_mulai.disabled = true
	else:
		_lbl_status.text = Bahasa.t("intro.lokasi_terpilih") % [Lokasi.nama_kota(_negara, _kota), nama_negara]
		_lbl_hint.text = ""
		_tombol_mulai.disabled = false
