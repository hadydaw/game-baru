class_name AppFrame
extends Control

# Bingkai aplikasi layar penuh: header dengan tombol kembali dan area konten dalam bingkai teal.

signal kembali

var _judul: Label
var _area: Control

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var kolom := VBoxContainer.new()
    kolom.set_anchors_preset(Control.PRESET_FULL_RECT)
    kolom.add_theme_constant_override("separation", 0)
    add_child(kolom)

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
    Tema.margin_seragam(margin, 12)
    kolom.add_child(margin)
    var bingkai := PanelContainer.new()
    bingkai.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 18))
    margin.add_child(bingkai)
    _area = Control.new()
    _area.size_flags_vertical = Control.SIZE_EXPAND_FILL
    bingkai.add_child(_area)

# Dipanggil setelah node masuk ke tree.
func setup(judul: String, konten: Control) -> void:
    _judul.text = judul
    konten.set_anchors_preset(Control.PRESET_FULL_RECT)
    _area.add_child(konten)
