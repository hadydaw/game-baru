class_name KonfirmasiPanel
extends Control

# Dialog konfirmasi bergaya JTN. Overlay penuh layar yang memblokir sentuhan ke layar di bawahnya.
# Kartu tersusun vertikal dan lebarnya mengikuti layar, sehingga teks membungkus dan tidak terpotong.
# Tombol berukuran lebar penuh dan tinggi cukup untuk disentuh jari.

signal diterima
signal dibatalkan

const WARNA_LATAR := Color("#0d1117")
const WARNA_TEAL := Color("#2dd4bf")
const WARNA_BATAS := Color(0.45, 0.6, 0.58)
const TINGGI_TOMBOL := 96.0
const JARAK_LUAR := 40

var _aman := Vector4.ZERO
var _luar: MarginContainer
var _judul: Label
var _isi: Label
var _tombol_ya: Button
var _tombol_batal: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var latar := ColorRect.new()
	latar.color = Color(0, 0, 0, 0.8)
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	latar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(latar)

	_luar = MarginContainer.new()
	_luar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_luar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_luar)
	var tumpuk := VBoxContainer.new()
	tumpuk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_luar.add_child(tumpuk)
	var atas := Control.new()
	atas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tumpuk.add_child(atas)

	var kartu := PanelContainer.new()
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartu.add_theme_stylebox_override("panel", Tema.kotak(WARNA_LATAR, WARNA_TEAL, 2, 18))
	tumpuk.add_child(kartu)
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 28)
	kartu.add_child(m)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 20)
	m.add_child(kolom)

	_judul = Tema.label("", WARNA_TEAL, 34)
	_judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(_judul)
	_isi = Tema.label("", Tema.TEKS, 24)
	_isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_child(_isi)

	_tombol_ya = _tombol(true)
	_tombol_ya.pressed.connect(func(): diterima.emit())
	kolom.add_child(_tombol_ya)
	_tombol_batal = _tombol(false)
	_tombol_batal.pressed.connect(func(): dibatalkan.emit())
	kolom.add_child(_tombol_batal)

	var bawah := Control.new()
	bawah.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bawah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tumpuk.add_child(bawah)
	visible = false
	atur_aman(_aman)

func _tombol(utama: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, TINGGI_TOMBOL)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color("#e6f7f5") if not utama else Color("#070b0e"))
	b.add_theme_stylebox_override("normal", _gaya(utama, false))
	b.add_theme_stylebox_override("hover", _gaya(utama, true))
	b.add_theme_stylebox_override("pressed", _gaya(utama, true))
	return b

func _gaya(utama: bool, aktif: bool) -> StyleBoxFlat:
	var bg := WARNA_TEAL if utama else Color(0.06, 0.1, 0.12)
	if utama and aktif:
		bg = Color("#5eead4")
	elif not utama and aktif:
		bg = Color(0.1, 0.16, 0.18)
	var batas := WARNA_TEAL if utama else WARNA_BATAS
	return Tema.kotak(bg, batas, 2 if utama else 1, 12)

# Mengatur teks dan label tombol, lalu menampilkan dialog.
func tampil(judul: String, isi: String, label_ya: String, label_batal: String) -> void:
	_judul.text = judul
	_isi.text = isi
	_tombol_ya.text = label_ya
	_tombol_batal.text = label_batal
	visible = true
	move_to_front()

func sembunyikan() -> void:
	visible = false

# Area aman perangkat (notch, status bar) ditambahkan ke jarak luar agar kartu tidak tertutup.
func atur_aman(nilai: Vector4) -> void:
	_aman = nilai
	if _luar == null:
		return
	_luar.add_theme_constant_override("margin_left", int(_aman.x) + JARAK_LUAR)
	_luar.add_theme_constant_override("margin_top", int(_aman.y) + JARAK_LUAR)
	_luar.add_theme_constant_override("margin_right", int(_aman.z) + JARAK_LUAR)
	_luar.add_theme_constant_override("margin_bottom", int(_aman.w) + JARAK_LUAR)
