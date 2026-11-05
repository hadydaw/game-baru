extends SceneTree

# Smoke test Peta Jaringan: instansiasi, pilih node, dan perubahan dari sesi Terminal tercermin.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("LULUS: ", pesan)
	else:
		print("GAGAL: ", pesan)
		_gagal += 1

func _initialize() -> void:
	await process_frame
	# Sesi baru agar hasil tidak dipengaruhi penyimpanan dari run sebelumnya.
	SesiUtama.sesi = ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))
	var peta := NetworkMap.new()
	peta.size = Vector2(1080, 1920)
	root.add_child(peta)
	_cek(peta.jumlah_node_terlihat() == 1, "awal hanya gerbang yang terlihat")

	peta.pilih_node("gerbang")
	_cek(peta.teks_detail() == "IP  10.7.0.1", "detail gerbang tampil")

	var sesi := SesiUtama.ambil()
	sesi.jalankan("ping -c 1 gerbang")
	await process_frame
	_cek(peta.jumlah_node_terlihat() >= 3, "tetangga gerbang muncul di peta setelah ping dari Terminal")
	sesi.jalankan("ping -c 1 arsip")
	_cek(SesiUtama.ambil().jaringan.dikenal("server_kota"), "server_kota terlihat setelah arsip dijangkau")

	sesi.jalankan("nmap 10.7.0.8")
	peta.pilih_node("arsip")
	_cek(peta.teks_detail() != "", "detail arsip tampil setelah nmap")

	peta.pilih_node("tidak_ada")
	_cek(peta.teks_detail().begins_with("Ketuk"), "node tidak dikenal tidak membuka detail")

	peta.free()
	print("HASIL PETA: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
