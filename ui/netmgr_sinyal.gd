class_name NetmgrSinyal
extends Control

# Batang kekuatan sinyal. Nilai dBm diubah menjadi 0-4 batang, lalu batang bergerak halus ke nilai itu.

var _target := 0.0
var _tampil := 0.0
var warna: Color = Tema.TEAL

func _ready() -> void:
	custom_minimum_size = Vector2(56, 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_dbm(dbm: int) -> void:
	_target = float(WifiLab.batang_sinyal(dbm))
	set_process(true)

func set_batang(n: float) -> void:
	_target = n
	set_process(true)

func _process(delta: float) -> void:
	_tampil = move_toward(_tampil, _target, delta * 12.0)
	queue_redraw()
	if is_equal_approx(_tampil, _target):
		set_process(false)

func _draw() -> void:
	var lebar := size.x / 4.0
	for i in range(4):
		var isi := clampf(_tampil - float(i), 0.0, 1.0)
		var tinggi := size.y * (0.3 + 0.7 * float(i) / 3.0)
		var rect := Rect2(float(i) * lebar + 2.0, size.y - tinggi, lebar - 6.0, tinggi)
		draw_rect(rect, Color(Tema.TEKS_REDUP, 0.2))
		if isi > 0.0:
			draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * (1.0 - isi), rect.size.x, rect.size.y * isi), warna)
