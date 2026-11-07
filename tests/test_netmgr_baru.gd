extends GutTest

# Network Manager baru: riwayat pemindaian, status antarmuka, dan layar tanpa checklist.

var _nm: NetworkManager

func before_each() -> void:
	Bahasa.kode = "id"

func after_each() -> void:
	if _nm != null:
		remove_child(_nm)
		_nm.free()
		_nm = null
	SesiUtama.sesi = null

func _sesi_terpasang() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	for c in ["toko beli usb_wireless_adapter", "toko beli antena_eksternal", "toko beli kabel_usb", "device rakit", "tools install driver-ar9271", "device hubungkan", "tools install airodump-ng", "tools install network-analyzer", "tools install password-auditor"]:
		s.jalankan(c)
	return s

func test_scan_mencatat_riwayat() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	assert_eq(s.wifi.riwayat.size(), 1, "satu pemindaian tercatat")
	var e: Dictionary = s.wifi.riwayat[0]
	assert_eq(int(e["jumlah"]), 3, "tiga jaringan tercatat")
	assert_eq(String(e["perangkat"]), "usb_wireless_adapter", "perangkat yang dipakai tercatat")
	assert_true(String(s.wifi.waktu_lihat["LAB-WIFI-01"]) != "", "waktu terakhir terlihat tercatat")

func test_pilih_dan_analisis_tercatat_di_riwayat() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	s.jalankan("airodump-ng --bssid 02:4A:1C:00:02:02 wlan0mon")
	s.jalankan("security analyze LAB-WIFI-02")
	var e: Dictionary = s.wifi.riwayat[0]
	assert_eq(String(e["dipilih"]), "LAB-WIFI-02", "jaringan yang dipilih tercatat")
	assert_eq(String(e["analisis"]["LAB-WIFI-02"]), "tinggi", "tingkat risiko hasil analisis tercatat")

func test_riwayat_tetap_ada_setelah_dimuat_ulang() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	s.jalankan("airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon")
	var dimuat := ShellSession.dari_dict(s.to_dict())
	assert_eq(dimuat.wifi.riwayat.size(), 2, "riwayat ikut tersimpan")
	assert_eq(String(dimuat.wifi.riwayat[0]["dipilih"]), "LAB-WIFI-01", "pilihan ikut tersimpan")
	assert_eq(dimuat.wifi.ditemukan.size(), 3, "hasil pemindaian ikut tersimpan")

func test_status_perangkat_berurutan() -> void:
	var p := Perangkat.new()
	assert_eq(p.status(), "tidak_terdeteksi", "belum dirakit")
	var s := _sesi_terpasang()
	assert_eq(s.perangkat.status(), "aktif", "terhubung dan ber-driver")
	s.perangkat.putuskan()
	assert_eq(s.perangkat.status(), "terputus", "terputus tetapi driver ada")
	s.perangkat.rakitan["driver"] = ""
	assert_eq(s.perangkat.status(), "kesalahan", "tanpa driver berarti kesalahan")

func test_layar_tidak_memuat_checklist_tahap() -> void:
	var s := _sesi_terpasang()
	SesiUtama.sesi = s
	_nm = NetworkManager.new()
	add_child(_nm)
	var teks := _kumpulkan_teks(_nm)
	assert_false(teks.contains("Deteksi perangkat"), "tidak ada checklist tahap")
	assert_false(teks.contains("Tahap pengujian"), "tidak ada judul checklist")
	assert_false(teks.contains("[ ]"), "tidak ada kotak centang")

func test_layar_menampilkan_jaringan_hasil_scan() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	SesiUtama.sesi = s
	_nm = NetworkManager.new()
	add_child(_nm)
	_nm._pilih_tab("pindai")
	# Setelah pemindaian dari Terminal, layar menampilkan jaringan secara bertahap; saat ini semua sudah tampil.
	_nm._memindai = false
	_nm._reveal_n = 3
	_nm._bangun_tab()
	var teks := _kumpulkan_teks(_nm)
	assert_true(teks.contains("LAB-WIFI-01"), "LAB-WIFI-01 tampil")
	assert_true(teks.contains("LAB-WIFI-03"), "LAB-WIFI-03 tampil")

func _kumpulkan_teks(node: Node) -> String:
	var hasil := ""
	for c in node.get_children():
		if c is Label:
			hasil += (c as Label).text + "\n"
		hasil += _kumpulkan_teks(c)
	return hasil

func test_pemindaian_dari_terminal_langsung_tampil_di_network_manager() -> void:
	var s := _sesi_terpasang()
	SesiUtama.sesi = s
	_nm = NetworkManager.new()
	add_child(_nm)
	assert_false(_nm._memindai, "belum ada pemindaian saat layar dibuka")
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	_nm._periksa()
	assert_true(_nm._memindai, "pemindaian dari Terminal memicu tampilan bertahap")
	_nm._reveal_n = 3
	_nm._selesai_reveal()
	assert_false(_nm._memindai, "tampilan selesai setelah semua jaringan tampil")

# Setiap kontrol di dalam daftar gulir harus meneruskan sentuhan geser, supaya layar bisa digulir.
func test_semua_tab_meneruskan_sentuhan_geser() -> void:
	var s := _sesi_terpasang()
	s.jalankan("airmon-ng start wlan0")
	s.jalankan("airodump-ng wlan0mon")
	s.jalankan("airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon")
	s.jalankan("security analyze LAB-WIFI-01")
	SesiUtama.sesi = s
	_nm = NetworkManager.new()
	add_child(_nm)
	for t in ["antarmuka", "pindai", "detail", "analisis", "riwayat"]:
		_nm._pilih_tab(t)
		var menghalangi := _cari_penghalang(_nm._isi)
		assert_true(menghalangi.is_empty(), "tab %s: tidak ada kontrol yang menelan geseran: %s" % [t, str(menghalangi)])

func _cari_penghalang(node: Node) -> Array:
	var hasil: Array = []
	for c in node.get_children():
		if c is Control and (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			hasil.append(c.get_class())
		hasil.append_array(_cari_penghalang(c))
	return hasil
