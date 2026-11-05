class_name NetmgrRadar
extends Control

# Radar pemindaian Network Manager. Garis sapuan hanya bergerak saat pemindaian sedang berjalan.
# Titik jaringan muncul sesuai hasil yang sudah ditampilkan (titik), jaraknya mengikuti kekuatan sinyal.

var aktif := false
var titik: Array = []   # Array of Vector2 ternormalisasi (-1..1)
var _sudut := 0.0
var _waktu := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 280)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_aktif(nilai: bool) -> void:
	aktif = nilai
	set_process(aktif or not titik.is_empty())
	queue_redraw()

func set_titik(daftar: Array) -> void:
	titik = daftar
	set_process(aktif or not titik.is_empty())
	queue_redraw()

func _process(delta: float) -> void:
	_waktu += delta
	if aktif:
		_sudut = fmod(_sudut + delta * 2.6, TAU)
	queue_redraw()

func _draw() -> void:
	var pusat := size * 0.5
	var r := minf(size.x, size.y) * 0.46
	draw_circle(pusat, r, Color(0.02, 0.09, 0.1, 0.9))
	for i in range(1, 4):
		draw_arc(pusat, r * float(i) / 3.0, 0.0, TAU, 72, Color(Tema.TEAL, 0.2), 1.5)
	draw_line(pusat + Vector2(-r, 0), pusat + Vector2(r, 0), Color(Tema.TEAL, 0.14), 1.0)
	draw_line(pusat + Vector2(0, -r), pusat + Vector2(0, r), Color(Tema.TEAL, 0.14), 1.0)
	if aktif:
		for k in range(18):
			var a := _sudut - float(k) * 0.045
			var alpha := (1.0 - float(k) / 18.0) * 0.4
			draw_line(pusat, pusat + Vector2(cos(a), sin(a)) * r, Color(Tema.TEAL, alpha), 3.0)
		draw_line(pusat, pusat + Vector2(cos(_sudut), sin(_sudut)) * r, Color(Tema.TEAL, 0.95), 2.0)
	for i in range(titik.size()):
		var p: Vector2 = pusat + Vector2(titik[i]) * r
		var kedip := 0.75 + 0.25 * sin(_waktu * 4.0 + float(i))
		draw_circle(p, 14.0, Color(Tema.AMBER, 0.18 * kedip))
		draw_circle(p, 6.0, Color(Tema.AMBER, kedip))
	draw_circle(pusat, 4.0, Color(Tema.TEAL, 0.9))
