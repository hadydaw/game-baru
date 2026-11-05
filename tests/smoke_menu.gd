extends SceneTree

# Smoke test menu utama: tata letak tetap di dalam layar pada beberapa ukuran HP portrait,
# dan tombol Lanjutkan mengikuti keberadaan simpanan.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("LULUS: ", pesan)
	else:
		print("GAGAL: ", pesan)
		_gagal += 1

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_menu.json"
	Pengaturan.berkas_aktif = "user://uji_smoke_menu_pengaturan.json"
	if FileAccess.file_exists(Penyimpanan.berkas_aktif):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Penyimpanan.berkas_aktif))
	for ukuran in [Vector2(1080, 1920), Vector2(720, 1280), Vector2(1080, 2340)]:
		# Meniru MainController: menu berada di dalam wadah berukuran layar.
		var wadah := Control.new()
		wadah.size = ukuran
		root.add_child(wadah)
		var m := MenuUtama.new()
		wadah.add_child(m)
		await process_frame
		await process_frame
		var luar := true
		for b in m.find_children("*", "Button", true, false):
			if not (b as Control).is_visible_in_tree():
				continue  # tombol di panel tersembunyi tidak ditampilkan
			var r: Rect2 = (b as Control).get_global_rect()
			if r.position.x < 0 or r.position.y < 0 or r.end.x > ukuran.x or r.end.y > ukuran.y:
				luar = false
				print("  rect di luar: ", (b as Button).text, " ", r)
			if r.size.y < 80:
				luar = false
				print("  terlalu pendek: ", (b as Button).text, " ", r)
		_cek(luar, "semua tombol di dalam layar %dx%d dan cukup tinggi untuk disentuh" % [ukuran.x, ukuran.y])
		_cek((m._tombol["lanjutkan"] as Button).disabled, "Lanjutkan nonaktif tanpa simpanan (%dx%d)" % [ukuran.x, ukuran.y])
		wadah.free()
	Pengaturan.berkas_aktif = Pengaturan.BERKAS
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	print("HASIL MENU: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
