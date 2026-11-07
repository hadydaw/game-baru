extends GutTest

# Wireshark: data simulasi, filter tampilan, statistik, model sesi, perintah wireshark dan tshark,
# serta integrasi katalog APT. Semua paket di sini berasal dari data simulasi lab.

func before_each() -> void:
	Bahasa.kode = "en"

func _sesi() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	s.economy.saldo = 5000
	return s

func _sesi_terpasang() -> ShellSession:
	var s := _sesi()
	s.jalankan("apt install -y wireshark")
	s.jalankan("apt install -y tshark")
	return s

func _teks(hasil: Array) -> String:
	var t := ""
	for b in hasil:
		t += String(b["teks"]) + "\n"
	return t

# Checksum Internet (RFC 1071) untuk menguji header IPv4: hasil 0 berarti header valid.
func _csum(data: PackedByteArray) -> int:
	var jumlah := 0
	var i := 0
	while i + 1 < data.size():
		jumlah += (data[i] << 8) | data[i + 1]
		i += 2
	if i < data.size():
		jumlah += data[i] << 8
	while jumlah >> 16:
		jumlah = (jumlah & 0xffff) + (jumlah >> 16)
	return (~jumlah) & 0xffff

func _paket(id: String) -> Array:
	return WiresharkData.muat_contoh(id)["paket"]

func _cocok(paket: Array, filter: String) -> int:
	var n := 0
	for p in paket:
		if WiresharkFilter.lolos(filter, p):
			n += 1
	return n

const LAN := "lab-jaringan-umum"
const WIFI := "lab-wifi-01-handshake"
const PINDAI := "lab-pindai-port"
const CONTOH_LAN := "/usr/share/wireshark/samples/lab-jaringan-umum.simcap"

# --- data simulasi ---

func test_data_tiga_skenario_ada_dan_konsisten() -> void:
	assert_eq(_paket(LAN).size(), 15)
	assert_eq(_paket(WIFI).size(), 16)
	assert_eq(_paket(PINDAI).size(), 16)

func test_data_hex_sesuai_panjang_dan_rincian_berada_dalam_frame() -> void:
	for id in WiresharkData.CONTOH:
		for p in _paket(String(id)):
			var raw := WiresharkData.hex_ke_byte(String(p["hex"]))
			assert_eq(raw.size(), int(p["panjang"]), "panjang %s #%d" % [id, int(p["no"])])
			for lap in p["rincian"]:
				assert_true(int(lap["mulai"]) + int(lap["panjang"]) <= raw.size(), "lapisan di luar frame %s #%d" % [id, int(p["no"])])
				for b in lap["bidang"]:
					assert_true(int(b["mulai"]) + int(b["panjang"]) <= raw.size(), "bidang di luar frame %s #%d" % [id, int(p["no"])])

func test_data_checksum_ipv4_valid() -> void:
	for id in WiresharkData.CONTOH:
		for p in _paket(String(id)):
			for lap in p["rincian"]:
				if not String(lap["judul"]).begins_with("Internet Protocol"):
					continue
				var raw := WiresharkData.hex_ke_byte(String(p["hex"]))
				var hdr := raw.slice(int(lap["mulai"]), int(lap["mulai"]) + 20)
				assert_eq(_csum(hdr), 0, "checksum IPv4 %s #%d" % [id, int(p["no"])])

func test_simpan_lalu_urai_mempertahankan_paket() -> void:
	var teks := WiresharkData.teks_simpan("uji", "eth0", _paket(LAN))
	var r := WiresharkData.urai(teks)
	assert_true(bool(r["ok"]))
	assert_eq(r["paket"].size(), 15)
	assert_eq(r["antarmuka"], "eth0")

func test_urai_menolak_berkas_rusak() -> void:
	assert_false(bool(WiresharkData.urai("bukan json")["ok"]))
	assert_false(bool(WiresharkData.urai("{\"format\": \"lain\", \"paket\": []}")["ok"]))

# --- filter tampilan ---

func test_filter_protokol_dan_port() -> void:
	var lan := _paket(LAN)
	assert_eq(_cocok(lan, "http"), 3)
	assert_eq(_cocok(lan, "dns"), 2)
	assert_eq(_cocok(lan, "icmp"), 4)
	assert_eq(_cocok(lan, "arp"), 2)
	assert_eq(_cocok(lan, "tcp.port == 80"), 7)
	assert_eq(_cocok(lan, "ip.addr == 10.7.0.80"), 7)

func test_filter_kata_kunci_dan_frame_contains() -> void:
	assert_eq(_cocok(_paket(LAN), "http.request.method == \"POST\""), 1)
	assert_eq(_cocok(_paket(LAN), "frame contains \"senja1234\""), 1)
	# Respons HTTP tidak membawa header Host, jadi hanya GET dan POST yang cocok.
	assert_eq(_cocok(_paket(LAN), "http.host == \"portal.lab.jtn.test\""), 2)

func test_filter_gabungan_and_or_not() -> void:
	var lan := _paket(LAN)
	assert_eq(_cocok(lan, "tcp and not http"), 4)
	assert_eq(_cocok(lan, "dns or arp"), 4)
	assert_eq(_cocok(lan, "(dns or arp) and not dns"), 2)
	assert_eq(_cocok(lan, "!icmp && ip"), _cocok(lan, "ip and not icmp"))

func test_filter_flag_tcp_pada_pindai_port() -> void:
	var pindai := _paket(PINDAI)
	assert_eq(_cocok(pindai, "tcp.flags.syn == 1 and tcp.flags.ack == 0"), 7)
	assert_eq(_cocok(pindai, "tcp.flags.rst == 1"), 7)
	assert_eq(_cocok(pindai, "tcp.port == 22 or tcp.port == 80"), 6)

func test_filter_wifi_eapol_dan_ssid() -> void:
	var wifi := _paket(WIFI)
	assert_eq(_cocok(wifi, "eapol"), 4)
	assert_eq(_cocok(wifi, "eapol.msg == 4"), 1)
	assert_eq(_cocok(wifi, "wlan.ssid == \"LAB-WIFI-01\""), 5)

func test_filter_perbandingan_numerik() -> void:
	assert_eq(_cocok(_paket(LAN), "frame.len > 1000"), 0)
	assert_true(_cocok(_paket(LAN), "frame.len > 60") > 0)

func test_filter_kesalahan_jelas() -> void:
	assert_true(String(WiresharkFilter.parse("tcp.port ==")["pesan"]).contains("tcp.port"))
	assert_false(WiresharkFilter.parse("tidakada").ok)
	assert_true(String(WiresharkFilter.parse("tidakada")["pesan"]).contains("tidakada"))
	assert_false(WiresharkFilter.parse("tcp.port ==").ok)
	assert_false(WiresharkFilter.parse("(tcp").ok)
	assert_false(WiresharkFilter.parse("tcp )").ok)
	assert_false(WiresharkFilter.parse("").ok)

# --- statistik ---

func test_statistik_ringkasan_dan_hierarki() -> void:
	var lan := _paket(LAN)
	var r := WiresharkStats.ringkasan(lan)
	assert_eq(int(r["paket"]), 15)
	assert_true(int(r["bytes"]) > 0)
	var h := WiresharkStats.hierarki(lan)
	assert_eq(String(h[0]["nama"]), "frame")
	assert_eq(int(h[0]["paket"]), 15)
	var http := h.filter(func(b): return b["nama"] == "http")
	assert_eq(int(http[0]["paket"]), 3)

func test_statistik_percakapan_teratas_adalah_klien_ke_portal() -> void:
	var k := WiresharkStats.percakapan(_paket(LAN))
	assert_eq(String(k[0]["a"]), "10.7.0.8")
	assert_eq(String(k[0]["b"]), "10.7.0.80")
	assert_eq(int(k[0]["paket"]), 7)

# --- model sesi ---

func test_model_tangkap_memutar_skenario_satu_per_satu() -> void:
	var m := WiresharkModel.new()
	m.mulai_tangkap("eth0", _paket(LAN))
	assert_true(m.menangkap)
	var n := 0
	while m.tangkap_satu():
		n += 1
	assert_eq(n, 15)
	assert_false(m.menangkap)
	assert_eq(m.paket.size(), 15)

func test_model_filter_membatasi_tampil_dan_galat_tidak_mengubah_tampil() -> void:
	var m := WiresharkModel.new()
	m.muat_berkas({"paket": _paket(LAN), "antarmuka": "eth0"}, "uji")
	assert_eq(m.tampil.size(), 15)
	assert_eq(m.terapkan_filter("dns").length(), 0)
	assert_eq(m.tampil.size(), 2)
	assert_true(m.terapkan_filter("tidakada").length() > 0)
	assert_eq(m.tampil.size(), 15, "filter yang galat menampilkan semua paket")

func test_model_antarmuka_wlan0mon_hanya_setelah_monitor() -> void:
	assert_eq(WiresharkModel.antarmuka_tersedia("").size(), 1)
	assert_true(WiresharkModel.antarmuka_tersedia("wlan0mon").has("wlan0mon"))
	assert_eq(WiresharkModel.skenario_untuk("wlan0mon", ""), "")
	assert_eq(WiresharkModel.skenario_untuk("wlan0mon", "wlan0mon"), WIFI)

# --- perintah wireshark dan tshark ---

func test_tshark_tanpa_paket_terpasang_tidak_ditemukan() -> void:
	var s := _sesi()
	assert_false(_teks(s.jalankan("tshark -v")).contains("4.6.5"))
	assert_false(_teks(s.jalankan("tshark -r %s" % CONTOH_LAN)).contains("ARP"))

func test_tshark_membaca_berkas_contoh_dengan_batas() -> void:
	var s := _sesi_terpasang()
	var teks := _teks(s.jalankan("tshark -r %s -c 3" % CONTOH_LAN))
	var baris := teks.split("\n", false)
	assert_eq(baris.size(), 3)
	assert_true(teks.contains("ARP"))

func test_tshark_filter_dan_statistik() -> void:
	var s := _sesi_terpasang()
	var teks := _teks(s.jalankan("tshark -r %s -Y 'http'" % CONTOH_LAN))
	assert_eq(teks.split("\n", false).size(), 3)
	var statistik := _teks(s.jalankan("tshark -r %s -q -z io,phs" % CONTOH_LAN))
	assert_true(statistik.contains("Protocol Hierarchy Statistics"))
	assert_true(statistik.contains("frames:15"))
	var percakapan := _teks(s.jalankan("tshark -r %s -q -z conv,ip" % CONTOH_LAN))
	assert_true(percakapan.contains("10.7.0.80"))

func test_tshark_filter_salah_menampilkan_galat() -> void:
	var s := _sesi_terpasang()
	assert_true(_teks(s.jalankan("tshark -r %s -Y 'tcp.port =='" % CONTOH_LAN)).contains("tshark:"))

func test_tshark_berkas_tidak_ada_dan_rusak() -> void:
	var s := _sesi_terpasang()
	assert_true(_teks(s.jalankan("tshark -r /tidak/ada.simcap")).contains("No such file"))
	s.tulis_berkas("/home/operator/rusak.simcap", "bukan json")
	assert_true(_teks(s.jalankan("tshark -r rusak.simcap")).contains("tshark:"))

func test_tshark_tangkap_eth0_dan_wlan0mon_butuh_monitor() -> void:
	var s := _sesi_terpasang()
	var hasil := _teks(s.jalankan("tshark -i eth0 -c 2"))
	assert_true(hasil.contains("Capturing on 'eth0'"))
	assert_true(hasil.contains("2 packets captured"))
	assert_true(_teks(s.jalankan("tshark -i wlan0mon -c 2")).contains("No such device"))
	s.wifi.monitor = "wlan0mon"
	assert_true(_teks(s.jalankan("tshark -i wlan0mon -c 2")).contains("2 packets captured"))

func test_tshark_daftar_antarmuka() -> void:
	var s := _sesi_terpasang()
	assert_true(_teks(s.jalankan("tshark -D")).contains("1. eth0"))

func test_wireshark_buka_berkas_contoh_menyiapkan_aplikasi() -> void:
	var s := _sesi_terpasang()
	var hasil := s.jalankan("wireshark -r %s" % CONTOH_LAN)
	assert_eq(hasil.size(), 0)
	assert_eq(s.permintaan_aplikasi, "wireshark")
	assert_eq(s.wireshark_perintah["paket"].size(), 15)

func test_wireshark_berkas_rusak_dan_tidak_ada() -> void:
	var s := _sesi_terpasang()
	assert_true(_teks(s.jalankan("wireshark -r /tidak/ada.simcap")).contains("No such file"))
	assert_eq(s.permintaan_aplikasi, "")
	s.tulis_berkas("/home/operator/rusak.simcap", "bukan json")
	assert_true(_teks(s.jalankan("wireshark -r rusak.simcap")).contains("damaged or corrupt"))
	assert_eq(s.permintaan_aplikasi, "")

func test_wireshark_berkas_di_rumah_dibaca() -> void:
	var s := _sesi_terpasang()
	s.tulis_berkas("/home/operator/hasil.simcap", WiresharkData.teks_simpan("hasil", "eth0", _paket(LAN)))
	s.jalankan("wireshark -r hasil.simcap")
	assert_eq(s.permintaan_aplikasi, "wireshark")
	assert_eq(s.wireshark_perintah["paket"].size(), 15)

func test_wireshark_tangkap_dan_versi() -> void:
	var s := _sesi_terpasang()
	assert_true(_teks(s.jalankan("wireshark -i wlan0mon")).contains("No such device"))
	s.jalankan("wireshark -i eth0")
	assert_eq(s.wireshark_perintah["tangkap"], "eth0")
	assert_true(_teks(s.jalankan("wireshark -v")).contains("4.6.4"))

func test_wireshark_dan_tshark_terpasang_lewat_katalog_apt() -> void:
	var s := _sesi()
	s.jalankan("apt install -y wireshark")
	assert_true(s.repositori.punya("wireshark"))
	assert_false(s.repositori.punya("tshark"))
	assert_eq(s.repositori.versi("wireshark"), "4.6.4", "versi terpasang = versi_awal katalog")
	s.jalankan("apt install -y tshark")
	assert_true(s.repositori.punya("tshark"))
	assert_eq(s.repositori.versi("tshark"), "4.6.4")
	assert_true(_teks(s.jalankan("wireshark -v")).contains("4.6.4"))
	assert_true(_teks(s.jalankan("tshark -v")).contains("4.6.4"))
	assert_eq(int(Repositori.item("tshark")["harga"]), 60)
