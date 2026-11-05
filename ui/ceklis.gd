class_name Ceklis
extends Control

# Tanda selesai untuk tahap dan tujuan misi: kotak dengan centang hijau bila selesai, kotak kosong bila belum.
# Digambar langsung agar tidak bergantung pada glyph font.

const UKURAN := 26.0
const HIJAU := Color("#3fb950")
const KOTAK_BELUM := Color(0.45, 0.5, 0.5)

var selesai := false

func _init(p_selesai: bool = false) -> void:
	selesai = p_selesai
	custom_minimum_size = Vector2(UKURAN, UKURAN)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var r := Rect2(Vector2(3, 3), Vector2(UKURAN - 6, UKURAN - 6))
	var warna := HIJAU if selesai else KOTAK_BELUM
	draw_rect(r, Color(warna.r, warna.g, warna.b, 0.12), true)
	draw_rect(r, warna, false, 2.0)
	if selesai:
		var titik := PackedVector2Array([
			Vector2(7, 14), Vector2(11.5, 19), Vector2(20, 8)])
		draw_polyline(titik, HIJAU, 3.0, true)
