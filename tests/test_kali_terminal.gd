extends GutTest

const UA := preload("res://tests/uji_aplikasi.gd")

# Terminal Kali: perintah pemulih kata sandi (aircrack-ng, hashcat, john), wireshark,
# paket baru di katalog APT, Alat yang dijaga kepemilikan tool, dan migrasi flag dari save lama.

const KAMUS := "/usr/share/wordlists/rockyou.txt"

func before_each() -> void:
	Bahasa.kode = "en"

func _sesi_kosong() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

# Sesi dengan semua paket uji sudah terpasang (perintah paket hanya dikenali setelah dipasang).
func _sesi() -> ShellSession:
	var s := _sesi_kosong()
	s.economy.saldo = 5000
	_adapter(s)
	for pkg in ["aircrack-ng", "hashcat", "john", "wireshark"]:
		s.jalankan("apt install -y " + pkg)
	return s

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += String(b["teks"]) + "\n"
	return t

func _galat(hasil: Array) -> bool:
	return hasil.size() > 0 and String(hasil[0]["tipe"]) == "error"

func _adapter(s: ShellSession) -> void:
	UA.jalan(s, "__beli__usb_wireless_adapter")
	UA.jalan(s, "__beli__antena_eksternal")
	UA.jalan(s, "__beli__kabel_usb")
	UA.jalan(s, "__rakit__")

func _handshake(s: ShellSession) -> void:
	s.wifi.handshake["LAB-WIFI-01"] = true

# --- katalog APT ---

func test_katalog_berisi_paket_kali_baru() -> void:
	for id in ["aircrack-ng", "hashcat", "john", "wireshark", "network-analyzer", "password-auditor"]:
		assert_true(Repositori.item(id).size() > 0, "%s ada di katalog" % id)

func test_apt_install_paket_baru_tanpa_adapter() -> void:
	var s := _sesi_kosong()
	assert_true(_teks(s.jalankan("apt install -y john")).contains("Setting up john"))
	assert_true(s.repositori.punya("john"))
	assert_true(s.jaringan.progres.has("pasang:john"))

func test_apt_install_aircrack_memasang_dependensi() -> void:
	var s := _sesi_kosong()
	s.economy.saldo = 5000
	_adapter(s)
	var teks := _teks(s.jalankan("apt install -y aircrack-ng"))
	assert_true(teks.contains("Setting up aircrack-ng"))
	assert_true(s.repositori.punya("aircrack-ng"), "dependensi ikut terpasang")

func test_apt_show_dan_search_paket_baru() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("apt show hashcat")).contains("Package: hashcat"))
	assert_true(_teks(s.jalankan("apt search wireshark")).contains("wireshark"))

# --- aircrack-ng ---

func test_aircrack_butuh_opsi_wordlist() -> void:
	var s := _sesi()
	_handshake(s)
	assert_true(_galat(s.jalankan("aircrack-ng LAB-WIFI-01")))

func test_aircrack_wordlist_selain_kamus_lab_galat() -> void:
	var s := _sesi()
	_handshake(s)
	var teks := _teks(s.jalankan("aircrack-ng -w /tmp/lain.txt LAB-WIFI-01"))
	assert_true(teks.contains("Aircrack-ng 1.7"))
	assert_true(teks.contains("failed"), "wordlist di luar kamus lab ditolak dengan galat")

func test_aircrack_tanpa_handshake() -> void:
	var s := _sesi()
	assert_true(_teks(s.jalankan("aircrack-ng -w %s LAB-WIFI-01" % KAMUS)).contains("No valid WPA handshakes found"))

func test_aircrack_dengan_kamus_lab_menemukan_kunci_bila_ada_di_kamus() -> void:
	var s := _sesi()
	_handshake(s)
	var kata := s.wifi.kata_sandi("LAB-WIFI-01")
	var teks := _teks(s.jalankan("aircrack-ng -w %s LAB-WIFI-01" % KAMUS))
	if WifiLab.kamus().has(kata):
		assert_true(teks.contains("KEY FOUND! [ %s ]" % kata))
		assert_eq(String(s.wifi.kata_sandi_ditemukan.get("LAB-WIFI-01", "")), kata)
		assert_true(s.jaringan.progres.has("crack:aircrack-ng"))
	else:
		assert_true(teks.contains("Passphrase not in dictionary"))

# --- hashcat ---

func test_hashcat_butuh_mode_hash() -> void:
	var s := _sesi()
	_handshake(s)
	assert_true(_teks(s.jalankan("hashcat LAB-WIFI-01 %s" % KAMUS)).contains("Hash mode is not specified"))

func test_hashcat_dengan_mode_dan_kamus_lab() -> void:
	var s := _sesi()
	_handshake(s)
	var kata := s.wifi.kata_sandi("LAB-WIFI-01")
	var teks := _teks(s.jalankan("hashcat -m 2500 LAB-WIFI-01 %s" % KAMUS))
	assert_true(teks.contains("hashcat (v6.2.6) starting"))
	assert_true(teks.contains("Hash.Mode........: 2500"))
	if WifiLab.kamus().has(kata):
		assert_true(teks.contains("Status...........: Cracked"))
	else:
		assert_true(teks.contains("Status...........: Exhausted"))

func test_hashcat_kamus_bukan_lab_galat() -> void:
	var s := _sesi()
	_handshake(s)
	assert_true(_teks(s.jalankan("hashcat -m 2500 LAB-WIFI-01 /tmp/lain.txt")).contains("No such file or directory"))

# --- john ---

func test_john_butuh_wordlist() -> void:
	var s := _sesi()
	_handshake(s)
	assert_true(_galat(s.jalankan("john LAB-WIFI-01")))

func test_john_dengan_wordlist_lab() -> void:
	var s := _sesi()
	_handshake(s)
	var teks := _teks(s.jalankan("john --wordlist=%s LAB-WIFI-01" % KAMUS))
	assert_true(teks.contains("Loaded 1 password hash"))
	assert_true(teks.contains("DONE"))

# --- wireshark (aplikasi jendela, lihat test_wireshark.gd) ---

func test_wireshark_membuka_aplikasi_setelah_dipasang() -> void:
	var s := _sesi()
	s.jalankan("wireshark -r /usr/share/wireshark/samples/lab-jaringan-umum.simcap")
	assert_eq(s.permintaan_aplikasi, "wireshark")

# --- Alat: gerbang kepemilikan ---

func test_alat_trace_butuh_signal_tracer() -> void:
	var s := _sesi_kosong()
	assert_false(CommandRegistry.tersedia(s, "trace"))
	assert_true(_galat(AlatCommands.jalankan(s, "trace", ["gerbang"])))
	s.inventory.miliki("signal_tracer", "misi")
	assert_true(CommandRegistry.tersedia(s, "trace"))

func test_alat_scan_tanpa_tool_tetap_bisa() -> void:
	var s := _sesi_kosong()
	assert_false(_galat(AlatCommands.jalankan(s, "scan", ["10.7.0.8"])))

func test_alat_perintah_tidak_dikenal_galat() -> void:
	assert_true(_galat(AlatCommands.jalankan(_sesi(), "xyz", [])))

# --- migrasi flag save lama ---

func test_save_lama_flag_perintah_dipetakan_ke_nama_kali() -> void:
	var s := _sesi()
	var d := s.to_dict()
	d["jaringan"]["progres"] = ["cmd:device", "tools:list", "man:handshake", "man:hasil-handshake", "man:audit", "man:kesimpulan-audit", "cmd:security", "cmd:audit", "cmd:tools"]
	var pulih := ShellSession.dari_dict(d)
	var p: Array = pulih.jaringan.progres
	for f in ["cmd:lsusb", "apt:list", "man:aircrack-ng", "man:airodump-ng", "man:john", "man:network-analyzer", "cmd:network-analyzer", "cmd:password-auditor", "cmd:apt"]:
		assert_true(p.has(f), "%s ada setelah migrasi" % f)
	assert_false(p.has("cmd:device"), "flag lama hilang")
	var unik := {}
	for f in p:
		unik[f] = true
	assert_eq(unik.size(), p.size(), "tidak ada flag ganda")

func test_save_lama_tanpa_flag_perintah_tetap_terbaca() -> void:
	var s := _sesi_kosong()
	s.jaringan.buka("pasang:driver-ar9271")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_true(pulih.jaringan.progres.has("pasang:driver-ar9271"))

# --- kompatibilitas perintah lama ---

func test_perintah_lama_menunjuk_pengganti_dan_tidak_menjalankan_apa_pun() -> void:
	var s := _sesi()
	var teks := _teks(s.jalankan("device"))
	assert_true(_galat(s.jalankan("device")))
	assert_true(teks.contains("Gunakan 'lsusb'") or teks.contains("Use 'lsusb'"))
	var sebelum := s.repositori.terpasang.keys()
	assert_true(_teks(s.jalankan("tools install driver-ar9271")).contains("apt"))
	assert_eq(s.repositori.terpasang.keys().size(), sebelum.size(), "perintah lama tidak mengubah paket")

func test_perintah_lama_game_menunjuk_aplikasi() -> void:
	var s := _sesi()
	for nama in ["toko", "bm", "wallet", "scan", "trace"]:
		assert_true(_teks(s.jalankan(nama)).contains("aplikasi") or _teks(s.jalankan(nama)).contains("app"), nama)

func test_perintah_tidak_dikenal_tetap_tidak_ditemukan() -> void:
	assert_true(_teks(_sesi().jalankan("xyz-tidak-ada")).contains("command not found") or _teks(_sesi().jalankan("xyz-tidak-ada")).contains("perintah tidak ditemukan"))
