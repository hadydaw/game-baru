class_name NetmgrGelombang
extends Control

# Indikator adapter: gelombang sinyal dan lampu status. Gelombang bergerak hanya saat perangkat aktif.
# Terputus tampil diam dan redup, kesalahan tampil merah tanpa gerak.

const TANPA := "tidak_terdeteksi"

var status := TANPA
var _waktu := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 110)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_status(nilai: String) -> void:
	status = nilai
	queue_redraw()

func _process(delta: float) -> void:
	_waktu += delta
	if status == "aktif" or status == "terputus":
		queue_redraw()

func _warna() -> Color:
	match status:
		"aktif":
			return Tema.TEAL
		"kesalahan":
			return Color(0.94, 0.27, 0.27)
		"terputus":
			return Tema.AMBER
	return Tema.TEKS_REDUP

func _draw() -> void:
	var warna := _warna()
	var asal := Vector2(size.x * 0.14, size.y * 0.62)
	var jumlah := 3
	var nyala := 0
	if status == "aktif":
		# Kekuatan sinyal naik turun seperti pada perangkat sungguhan.
		nyala = clampi(int(round(2.0 + 1.5 * sin(_waktu * 2.2))), 1, 3)
	elif status == "terputus":
		nyala = 1
	for k in range(jumlah):
		var radius := 18.0 + float(k) * 16.0
		var lit := k < nyala
		var alpha := (0.95 if lit else 0.18)
		if status == "aktif" and lit:
			alpha = 0.6 + 0.35 * sin(_waktu * 4.0 - float(k))
		draw_arc(asal, radius, -PI * 0.3, PI * 0.3, 40, Color(warna, alpha), 4.0)
	draw_circle(asal, 6.0, Color(warna, 1.0 if status != TANPA else 0.3))
	# Lampu status di kanan.
	var lampu := Vector2(size.x - 28.0, size.y * 0.5)
	var kedip := 1.0 if status != "aktif" else 0.6 + 0.4 * sin(_waktu * 3.0)
	draw_circle(lampu, 13.0, Color(warna, 0.2 * kedip))
	draw_circle(lampu, 7.0, Color(warna, kedip))
