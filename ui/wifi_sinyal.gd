class_name WifiSinyal
extends Control

# Ikon sinyal Wi-Fi yang berfluktuasi seperti sinyal sungguhan: kadang penuh, kadang turun, kadang hilang sebentar.
const UKURAN := Vector2(36, 36)
const JEDA_MIN := 0.4
const JEDA_MAX := 1.2
const KECEPATAN := 4.0

var _level := 3.0
var _target := 3
var _tunggu := 0.0

func _init() -> void:
	custom_minimum_size = UKURAN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_tunggu -= delta
	if _tunggu <= 0.0:
		_tunggu = randf_range(JEDA_MIN, JEDA_MAX)
		_target = _pilih_target()
	_level = move_toward(_level, float(_target), delta * KECEPATAN)
	queue_redraw()

# Sinyal lebih sering penuh atau sedang, sesekali turun.
func _pilih_target() -> int:
	var r := randf()
	if r < 0.45:
		return 3
	if r < 0.75:
		return 2
	if r < 0.92:
		return 1
	return 0

func _draw() -> void:
	var pusat := Vector2(size.x * 0.5, size.y * 0.88)
	var redup := Color(Tema.TEAL, 0.18)
	for i in range(3):
		var r := size.x * (0.3 + 0.22 * i)
		var warna := Tema.TEAL if _level >= float(i) + 0.5 else redup
		draw_arc(pusat, r, deg_to_rad(-135.0), deg_to_rad(-45.0), 24, warna, 4.0, true)
	draw_circle(pusat, 3.5, Tema.TEAL if _level >= 0.5 else redup)
