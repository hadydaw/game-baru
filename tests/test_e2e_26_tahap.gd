extends GutTest

# Tutorial Misi 1 dari awal sampai akhir: 26 tahap berurutan, muat ulang di setiap tahap, email tepat sekali.

const CMDS := [
	["help"], ["device list"], ["toko beli usb_wireless_adapter"], ["toko beli antena_eksternal"], ["toko beli kabel_usb"],
	["device rakit"], ["tools search driver"], ["tools install driver-ar9271"], ["device hubungkan"],
	["tools install airodump-ng"], ["airmon-ng start wlan0", "airodump-ng wlan0mon"], ["__netmgr__"], ["airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon"],
	["tools install network-analyzer"], ["security analyze LAB-WIFI-01"], ["man password-auditor"],
	["tools install password-auditor"], ["tools list"], ["man handshake"], ["audit auth LAB-WIFI-01"],
	["man hasil-handshake"], ["man audit"], ["audit run LAB-WIFI-01"], ["man kesimpulan-audit"],
	["security verify LAB-WIFI-01 senja1234"], ["security report LAB-WIFI-01"],
]

var log_galat: Array = []

func before_each() -> void:
	Bahasa.kode = "id"
	Penyimpanan.berkas_aktif = "user://e2e_tmp/filesystem.json"
	DirAccess.make_dir_recursive_absolute("user://e2e_tmp")
	DirAccess.remove_absolute("user://e2e_tmp/filesystem.json")
	DirAccess.remove_absolute("user://e2e_tmp/filesystem.json.bak")
	SesiUtama.reset()

func after_all() -> void:
	DirAccess.remove_absolute("user://e2e_tmp/filesystem.json")
	DirAccess.remove_absolute("user://e2e_tmp/filesystem.json.bak")
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	SesiUtama.reset()

func _email_tahap(s: ShellSession, n: int) -> int:
	var k := 0
	for p in s.pesan_misi:
		if int(p.get("tahap", 0)) == n:
			k += 1
	return k

func _jalan(s: ShellSession, c: String, tahap: int) -> void:
	if c == "__netmgr__":
		s.jaringan.buka("ui:netmgr")
		return
	for b in s.jalankan(c):
		if String(b.get("tipe", "")) == "error":
			log_galat.append("tahap %d | %s | %s" % [tahap, c, String(b.get("teks", ""))])

func test_e2e_26_tahap() -> void:
	var s: ShellSession = SesiUtama.ambil()
	assert_not_null(s, "sesi awal dibuat")
	var m := Misi.temukan("misi_1")
	assert_true(Misi.tersedia(s, m), "misi tutorial tersedia di awal")
	assert_true(Misi.terima(s, "misi_1"), "misi diterima lewat MENERIMA")
	assert_eq(_email_tahap(s, 1), 1, "email tahap 1 datang sekali setelah diterima")
	var salah := 0
	for n in range(1, 27):
		assert_eq(Misi.tahap_aktif(s, m), n, "aktif harus %d" % n)
		assert_false(Misi.tahap_bisa_dibaca(s, m, n + 1) if n + 1 <= 26 else false, "tahap %d tidak terbuka dini" % (n + 1))
		for c in CMDS[n - 1]:
			_jalan(s, c, n)
			Misi.perbarui(s)
		# Simpan lalu muat ulang dari disk, tanpa BELAJAR.
		assert_true(Penyimpanan.simpan_sesi(s), "simpan setelah tahap %d" % n)
		SesiUtama.reset()
		s = SesiUtama.ambil()
		m = Misi.temukan("misi_1")
		var harap := n + 1 if n + 1 <= 26 else 0
		if Misi.tahap_aktif(s, m) != harap:
			salah += 1
		assert_eq(Misi.tahap_aktif(s, m), harap, "setelah tugas tahap %d dan muat ulang, aktif = %d" % [n, harap])
		if n < 26:
			assert_eq(_email_tahap(s, n + 1), 1, "email tahap %d datang tepat sekali" % (n + 1))
		assert_eq(_email_tahap(s, n), 1, "email tahap %d tidak berulang" % n)
		# Opsional: BELAJAR tahap yang sudah terbuka boleh dibuka dan tidak mengubah progres.
		if n < 26:
			assert_true(Misi.tandai_baca(s, "misi_1", n + 1), "materi tahap %d bisa dibuka" % (n + 1))
			assert_eq(Misi.tahap_aktif(s, m), harap, "membuka materi tidak mengubah progres")
	assert_eq(log_galat.size(), 0, "tidak ada galat Terminal pada perintah tutorial: %s" % str(log_galat))
	assert_eq(salah, 0, "tidak ada tahap yang salah urutan setelah muat ulang")
	# Tahap 26 punya tugas laporan: misi selesai setelah laporan dibuat.
	assert_eq(String(s.misi.get("misi_1", "")), "selesai", "misi selesai")
	assert_true(s.hadiah_diambil.has("misi_1"), "hadiah diberikan sekali")
	assert_eq(_email_tahap(s, 26), 1, "email tahap 26 datang")
	# Setelah semua muat ulang: software terpasang, perintah tetap berfungsi, dan status tahap tetap benar.
	assert_true(s.repositori.punya("airodump-ng"), "airodump-ng tetap terpasang setelah muat ulang")
	assert_true(s.repositori.punya("network-analyzer"), "network-analyzer tetap terpasang")
	assert_true(s.repositori.punya("password-auditor"), "password-auditor tetap terpasang")
	var hasil_airodump := s.jalankan("airodump-ng wlan0mon")
	assert_eq(String(hasil_airodump[0].get("tipe", "")) == "error", false, "airodump-ng tetap bisa dipakai setelah muat ulang")
	assert_eq(String(s.misi.get("misi_1", "")), "selesai", "status misi tetap selesai setelah muat ulang")
	var urut := []
	for p in s.pesan_misi:
		urut.append(int(p.get("tahap", 0)))
	assert_eq(urut.size(), 28, "28 email tutorial: pesan awal, 26 tahap, dan pesan selesai")
