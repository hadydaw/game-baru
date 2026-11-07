extends GutTest

# Simpanan lama memakai "wifi-scanner". Setelah dimuat, pemasangan, progres misi, dan teks email
# harus memakai airodump-ng, dan progres pemain tidak hilang.

func _siap_terpasang() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	for c in ["toko beli usb_wireless_adapter", "toko beli antena_eksternal", "toko beli kabel_usb", "device rakit", "tools install driver-ar9271", "device hubungkan", "tools install airodump-ng"]:
		s.jalankan(c)
	return s

func test_simpanan_wifi_scanner_dimigrasi() -> void:
	var s := _siap_terpasang()
	var d := s.to_dict()
	# Ubah ke bentuk simpanan lama.
	var terpasang: Dictionary = d["repositori"]["terpasang"]
	terpasang["wifi-scanner"] = terpasang["airodump-ng"]
	terpasang.erase("airodump-ng")
	d["jaringan"]["progres"] = Array(d["jaringan"]["progres"]) + ["pasang:wifi-scanner", "wifi:pilih:LAB-WIFI-01"]
	d["pesan_misi"] = [
		{"id": "misi:10", "tahap": 10, "isi": "Pasang Wireless Scanner dari Tools Repository: 'tools install wifi-scanner'.", "judul": "Tahap 10: Memasang Wireless Scanner"},
		{"id": "misi:11", "tahap": 11, "isi": "Jalankan 'wifi-scanner --scan' untuk melihat jaringan di sekitarmu. — Agensi", "judul": "Tahap 11"},
	]
	var dimuat := ShellSession.dari_dict(d)
	assert_true(dimuat.repositori.punya("airodump-ng"), "airodump-ng terpasang dari simpanan lama")
	assert_false(dimuat.repositori.punya("wifi-scanner"), "nama lama tidak tersisa")
	assert_true(dimuat.jaringan.progres.has("pasang:airodump-ng"), "flag pemasangan diganti")
	assert_false(dimuat.jaringan.progres.has("pasang:wifi-scanner"), "flag lama tidak tersisa")
	assert_true(dimuat.jaringan.progres.has("wifi:pilih:LAB-WIFI-01"), "progres lain tetap")
	var isi := String(dimuat.pesan_misi[0]["isi"])
	assert_false(isi.contains("wifi-scanner"), "teks email lama diganti")
	assert_true(isi.contains("airodump-ng"), "teks email memakai airodump-ng")
	var isi11 := String(dimuat.pesan_misi[1]["isi"])
	assert_true(isi11.contains("airmon-ng start wlan0"), "email tahap 11 menyebut monitor mode")
	dimuat.jalankan("airmon-ng start wlan0")
	assert_eq(String(dimuat.jalankan("airodump-ng wlan0mon")[0].get("tipe", "")) == "error", false, "perintah baru bisa dipakai")
