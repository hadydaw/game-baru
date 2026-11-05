extends SceneTree

# Smoke test Splash: logo utuh, di tengah, di dalam area aman, dan layer splash tidak melebar.
# Dijalankan pada ukuran HP portrait 9:16. Layout diuji di dalam wadah berukuran layar.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("LULUS: ", pesan)
	else:
		print("GAGAL: ", pesan)
		_gagal += 1

func _initialize() -> void:
	await process_frame
	var aman := Vector4(0, 60, 0, 40)  # status bar dan navigation bar
	for ukuran in [Vector2(720, 1280), Vector2(1080, 1920)]:
		var tag := "%dx%d" % [ukuran.x, ukuran.y]
		var m := MainController.new()
		var wadah := Control.new()
		wadah.size = ukuran
		root.add_child(wadah)
		var splash := m._buat_splash(ukuran, aman)
		wadah.add_child(splash)
		await process_frame
		await process_frame
		var wadah_rect := Rect2(Vector2.ZERO, ukuran)
		var latar := splash.find_children("*", "ColorRect", true, false)[0] as Control
		var logo := splash.find_children("*", "TextureRect", true, false)[0] as Control
		_cek(splash.get_global_rect() == wadah_rect, "layer splash sama dengan layar %s (tidak melebar)" % tag)
		_cek(latar.get_global_rect() == wadah_rect, "latar penuh layar %s" % tag)
		var r := logo.get_global_rect()
		_cek(r.position.x >= 0 and r.end.x <= ukuran.x and r.position.y >= 0 and r.end.y <= ukuran.y, "logo di dalam layar %s" % tag)
		_cek(r.position.y >= aman.y and r.end.y <= ukuran.y - aman.w, "logo di dalam area aman %s" % tag)
		_cek(absf(r.size.x - r.size.y) < 0.5, "logo tidak diregangkan (rasio 1:1 dipertahankan) %s" % tag)
		var pusat := r.get_center()
		var pusat_area := Vector2(ukuran.x / 2.0, (aman.y + (ukuran.y - aman.w)) / 2.0)
		_cek(pusat.distance_to(pusat_area) < 2.0, "logo di tengah area layar %s" % tag)
		wadah.free()
		m.free()
	print("HASIL SPLASH: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
