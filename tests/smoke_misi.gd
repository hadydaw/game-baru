extends SceneTree

# Smoke test Pusat Misi: layout tetap di dalam lebar HP portrait, aplikasi Misi di Desktop
# membuka Pusat Misi (bukan placeholder), dan misi aktif tampil dengan tujuannya.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("LULUS: ", pesan)
	else:
		print("GAGAL: ", pesan)
		_gagal += 1

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_misi.json"
	var kunci := {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "arsip:TK-7731", "ukuran": 13}
	var rumah := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {"kunci_arsip.txt": kunci}}
	var fs := {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": rumah}}}}
	SesiUtama.sesi = ShellSession.new(Vfs.new(fs), Jaringan.muat(), "operator")
	Misi.perbarui(SesiUtama.sesi)
	# Misi tutorial sudah diterima pemain, lalu tampil di Pusat Misi dengan judulnya saat ini.
	Misi.terima(SesiUtama.sesi, "misi_1")

	var kiri := MainController.new()
	_cek(kiri._buat_konten("misi") is PusatMisi, "aplikasi Misi di Desktop membuka Pusat Misi")
	kiri.free()

	for ukuran in [Vector2(720, 1280), Vector2(1080, 1920)]:
		var tag := "%dx%d" % [ukuran.x, ukuran.y]
		var wadah := Control.new()
		wadah.size = ukuran
		root.add_child(wadah)
		var layar := PusatMisi.new()
		layar.size = ukuran
		wadah.add_child(layar)
		await process_frame
		await process_frame
		layar.call("_pilih_kategori", "tutorial")
		layar.set("_tampil_daftar", "tutorial")
		layar.call("_segarkan_semua")
		await process_frame
		var keluar := 0
		var ada_judul := false
		var ada_tujuan := false
		for l in layar.find_children("*", "Label", true, false):
			var r := (l as Label).get_global_rect()
			if r.position.x < -0.5 or r.end.x > ukuran.x + 0.5:
				keluar += 1
			if (l as Label).text.contains("Tutorial Misi 1"):
				ada_judul = true
			# Rincian misi memuat baris "Tujuan : ..." dari ringkasan misi.
			if (l as Label).text.begins_with("Tujuan"):
				ada_tujuan = true
		_cek(keluar == 0, "semua teks Pusat Misi di dalam lebar %s" % tag)

		_cek(ada_judul, "misi aktif tampil dengan judulnya %s" % tag)
		_cek(ada_tujuan, "tujuan misi tampil %s" % tag)
		wadah.free()

	print("HASIL MISI: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
