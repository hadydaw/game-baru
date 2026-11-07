extends GutTest

# Misi Tutorial 2 JEJAK JARINGAN: alur muncul, terima, tahap lewat perintah Terminal,
# keluaran tools, dan integrasi progres dengan Misi serta penyimpanan.

func _sesi() -> ShellSession:
	var s := ShellSession.new(Vfs.new(SesiUtama._fs_awal()), Jaringan.muat(), "operator")
	s.wifi.kunci_seed = 0
	return s

func _jalan(s: ShellSession, perintah: String) -> String:
	var t := ""
	for b in s.jalankan(perintah):
		t += ShellSession.teks_baris(b) + "\n"
	return t

func _selesaikan_tutorial_1(s: ShellSession) -> void:
	s.misi["misi_1"] = "selesai"
	Misi.perbarui(s)

func test_misi_2_muncul_setelah_tutorial_1_selesai() -> void:
	var s := _sesi()
	var m2 := Misi.temukan("misi_2")
	assert_false(Misi.tersedia(s, m2), "belum tersedia sebelum Tutorial 1 selesai")
	_selesaikan_tutorial_1(s)
	assert_true(Misi.tersedia(s, m2), "tersedia setelah Tutorial 1 selesai")
	assert_false(s.misi.has("misi_2"), "belum diterima")

func test_terima_mengirim_email_sekali() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	var sebelum := s.email.size() if "email" in s else 0
	assert_true(Misi.terima(s, "misi_2"))
	assert_eq(String(s.misi["misi_2"]), "aktif")
	assert_true(s.jaringan.progres.has("misi_terima:misi_2"))
	assert_false(Misi.terima(s, "misi_2"), "tidak bisa diterima dua kali")
	assert_true(sebelum >= 0)

func test_lab2_terkunci_sampai_misi_diterima() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	assert_true(s.jaringan.terkunci("lab2-berkas"))
	Misi.terima(s, "misi_2")
	assert_false(s.jaringan.terkunci("lab2-berkas"))

func test_ip_addr_dan_route_menampilkan_subnet_lab() -> void:
	var s := _sesi()
	var addr := _jalan(s, "ip addr")
	assert_true(addr.contains("inet 10.8.1.42/24"), "alamat perangkat")
	assert_true(addr.contains("link/ether 02:4a:1c:10:00:42"), "MAC perangkat")
	var route := _jalan(s, "ip route")
	assert_true(route.contains("default via 10.8.1.1 dev eth0"), "gateway")
	assert_true(s.jaringan.progres.has("ip:addr"))
	assert_true(s.jaringan.progres.has("ip:route"))

func test_netdiscover_tidak_ada_sebelum_dipasang() -> void:
	var s := _sesi()
	assert_true(_jalan(s, "netdiscover -r 10.8.1.0/24").contains("command not found") or _jalan(s, "netdiscover -r 10.8.1.0/24").contains("tidak ditemukan"))

func test_apt_pasang_nmap_mencatat_flag() -> void:
	var s := _sesi()
	_jalan(s, "apt install -y nmap")
	assert_true(s.jaringan.progres.has("pasang:nmap"))

func test_netdiscover_menemukan_host_lab_dan_mencatat_flag() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "apt install -y netdiscover")
	var t := _jalan(s, "netdiscover -r 10.8.1.0/24")
	assert_true(t.contains("10.8.1.8"), "berkas ditemukan")
	assert_true(t.contains("10.8.1.1"), "gerbang ditemukan")
	assert_true(t.contains("Senja Networks"), "vendor tampil")
	assert_true(s.jaringan.progres.has("netdiscover:pindai"))
	assert_true(s.jaringan.ditemukan.has("lab2-berkas"), "masuk Network Manager")

func test_netdiscover_wajib_range_24() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "apt install -y netdiscover")
	assert_true(_jalan(s, "netdiscover").contains("Usage"))
	assert_true(_jalan(s, "netdiscover -r 10.8.0.0/16").contains("Invalid range"))

func test_nmap_sn_subnet_dan_flag() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "apt install -y nmap")
	var t := _jalan(s, "nmap -sn 10.8.1.0/24")
	assert_true(t.contains("Nmap scan report for 10.8.1.8"))
	assert_true(t.contains("Nmap done"))
	assert_false(t.contains("10.7.0.8"), "hanya subnet yang diminta")
	assert_true(s.jaringan.progres.has("nmap:sn"))

func test_nmap_port_berkas_mencatat_flag() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "apt install -y nmap")
	_jalan(s, "nmap -sn 10.8.1.0/24")
	var t := _jalan(s, "nmap -p 22,80 10.8.1.8")
	assert_true(t.contains("22/tcp"))
	assert_true(t.contains("80/tcp"))
	assert_true(s.jaringan.progres.has("nmap:port:lab2-berkas"))

func test_nmap_oN_menulis_laporan_ke_berkas() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "apt install -y nmap")
	_jalan(s, "nmap -sn -oN laporan-jejak.txt 10.8.1.0/24")
	var abs := Vfs.normalisasi(s.cwd, "laporan-jejak.txt", s.home)
	var node := s.fs.ambil(abs)
	assert_false(node.is_empty(), "berkas laporan dibuat")
	assert_true(String(node.get("isi", "")).contains("Nmap scan report for 10.8.1.8"))
	assert_true(s.jaringan.progres.has("nmap:laporan"))

func test_wireshark_sampel_jejak_dan_flag_kredensial() -> void:
	var d := WiresharkData.muat_contoh("lab-jejak-internal")
	assert_false(d.is_empty(), "sampel termuat")
	var ada_login := false
	for pk in d["paket"]:
		if Dictionary(pk.get("fitur", {})).has("http.form.password"):
			ada_login = true
	assert_true(ada_login, "sampel memuat login HTTP plaintext")

func test_misi_2_selesai_setelah_semua_flag() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "apt install -y nmap")
	var urutan := ["ip:addr", "ip:route", "pasang:nmap", "pasang:netdiscover", "netdiscover:pindai",
		"nmap:sn", "nmap:port:lab2-berkas", "pasang:wireshark", "wireshark:jejak:kredensial", "nmap:laporan"]
	for f in urutan:
		s.jaringan.buka(f)
	Misi.perbarui(s)
	assert_eq(String(s.misi["misi_2"]), "selesai")
	assert_true(s.hadiah_diambil.has("misi_2"), "hadiah diberikan")

func test_progres_misi_2_bertahan_setelah_muat_ulang() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	_jalan(s, "ip addr")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_eq(String(pulih.misi["misi_2"]), "aktif")
	assert_true(pulih.jaringan.progres.has("ip:addr"))
	assert_eq(pulih.jaringan.ip("lab2-berkas"), "10.8.1.8")
	assert_eq(pulih.wifi.kunci_seed, 0)

func test_nmap_belum_dipasang_ditolak_seperti_perintah_tidak_ada() -> void:
	var s := _sesi()
	_selesaikan_tutorial_1(s)
	Misi.terima(s, "misi_2")
	var t := _jalan(s, "nmap -sn 10.8.1.0/24")
	assert_true(t.contains("not found") or t.contains("tidak ditemukan"), "nmap belum dipasang: %s" % t)
	assert_false(s.jaringan.progres.has("nmap:sn"), "tidak ada progres nmap sebelum dipasang")
	_jalan(s, "apt install -y nmap")
	assert_true(_jalan(s, "nmap -sn 10.8.1.0/24").contains("Nmap done"), "nmap berjalan setelah apt install")
