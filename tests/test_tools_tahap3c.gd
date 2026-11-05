extends GutTest

# Tahap 3c: Crypt Decoder (decode dan penolakan cat), Password Analyzer tingkat 1 (analyze),
# dan data harga tool sesuai rentang di dokumen rancangan.

func _sesi() -> ShellSession:
	var operator := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {
		"rahasia.enc": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----",
			"isi": "QZ9x-7f2", "enkripsi": "B", "isi_asli": "Kode: 7731", "ukuran": 10},
		"sampel.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----",
			"isi": "a1b2c3", "hash": {"algo": "sha256", "salt": false}, "ukuran": 6},
		"bergaram.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----",
			"isi": "x", "hash": {"algo": "bcrypt", "salt": true}, "ukuran": 1},
		"catatan.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----",
			"isi": "biasa", "ukuran": 5},
	}}
	var akar := {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
		"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": operator}}}}
	return ShellSession.new(Vfs.new(akar))

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += Bahasa.pilih(String(b["teks"])) + "\n"
	return t

func _galat(hasil: Array) -> bool:
	return hasil.size() > 0 and String(hasil[0]["tipe"]) == "error"

func test_cat_berkas_terenkripsi_ditolak_tanpa_decoder() -> void:
	var s := _sesi()
	var hasil := s.jalankan("cat rahasia.enc")
	assert_true(_galat(hasil))
	assert_true(_teks(hasil).contains("Dibutuhkan: Crypt Decoder."))
	assert_false(_teks(hasil).contains("QZ9x"), "isi terenkripsi tidak bocor")

func test_cat_berkas_terenkripsi_minta_tingkat_lebih_tinggi() -> void:
	var s := _sesi()
	s.inventory.miliki("crypt_decoder", "awal", 1)
	assert_true(_teks(s.jalankan("cat rahasia.enc")).contains("tingkat 2"))

func test_decode_tanpa_kepemilikan_tidak_ditemukan() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("decode rahasia.enc")).contains("perintah tidak ditemukan"))

func test_decode_dengan_tingkat_cukup_menampilkan_isi_asli() -> void:
	var s := _sesi()
	s.inventory.miliki("crypt_decoder", "black_market", 2)
	var hasil := s.jalankan("decode rahasia.enc")
	assert_false(_galat(hasil))
	assert_true(_teks(hasil).contains("Kode: 7731"))

func test_decode_tingkat_kurang_ditolak() -> void:
	var s := _sesi()
	s.inventory.miliki("crypt_decoder", "awal", 1)
	assert_true(_galat(s.jalankan("decode rahasia.enc")))

func test_decode_berkas_biasa_dan_banyak_argumen_ditolak() -> void:
	var s := _sesi()
	s.inventory.miliki("crypt_decoder", "awal", 3)
	assert_true(_teks(s.jalankan("decode catatan.txt")).contains("tidak terenkripsi"))
	assert_true(_teks(s.jalankan("decode rahasia.enc catatan.txt")).contains("satu berkas"))

func test_cat_berkas_biasa_tetap_bisa_dibaca() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("cat catatan.txt")).contains("biasa"))

func test_analyze_tanpa_kepemilikan_tidak_ditemukan() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("analyze sampel.txt")).contains("perintah tidak ditemukan"))

func test_analyze_hash_tanpa_salt() -> void:
	var s := _sesi()
	s.inventory.miliki("password_analyzer", "awal", 1)
	var t := _teks(s.jalankan("analyze sampel.txt"))
	assert_true(t.contains("Jenis hash: sha256"))
	assert_true(t.contains("Salt: tidak ada."))

func test_analyze_hash_dengan_salt_tidak_dapat_dianalisis() -> void:
	var s := _sesi()
	s.inventory.miliki("password_analyzer", "awal", 1)
	assert_true(_teks(s.jalankan("analyze bergaram.txt")).contains("tidak dapat dianalisis"))

func test_analyze_berkas_tanpa_hash() -> void:
	var s := _sesi()
	s.inventory.miliki("password_analyzer", "awal", 1)
	assert_true(_teks(s.jalankan("analyze catatan.txt")).contains("Tidak ada hash"))

func test_firewall_bypass_bisa_dimiliki_tanpa_perintah() -> void:
	var inv := Inventory.baru()
	assert_true(inv.miliki("firewall_bypass", "misi"))
	assert_eq(ToolDefs.perintah("firewall_bypass").size(), 0)

func test_harga_tool_sesuai_rentang_dokumen() -> void:
	# Rentang dari dokumen rancangan: tingkat 1 200–500, tingkat 2 600–1.200, tingkat 3 1.500–3.000.
	var rentang := {1: [200, 500], 2: [600, 1200], 3: [1500, 3000]}
	for id in ToolDefs.DEFS:
		for t in [1, 2, 3]:
			var h := ToolDefs.harga(String(id), t)
			assert_true(h >= rentang[t][0] and h <= rentang[t][1], "%s tingkat %d di luar rentang" % [id, t])
