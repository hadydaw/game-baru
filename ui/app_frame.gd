class_name AppFrame
extends Control

# Bingkai aplikasi layar penuh: header dengan tombol kembali dan area konten.

signal kembali

const WARNA_HEADER := Color("#161b22")

var _judul: Label
var _area: Control

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var kolom := VBoxContainer.new()
    kolom.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(kolom)
    var header := PanelContainer.new()
    var gaya := StyleBoxFlat.new()
    gaya.bg_color = WARNA_HEADER
    header.add_theme_stylebox_override("panel", gaya)
    kolom.add_child(header)
    var baris := HBoxContainer.new()
    header.add_child(baris)
    var tombol := Button.new()
    tombol.text = "‹ Desktop"
    tombol.custom_minimum_size = Vector2(0, 88)
    tombol.pressed.connect(func(): kembali.emit())
    baris.add_child(tombol)
    _judul = Label.new()
    _judul.size_flags_horizontal = SIZE_EXPAND_FILL
    _judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    baris.add_child(_judul)
    _area = Control.new()
    _area.size_flags_vertical = SIZE_EXPAND_FILL
    kolom.add_child(_area)

# Dipanggil setelah node masuk ke tree.
func setup(judul: String, konten: Control) -> void:
    _judul.text = judul
    konten.set_anchors_preset(Control.PRESET_FULL_RECT)
    _area.add_child(konten)
