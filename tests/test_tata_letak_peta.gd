extends GutTest

const AREA := Rect2(0, 64, 1080, 1200)

func before_each() -> void:
	Penyimpanan.berkas_aktif = "user://uji_sesi_peta.json"
	# Sesi baru untuk setiap tes agar tidak bergantung pada penyimpanan dan tes lain.
	SesiUtama.sesi = ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func test_posisi_semua_node_di_dalam_area() -> void:
	var posisi := TataLetakPeta.posisi(["gerbang", "arsip", "relay", "server_kota"], AREA)
	assert_eq(posisi.size(), 4)
	for id in posisi:
		assert_true(AREA.has_point(posisi[id]), "%s di luar area" % id)

func test_gerbang_berada_di_atas() -> void:
	var posisi := TataLetakPeta.posisi(["gerbang", "arsip", "relay"], AREA)
	assert_true(posisi["gerbang"].y < posisi["arsip"].y)
	assert_true(posisi["gerbang"].y < posisi["relay"].y)

func test_node_tidak_bertumpuk() -> void:
	var posisi := TataLetakPeta.posisi(["gerbang", "arsip", "relay", "server_kota"], AREA)
	var daftar := posisi.values()
	for i in range(daftar.size()):
		for k in range(i + 1, daftar.size()):
			assert_true(daftar[i].distance_to(daftar[k]) > 80.0, "node terlalu berdekatan")

func test_keadaan_terkunci_lebih_diutamakan() -> void:
	assert_eq(TataLetakPeta.keadaan({"terkunci": true, "status": "aktif"}), "terkunci")
	assert_eq(TataLetakPeta.keadaan({"terkunci": false, "status": "aktif"}), "aktif")
	assert_eq(TataLetakPeta.keadaan({"terkunci": false, "status": "tidak_aktif"}), "tidak_aktif")

func test_sambungan_hanya_node_terlihat() -> void:
	var j := Jaringan.muat()
	j.ditemukan = ["gerbang"]
	assert_eq(TataLetakPeta.sambungan(j).size(), 0, "gerbang belum punya tetangga terlihat")
	j.jelajahi("gerbang")
	var pasangan := TataLetakPeta.sambungan(j)
	assert_eq(pasangan.size(), 2, "gerbang terhubung ke arsip dan relay")

func test_sidik_berubah_setelah_ping() -> void:
	var sesi := SesiUtama.ambil()
	var sebelum := TataLetakPeta.sidik(sesi.jaringan)
	sesi.jalankan("ping -c 1 gerbang")
	var sesudah := TataLetakPeta.sidik(sesi.jaringan)
	assert_ne(sebelum, sesudah, "sidik harus berubah setelah ping sukses")

func test_sidik_berubah_setelah_nmap() -> void:
	var sesi := SesiUtama.ambil()
	sesi.jalankan("ping -c 1 gerbang")
	var sebelum := TataLetakPeta.sidik(sesi.jaringan)
	sesi.jalankan("nmap 10.7.0.8")
	var sesudah := TataLetakPeta.sidik(sesi.jaringan)
	assert_ne(sebelum, sesudah, "sidik harus berubah setelah nmap")

func test_sidik_stabil_bila_tidak_ada_perubahan() -> void:
	var sesi := SesiUtama.ambil()
	assert_eq(TataLetakPeta.sidik(sesi.jaringan), TataLetakPeta.sidik(sesi.jaringan))

func test_sesi_utama_satu_instance() -> void:
	var a := SesiUtama.ambil()
	var b := SesiUtama.ambil()
	assert_true(a == b, "Terminal dan Peta harus memakai sesi yang sama")

func test_perubahan_terminal_terlihat_di_peta() -> void:
	var sesi := SesiUtama.ambil()
	var sebelum := TataLetakPeta.sidik(sesi.jaringan)
	sesi.jalankan("ping -c 1 gerbang")
	var sesudah := TataLetakPeta.sidik(SesiUtama.ambil().jaringan)
	assert_ne(sebelum, sesudah)
	assert_true(SesiUtama.ambil().jaringan.dikenal("arsip"), "arsip terlihat setelah gerbang dijangkau")
