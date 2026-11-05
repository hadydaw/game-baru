extends GutTest

# Intro pemain baru: data lokasi, pemilihan negara dan kota, penyimpanan lokasi,
# IP unik per node yang stabil setelah dimuat ulang, dan pergantian bahasa.

const UJI := "user://uji_pemain_baru.json"

func before_each() -> void:
	Pengaturan.berkas_aktif = UJI
	Bahasa.kode = "id"

func after_each() -> void:
	Bahasa.kode = "id"
	if FileAccess.file_exists(UJI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UJI))

func _sesi_baru() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))
	s.jaringan.acak_ip()
	return s

func test_data_lokasi_sepuluh_negara_masing_masing_sepuluh_kota() -> void:
	var negara := Lokasi.semua_negara()
	assert_eq(negara.size(), 10)
	for n in negara:
		assert_eq(n["kota"].size(), 10, "kota di %s" % n["kode"])
		assert_true(float(n["x"]) >= 0.0 and float(n["x"]) <= 1.0)
		assert_true(float(n["y"]) >= 0.0 and float(n["y"]) <= 1.0)

func test_titik_negara_dan_kota_unik() -> void:
	var kode_negara := {}
	for n in Lokasi.semua_negara():
		assert_false(kode_negara.has(n["kode"]))
		kode_negara[n["kode"]] = true
		var kode_kota := {}
		for k in n["kota"]:
			assert_false(kode_kota.has(k["kode"]), "kota ganda di %s" % n["kode"])
			kode_kota[k["kode"]] = true

func test_nama_mengikuti_bahasa() -> void:
	Bahasa.kode = "id"
	assert_eq(Lokasi.nama_negara("jepang"), "Jepang")
	assert_eq(Lokasi.nama_negara("jepang"), "Jepang")
	Bahasa.kode = "en"
	assert_eq(Lokasi.nama_negara("jepang"), "Japan")
	assert_eq(Lokasi.nama_kota("jepang", "tokyo"), "Tokyo")

func test_kota_tidak_ada_mengembalikan_kosong() -> void:
	assert_true(Lokasi.cari_kota("jepang", "tidak_ada").is_empty())
	assert_true(Lokasi.cari_negara("tidak_ada").is_empty())

func test_lokasi_tersimpan_dan_termuat() -> void:
	var s := _sesi_baru()
	s.lokasi = {"negara": "mesir", "kota": "luxor"}
	var d := s.to_dict()
	var pulih := ShellSession.dari_dict(d)
	assert_eq(pulih.lokasi, {"negara": "mesir", "kota": "luxor"})

func test_ip_unik_dan_rentang_privat() -> void:
	var s := _sesi_baru()
	var terpakai := {}
	for id in s.jaringan.data:
		var ip := s.jaringan.ip(id)
		assert_false(terpakai.has(ip), "IP ganda: %s" % ip)
		terpakai[ip] = true
		var privat := ip.begins_with("10.") or ip.begins_with("192.168.")
		if ip.begins_with("172."):
			var dua := int(ip.split(".")[1])
			privat = dua >= 16 and dua <= 31
		assert_true(privat, "bukan IP privat: %s" % ip)

func test_ip_berbeda_antar_sesi_baru() -> void:
	var a := _sesi_baru()
	var b := _sesi_baru()
	var sama := 0
	for id in a.jaringan.data:
		if a.jaringan.ip(id) == b.jaringan.ip(id):
			sama += 1
	assert_true(sama < a.jaringan.data.size(), "IP seharusnya berubah antar sesi baru")

func test_ip_stabil_setelah_muat_ulang() -> void:
	var s := _sesi_baru()
	var sebelum := {}
	for id in s.jaringan.data:
		sebelum[id] = s.jaringan.ip(id)
	var pulih := ShellSession.dari_dict(s.to_dict())
	for id in sebelum:
		assert_eq(pulih.jaringan.ip(id), sebelum[id], "IP %s berubah" % id)

func test_scan_memakai_ip_acak_node() -> void:
	var s := _sesi_baru()
	var ip := s.jaringan.ip("arsip")
	var hasil := s.jalankan("scan %s" % ip)
	var teks := ""
	for b in hasil:
		teks += String(b.get("teks", ""))
	assert_true(teks.contains(ip), "scan dengan IP acak harus mengenali arsip")

func test_teks_misi_memakai_ip_sesi() -> void:
	var s := _sesi_baru()
	var ip := s.jaringan.ip("arsip")
	var teks := Misi.ganti_ip(s, "Pindai IP {ip:arsip} dengan perintah scan")
	assert_eq(teks, "Pindai IP %s dengan perintah scan" % ip)
	assert_false(teks.contains("{ip:"))

func test_jaringan_default_tetap_untuk_tes_lama() -> void:
	var j := Jaringan.muat()
	assert_eq(j.ip("arsip"), "10.7.0.8")

func test_bahasa_inggris_untuk_teks_intro() -> void:
	Bahasa.kode = "en"
	assert_true(Bahasa.t("intro.hal1").begins_with("Welcome"))
	assert_true(Bahasa.t("intro.hal2").contains("Duka Janggal") or Bahasa.t("intro.hal2").contains("Duka Janggal Government"))
	Bahasa.kode = "id"
	assert_true(Bahasa.t("intro.hal1").begins_with("Selamat datang"))
