extends SceneTree

# Smoke test Desktop dan dialog kembali ke menu pada ukuran HP portrait:
# tombol Menu terlihat di dalam layar, dan dialog konfirmasi tidak keluar layar.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("LULUS: ", pesan)
	else:
		print("GAGAL: ", pesan)
		_gagal += 1

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_desktop.json"
	SesiUtama.sesi = ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))
	for ukuran in [Vector2(1080, 1920), Vector2(720, 1280), Vector2(1080, 2340)]:
		# Meniru MainController: layar berada di dalam wadah berukuran layar.
		# Viewport diset sama dengan layar: tata letak Desktop membaca ukuran viewport.
		root.size = ukuran
		var wadah := Control.new()
		wadah.size = ukuran
		root.add_child(wadah)
		var d := DesktopView.new()
		d.size = ukuran
		wadah.add_child(d)
		await process_frame
		await process_frame
		var tombol_menu: Button = null
		for b in d.find_children("*", "Button", true, false):
			if (b as Button).text.contains("Menu"):
				tombol_menu = b
		_cek(tombol_menu != null and tombol_menu.is_visible_in_tree(), "tombol Menu ada di Desktop %dx%d" % [ukuran.x, ukuran.y])
		if tombol_menu != null:
			var r := tombol_menu.get_global_rect()
			_cek(r.position.x >= 0 and r.end.x <= ukuran.x and r.end.y <= ukuran.y, "tombol Menu di dalam layar %dx%d" % [ukuran.x, ukuran.y])
			_cek(r.size.y >= 64, "tombol Menu cukup tinggi untuk disentuh %dx%d" % [ukuran.x, ukuran.y])
		wadah.free()

		var wadah2 := Control.new()
		wadah2.size = ukuran
		root.add_child(wadah2)
		var p := KonfirmasiPanel.new()
		wadah2.add_child(p)
		await process_frame
		p.tampil("Kembali ke menu?", "Progres kamu disimpan. Pilih Lanjutkan di menu untuk meneruskan dari sini. Tidak ada data yang dihapus.", "Kembali ke Menu", "Batal")
		await process_frame
		await process_frame
		var luar := false
		for b in p.find_children("*", "Button", true, false):
			var rb := (b as Control).get_global_rect()
			if rb.position.x < 0 or rb.end.x > ukuran.x or rb.end.y > ukuran.y or rb.size.y < 80:
				luar = true
				print("  tombol bermasalah: ", (b as Button).text, " ", rb)
		_cek(not luar, "tombol dialog di dalam layar dan cukup tinggi %dx%d" % [ukuran.x, ukuran.y])
		_cek(p._isi.get_global_rect().end.x <= ukuran.x, "teks dialog tidak keluar layar %dx%d" % [ukuran.x, ukuran.y])
		wadah2.free()

	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	print("HASIL DESKTOP: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
