extends GutTest

const UA := preload("res://tests/uji_aplikasi.gd")

# Tahap 4: Tutorial Misi 1 dari awal sampai akhir, hanya lewat Terminal, Pasar, Device Manager,
# dan Tools Repository. Setiap tahap memberi umpan balik sekali, hadiah diberikan sekali, dan
# progres bertahan saat disimpan.

func _sesi() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	s.wifi.kunci_seed = 0  # kata sandi acak; 0 = kandidat pertama (senja1234)
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	return s

func _jalan(s: ShellSession, perintah: String) -> Array:
	var hasil := UA.jalan(s, perintah)
	_baca_tahap_aktif(s)
	return hasil

# Pemain membaca materi tahap yang sedang aktif (tombol KEMBALI), lalu menyelesaikan tugasnya.
func _baca_tahap_aktif(s: ShellSession) -> void:
	var m := Misi.temukan("misi_1")
	var n := Misi.tahap_aktif(s, m)
	while n > 0 and not s.jaringan.progres.has(Misi.baca_flag("misi_1", n)):
		if not Misi.tandai_baca(s, "misi_1", n):
			break
		n = Misi.tahap_aktif(s, m)

func _galat(hasil: Array) -> bool:
	return hasil.size() > 0 and String(hasil[0]["tipe"]) == "error"

func before_each() -> void:
	Bahasa.kode = "id"

func test_misi_diterima_saat_mulai_tanpa_alat() -> void:
	var s := _sesi()
	assert_eq(String(s.misi.get("misi_1", "")), "aktif")
	assert_eq(s.inventory.milik.size(), 0)
	assert_eq(s.perangkat.komponen.size(), 0)
	assert_eq(s.repositori.terpasang.size(), 0)

func test_tahap_terdefinisi_dan_berurutan() -> void:
	var m := Misi.temukan("misi_1")
	assert_eq(m["tahap"].size(), 26, "tutorial dipecah menjadi langkah kecil")
	assert_eq(Misi.tahap_progres(_sesi(), m).size(), 26)
	assert_eq(Bahasa.pilih(String(m["tahap"][0]["judul"])), "Tahap 1: Membuka Daftar Perintah", "judul tahap pertama")

func test_alur_lengkap_sampai_hadiah() -> void:
	var s := _sesi()
	# Tahap 1: terminal
	_jalan(s, "help")
	_jalan(s, "lsusb")
	# Tahap 2: hardware dari Pasar atau toko
	_jalan(s, "__beli__usb_wireless_adapter")
	_jalan(s, "__beli__antena_eksternal")
	_jalan(s, "__beli__kabel_usb")
	# Tahap 3: rakit
	assert_false(_galat(_jalan(s, "__rakit__")))
	# Tahap 4: driver dan koneksi
	_jalan(s, "apt search driver")
	assert_false(_galat(_jalan(s, "apt install -y driver-ar9271")))
	assert_false(_galat(_jalan(s, "__hubungkan__")))
	# Tahap 5-6: software dan pemindaian
	_jalan(s, "apt install -y aircrack-ng")
	_jalan(s, "airmon-ng start wlan0")
	assert_false(_galat(_jalan(s, "airodump-ng wlan0mon")))
	s.jaringan.buka("ui:netmgr")
	Misi.perbarui(s)
	# Tahap 7: analisis
	_jalan(s, "apt install -y network-analyzer")
	_jalan(s, "airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon")
	_jalan(s, "network-analyzer analyze LAB-WIFI-01")
	# Tahap 8: pengujian keamanan
	_jalan(s, "man password-auditor")
	_jalan(s, "apt install -y password-auditor")
	_jalan(s, "apt list --installed")
	_jalan(s, "man aircrack-ng")
	_jalan(s, "password-auditor auth LAB-WIFI-01")
	_jalan(s, "man airodump-ng")
	_jalan(s, "man john")
	_jalan(s, "password-auditor run LAB-WIFI-01")
	_jalan(s, "man network-analyzer")
	# Tahap 9: verifikasi akses
	assert_false(_galat(_jalan(s, "network-analyzer verify LAB-WIFI-01 senja1234")))
	# Tahap 26: laporan temuan menyelesaikan misi
	assert_eq(String(s.misi["misi_1"]), "aktif", "belum selesai sebelum laporan")
	_jalan(s, "network-analyzer report LAB-WIFI-01")
	assert_eq(String(s.misi["misi_1"]), "selesai")
	assert_eq(s.xp, 100)
	assert_eq(s.perangkat.jumlah("wifi_hacking_kit"), 1)
	assert_eq(s.perangkat.antena(), 2, "Wi-Fi Hacking Kit menaikkan antena")
	assert_eq(s.economy.saldo, 500 - 110 - 60 - 15 - 60 - 120 - 130 + 150, "hadiah kredit masuk sekali")
	assert_true(s.hadiah_diambil.has("misi_1"))

func test_umpan_balik_tahap_sekali_per_tahap() -> void:
	var s := _sesi()
	_jalan(s, "help")
	_jalan(s, "lsusb")
	var judul := []
	for p in s.pesan_misi:
		judul.append(Bahasa.pilih(String(p["subjek"])))
	assert_true(judul.has("Tahap 1: Membuka Daftar Perintah"))
	var n := s.pesan_misi.size()
	_jalan(s, "lsusb")
	assert_eq(s.pesan_misi.size(), n, "tidak diulang")

func test_hadiah_tidak_ganda_setelah_dimuat_ulang() -> void:
	var s := _sesi()
	_jalan(s, "help")
	_jalan(s, "lsusb")
	_jalan(s, "__beli__usb_wireless_adapter")
	_jalan(s, "__beli__antena_eksternal")
	_jalan(s, "__beli__kabel_usb")
	_jalan(s, "__rakit__")
	_jalan(s, "apt search driver")
	_jalan(s, "apt install -y driver-ar9271")
	_jalan(s, "__hubungkan__")
	_jalan(s, "apt install -y aircrack-ng")
	_jalan(s, "airmon-ng start wlan0")
	_jalan(s, "airodump-ng wlan0mon")
	s.jaringan.buka("ui:netmgr")
	Misi.perbarui(s)
	_jalan(s, "apt install -y network-analyzer")
	_jalan(s, "airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon")
	_jalan(s, "network-analyzer analyze LAB-WIFI-01")
	_jalan(s, "man password-auditor")
	_jalan(s, "apt install -y password-auditor")
	_jalan(s, "apt list --installed")
	_jalan(s, "man aircrack-ng")
	_jalan(s, "password-auditor auth LAB-WIFI-01")
	_jalan(s, "man airodump-ng")
	_jalan(s, "man john")
	_jalan(s, "password-auditor run LAB-WIFI-01")
	_jalan(s, "man network-analyzer")
	_jalan(s, "network-analyzer verify LAB-WIFI-01 senja1234")
	_jalan(s, "network-analyzer report LAB-WIFI-01")
	assert_eq(String(s.misi["misi_1"]), "selesai")
	var saldo := s.economy.saldo
	var pulih := ShellSession.dari_dict(s.to_dict())
	Misi.perbarui(pulih)
	Misi.perbarui(pulih)
	assert_eq(pulih.economy.saldo, saldo, "hadiah tidak diberikan dua kali")
	assert_eq(pulih.xp, 100)
	assert_eq(pulih.perangkat.jumlah("wifi_hacking_kit"), 1)
	assert_eq(pulih.hadiah_diambil.count("misi_1"), 1)

func test_progres_tahap_bertahan_setelah_disimpan() -> void:
	var s := _sesi()
	_jalan(s, "help")
	_jalan(s, "lsusb")
	var pulih := ShellSession.dari_dict(s.to_dict())
	var progres := Misi.tahap_progres(pulih, Misi.temukan("misi_1"))
	assert_true(bool(progres[0]["selesai"]), "tahap 1 tetap selesai")
	assert_true(bool(progres[1]["selesai"]), "tahap 2 selesai dengan device list")
	assert_false(bool(progres[2]["selesai"]))

func test_pusat_misi_menampilkan_semua_tahap() -> void:
	SesiUtama.sesi = _sesi()
	var p := PusatMisi.new()
	add_child_autofree(p)
	p._pilih_kategori("tutorial")
	p._tampil_daftar = "tutorial"
	p._misi_terpilih = "misi_1"
	p._rincian = true
	p._segarkan_semua()
	assert_true(p._isi_deskripsi.get_child_count() > 10)

func test_flag_misi_selesai_dibuka_setelah_tutorial_1() -> void:
	var s := _sesi()
	assert_false(s.jaringan.progres.has("misi_selesai:misi_1"), "belum selesai")
	s.misi["misi_1"] = "selesai"
	Misi.perbarui(s)
	assert_true(s.jaringan.progres.has("misi_selesai:misi_1"), "flag terbuka setelah selesai")
	assert_eq(Misi.flag_selesai("misi_1"), "misi_selesai:misi_1")
