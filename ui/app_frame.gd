class_name AppFrame
extends Control

# Bingkai aplikasi layar penuh: header dengan tombol kembali, dan area konten dalam bingkai teal.
# Seluruh layar dipakai; hanya padding area aman yang dikosongkan.

signal kembali

const JARAK_BINGKAI := 12

# Area aman perangkat: kiri, atas, kanan, bawah (diisi oleh MainController).
var aman := Vector4.ZERO

var _judul: Label
var _area: Control
var _margin_luar: MarginContainer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _margin_luar = MarginContainer.new()
    _margin_luar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_margin_luar)
    atur_aman(aman)

    var kolom := VBoxContainer.new()
    kolom.add_theme_constant_override("separation", 0)
    _margin_luar.add_child(kolom)

    var header := PanelContainer.new()
    header.add_theme_stylebox_override("panel", Tema.header_bawah(Tema.LATAR_HEADER, Tema.TEAL))
    kolom.add_child(header)
    var baris := HBoxContainer.new()
    header.add_child(baris)
    var tombol_kembali := Button.new()
    tombol_kembali.flat = true
    tombol_kembali.text = "‹ Desktop"
    tombol_kembali.focus_mode = Control.FOCUS_NONE
    tombol_kembali.custom_minimum_size = Vector2(0, 88)
    tombol_kembali.add_theme_color_override("font_color", Tema.TEAL)
    tombol_kembali.add_theme_font_size_override("font_size", 24)
    tombol_kembali.pressed.connect(func(): kembali.emit())
    baris.add_child(tombol_kembali)
    _judul = Tema.label("", Tema.TEKS, 26)
    _judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    baris.add_child(_judul)

    var margin := MarginContainer.new()
    margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    Tema.margin_seragam(margin, JARAK_BINGKAI)
    kolom.add_child(margin)
    var bingkai := PanelContainer.new()
    bingkai.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 18))
    margin.add_child(bingkai)
    _area = Control.new()
    _area.size_flags_vertical = Control.SIZE_EXPAND_FILL
    bingkai.add_child(_area)

# Dipanggil MainController saat layar atau area aman berubah.
func atur_aman(nilai: Vector4) -> void:
    aman = nilai
    if not is_instance_valid(_margin_luar):
        return
    _margin_luar.add_theme_constant_override("margin_left", int(aman.x))
    _margin_luar.add_theme_constant_override("margin_top", int(aman.y))
    _margin_luar.add_theme_constant_override("margin_right", int(aman.z))
    _margin_luar.add_theme_constant_override("margin_bottom", int(aman.w))

# Dipanggil setelah node masuk ke tree.
func setup(judul: String, konten: Control) -> void:
    _judul.text = judul
    konten.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _area.add_child(konten)
