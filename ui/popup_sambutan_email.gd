class_name PopupSambutanEmail
extends Control

# Pemberitahuan pertama di Desktop bahwa pemain punya email baru. Hanya muncul sekali per sesi baru.

signal diterima

const JARAK_LUAR := 40

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var latar := ColorRect.new()
	latar.color = Color(0, 0, 0, 0.8)
	latar.mouse_filter = Control.MOUSE_FILTER_STOP
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", JARAK_LUAR)
	m.add_theme_constant_override("margin_right", JARAK_LUAR)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var pusat := VBoxContainer.new()
	pusat.alignment = BoxContainer.ALIGNMENT_CENTER
	pusat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(pusat)

	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Color("#0d1117"), Tema.TEAL, 2, 18))
	pusat.add_child(kartu)
	var isi_m := MarginContainer.new()
	Tema.margin_seragam(isi_m, 32)
	kartu.add_child(isi_m)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 26)
	isi_m.add_child(kolom)

	var judul := Tema.label("", Tema.TEAL, 44)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(judul)
	Bahasa.isi(judul, "email.sambutan_judul")

	var isi := Tema.label("", Tema.TEKS, 34)
	isi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(isi)
	Bahasa.isi(isi, "email.sambutan_isi")

	var ok := Button.new()
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 96)
	ok.add_theme_font_size_override("font_size", 32)
	ok.add_theme_color_override("font_color", Color("#06201c"))
	ok.add_theme_stylebox_override("normal", Tema.kotak(Tema.TEAL, Tema.TEAL, 0, 18))
	ok.add_theme_stylebox_override("hover", Tema.kotak(Tema.TEAL, Tema.TEAL, 0, 18))
	ok.add_theme_stylebox_override("pressed", Tema.kotak(Color("#1fb3a1"), Tema.TEAL, 0, 18))
	Bahasa.isi(ok, "email.sambutan_ok")
	ok.pressed.connect(func(): diterima.emit())
	kolom.add_child(ok)

func atur_aman(nilai: Vector4) -> void:
	var m := get_child(1) as MarginContainer
	if m:
		m.add_theme_constant_override("margin_top", int(nilai.y) + JARAK_LUAR)
		m.add_theme_constant_override("margin_bottom", int(nilai.w) + JARAK_LUAR)
