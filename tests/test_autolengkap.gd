extends GutTest

# Uji autocomplete Tab: nama perintah, opsi, subperintah, paket apt, jalur berkas, dan sampel Wireshark.
# Sumber data sama dengan saat perintah dijalankan: CommandRegistry, Repositori, dan Vfs pemain.

func _sesi() -> ShellSession:
	var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
	var data: Dictionary = JSON.parse_string(isi)
	return ShellSession.new(Vfs.new(data["/"]))

func _sesi_kosong() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func _pasang(s: ShellSession, id: String) -> void:
	s.jalankan("apt install -y " + id)
	assert_true(s.repositori.punya(id), "%s terpasang untuk uji" % id)

func _teks(s: ShellSession, masukan: String) -> String:
	return String(ShellComplete.lengkapi(s, masukan)["teks"])

func _sesi_terpasang(id: String) -> ShellSession:
	var s := _sesi()
	_pasang(s, id)
	return s

func _pilihan(s: ShellSession, masukan: String) -> Array:
	return ShellComplete.lengkapi(s, masukan)["pilihan"]

# 1. Nama perintah

func test_perintah_tunggal_dilengkapi() -> void:
	assert_eq(_teks(_sesi(), "ca"), "cat ")

func test_nmap_tidak_muncul_sebelum_apt_install() -> void:
	var s := _sesi()
	assert_eq(_teks(s, "nma"), "nma", "nmap belum dipasang, jadi tidak ditawarkan")
	assert_eq(_pilihan(s, "nma").size(), 0)
	assert_eq(_teks(s, "nmap -"), "nmap -", "argumen perintah yang belum tersedia tidak ditawarkan")

func test_nmap_muncul_setelah_apt_install() -> void:
	var s := _sesi()
	_pasang(s, "nmap")
	assert_eq(_teks(s, "nma"), "nmap ")

func test_wireshark_tidak_muncul_sebelum_dipasang() -> void:
	var s := _sesi()
	assert_eq(_teks(s, "wire"), "wire", "wireshark belum terpasang, jadi tidak ditawarkan")
	assert_eq(_pilihan(s, "wire").size(), 0)

func test_wireshark_muncul_setelah_dipasang() -> void:
	var s := _sesi()
	_pasang(s, "wireshark")
	assert_eq(_teks(s, "wire"), "wireshark ")

func test_netdiscover_tidak_muncul_sebelum_dipasang() -> void:
	var s := _sesi()
	assert_eq(_teks(s, "netd"), "netd")
	assert_false(_pilihan(s, "netd").has("netdiscover"))

func test_netdiscover_muncul_setelah_dipasang() -> void:
	var s := _sesi()
	_pasang(s, "netdiscover")
	assert_eq(_teks(s, "netd"), "netdiscover ")

func test_banyak_perintah_menampilkan_daftar_dan_awalan_bersama() -> void:
	var s := _sesi()
	var hasil := ShellComplete.lengkapi(s, "c")
	assert_eq(hasil["teks"], "c", "awalan bersama hanya c, teks tidak berubah")
	assert_eq(hasil["pilihan"].size(), 3, "cat, cd, clear ditampilkan")

func test_perintah_lama_dan_alat_tidak_ditawarkan() -> void:
	var s := _sesi()
	assert_false(_pilihan(s, "").has("security"), "security sudah diganti network-analyzer")
	assert_false(_pilihan(s, "").has("audit"), "audit sudah diganti password-auditor")
	assert_false(_pilihan(s, "").has("scan"), "scan dipindah ke aplikasi Alat")

func test_tanpa_kecocokan_teks_tidak_berubah() -> void:
	assert_eq(_teks(_sesi(), "xyzzy"), "xyzzy")

# 2. Opsi dan subperintah

func test_opsi_nmap_ditawarkan_hanya_yang_diimplementasikan() -> void:
	var s := _sesi()
	_pasang(s, "nmap")
	s.inventory.milik["network_scanner"] = {"tingkat": 2, "sumber": "uji"}
	var p := _pilihan(s, "nmap -")
	assert_true(p.has("-sn") and p.has("-p") and p.has("-sV") and p.has("-oN"))
	assert_false(p.has("-A"), "-A belum diimplementasikan")
	assert_false(p.has("-O"), "-O belum diimplementasikan")

func test_opsi_sv_nmap_butuh_network_scanner_tingkat_2() -> void:
	var s := _sesi()
	_pasang(s, "nmap")
	assert_false(_pilihan(s, "nmap -").has("-sV"), "tanpa Network Scanner, -sV tidak ditawarkan")
	assert_eq(_teks(s, "nmap -sV"), "nmap -sV", "-sV tidak ditawarkan tanpa tingkat yang cukup")
	s.inventory.milik["network_scanner"] = {"tingkat": 2, "sumber": "uji"}
	assert_true(_pilihan(s, "nmap -").has("-sV"), "dengan tingkat 2, -sV ditawarkan")

func test_opsi_nmap_melengkapi_saat_unik() -> void:
	var s := _sesi()
	_pasang(s, "nmap")
	assert_eq(_teks(s, "nmap -sn"), "nmap -sn ")

func test_opsi_nmap_berbagi_awalan_saat_ambigu() -> void:
	var s := _sesi()
	_pasang(s, "nmap")
	s.inventory.milik["network_scanner"] = {"tingkat": 2, "sumber": "uji"}
	assert_eq(_teks(s, "nmap -s"), "nmap -s", "-sn dan -sV sama-sama berawalan -s, tidak ada yang lebih panjang yang sama")
	assert_eq(_pilihan(s, "nmap -s").size(), 2)

func test_opsi_wireshark_ditawarkan() -> void:
	var p := _pilihan(_sesi_terpasang("wireshark"), "wireshark -")
	assert_true(p.has("-r") and p.has("-i") and p.has("--version"))

func test_subperintah_ip_ditawarkan() -> void:
	var s := _sesi()
	assert_eq(_pilihan(s, "ip "), ["addr", "route"])
	assert_eq(_teks(s, "ip a"), "ip addr ")
	assert_eq(_teks(s, "ip r"), "ip route ")

func test_subperintah_apt_ditawarkan() -> void:
	var p := _pilihan(_sesi(), "apt ")
	assert_true(p.has("install") and p.has("remove") and p.has("update"))

func test_apt_install_menawarkan_paket_yang_belum_terpasang() -> void:
	var s := _sesi()
	assert_eq(_teks(s, "apt install wires"), "apt install wireshark ", "wireshark ada di katalog dan belum terpasang")
	assert_eq(_teks(s, "apt install zzz"), "apt install zzz", "tidak ada paket yang cocok")
	assert_eq(_teks(s, "apt install netd"), "apt install netdiscover ")

func test_apt_remove_hanya_menawarkan_yang_terpasang() -> void:
	var s := _sesi()
	assert_eq(_teks(s, "apt remove netd"), "apt remove netd", "netdiscover belum terpasang")
	_pasang(s, "netdiscover")
	assert_eq(_teks(s, "apt remove netd"), "apt remove netdiscover ")

# 3. Jalur berkas dan direktori

func test_berkas_di_direktori_kerja() -> void:
	var s := _sesi()
	s.jalankan("cd dokumen")
	assert_eq(_teks(s, "cat jad"), "cat jadwal.txt ")

func test_direktori_menambah_garis_miring() -> void:
	assert_eq(_teks(_sesi(), "cd dok"), "cd dokumen/")

func test_jalur_bertingkat() -> void:
	assert_eq(_teks(_sesi(), "cat dokumen/ja"), "cat dokumen/jadwal.txt ")

func test_home_directory_tilde() -> void:
	assert_eq(_teks(_sesi(), "cat ~/dok"), "cat ~/dokumen/")

func test_cd_hanya_menawarkan_direktori() -> void:
	var s := _sesi()
	s.jalankan("cd dokumen")
	assert_eq(_teks(s, "cd jad"), "cd jad", "jadwal.txt bukan direktori")

func test_titik_tersembunyi_hanya_jika_diminta() -> void:
	assert_eq(_teks(_sesi(), "cat .ca"), "cat .catatan ")
	assert_eq(_teks(_sesi(), "ls ca"), "ls ca")

func test_direktori_tidak_ada_tidak_berubah() -> void:
	assert_eq(_teks(_sesi(), "cat tidakada/x"), "cat tidakada/x")

func test_direktori_kosong_tidak_berubah() -> void:
	var s := _sesi_kosong()
	assert_eq(_teks(s, "cat "), "cat ", "direktori kosong tidak punya kecocokan")
	assert_eq(_pilihan(s, "cat ").size(), 0)

func test_nama_dengan_spasi_dikutip() -> void:
	var s := _sesi()
	s.fs.tambah(s.home, "Laporan Dua.txt", {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r--r--", "isi": "x", "ukuran": 1})
	assert_eq(_teks(s, "cat Lap"), "cat \"Laporan Dua.txt\" ")

func test_nama_dengan_spasi_dilanjutkan_dari_kutip_terbuka() -> void:
	var s := _sesi()
	s.fs.tambah(s.home, "Laporan Dua.txt", {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r--r--", "isi": "x", "ukuran": 1})
	assert_eq(_teks(s, "cat \"Lap"), "cat \"Laporan Dua.txt\" ")

# 4. Sampel Wireshark di /usr/share (virtual)

func test_wireshark_jalur_usr_share() -> void:
	assert_eq(_teks(_sesi_terpasang("wireshark"), "wireshark -r /usr/sh"), "wireshark -r /usr/share/")

func test_wireshark_jalur_sampel_satu_kecocokan() -> void:
	assert_eq(_teks(_sesi_terpasang("wireshark"), "wireshark -r /usr/share/wireshark/samples/lab-je"), "wireshark -r /usr/share/wireshark/samples/lab-jejak-internal.simcap ")

func test_wireshark_jalur_sampel_banyak_kecocokan() -> void:
	var s := _sesi()
	_pasang(s, "wireshark")
	var p := _pilihan(s, "wireshark -r /usr/share/wireshark/samples/lab-")
	assert_eq(p.size(), 4, "empat contoh lab")
	assert_eq(_teks(s, "wireshark -r /usr/share/wireshark/samples/lab-"), "wireshark -r /usr/share/wireshark/samples/lab-", "awalan bersama tidak bertambah")

func test_tshark_juga_membaca_sampel() -> void:
	assert_eq(_teks(_sesi_terpasang("tshark"), "tshark -r /usr/share/wireshark/samples/lab-p"), "tshark -r /usr/share/wireshark/samples/lab-pindai-port.simcap ")

func test_perintah_lain_tidak_melihat_sampel() -> void:
	assert_eq(_teks(_sesi(), "cat /usr/sh"), "cat /usr/sh", "cat tidak membaca sampel virtual")

# 5. Tab tidak mengubah riwayat dan tidak menjalankan perintah

func test_lengkapi_tidak_mengubah_riwayat() -> void:
	var s := _sesi()
	s.jalankan("ls")
	var sebelum := s.riwayat.size()
	_teks(s, "cat ")
	_teks(s, "ca")
	_teks(s, "ip ")
	assert_eq(s.riwayat.size(), sebelum, "Tab tidak menambah riwayat")
