extends GutTest

# Urutan 26 tahap Tutorial Misi 1: tahap berjalan berurutan. Materi hanya bisa dibaca untuk tahap aktif,
# tahap selesai setelah materinya dibaca (KEMBALI) dan tugasnya terpenuhi, dan progres bertahan saat dimuat ulang.

const TUGAS := [
	["help"],
	["device list"],
	["toko beli usb_wireless_adapter"],
	["toko beli antena_eksternal"],
	["toko beli kabel_usb"],
	["device rakit"],
	["tools search driver"],
	["tools install driver-ar9271"],
	["device hubungkan"],
	["tools install wifi-scanner"],
	["wifi-scanner --scan"],
	["__netmgr__"],
	["network inspect LAB-WIFI-01"],
	["tools install network-analyzer"],
	["security analyze LAB-WIFI-01"],
	["man password-auditor"],
	["tools install password-auditor"],
	["tools list"],
	["man handshake"],
	["audit auth LAB-WIFI-01"],
	["man hasil-handshake"],
	["man audit"],
	["audit run LAB-WIFI-01"],
	["man kesimpulan-audit"],
	["security verify LAB-WIFI-01 senja1234"],
	[],
]

func before_each() -> void:
	Bahasa.kode = "id"

func _sesi() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	return s

func _kerjakan(s: ShellSession, n: int) -> void:
	for cmd in TUGAS[n - 1]:
		if cmd == "__netmgr__":
			s.jaringan.buka("ui:netmgr")
		else:
			s.jalankan(cmd)
		Misi.perbarui(s)

func _aktif(s: ShellSession) -> int:
	return Misi.tahap_aktif(s, Misi.temukan("misi_1"))

func _bisa(s: ShellSession, n: int) -> bool:
	return Misi.tahap_bisa_dibaca(s, Misi.temukan("misi_1"), n)

func _ada_email(s: ShellSession, n: int) -> bool:
	for p in s.pesan_misi:
		if Bahasa.pilih(String(p["subjek"])).contains("Tahap %d:" % n):
			return true
	return false

func _jumlah_email(s: ShellSession, n: int) -> int:
	var k := 0
	for p in s.pesan_misi:
		if Bahasa.pilih(String(p["subjek"])).contains("Tahap %d:" % n):
			k += 1
	return k

func test_hanya_tahap_1_yang_bisa_dibaca_di_awal() -> void:
	var s := _sesi()
	assert_eq(_aktif(s), 1, "tahap 1 aktif setelah misi diterima")
	assert_true(_bisa(s, 1), "materi tahap 1 bisa dibaca")
	assert_false(_bisa(s, 2), "materi tahap 2 belum bisa dibaca")
	assert_false(_bisa(s, 26), "materi tahap terakhir belum bisa dibaca")

func test_tugas_saja_menyelesaikan_tahap() -> void:
	var s := _sesi()
	_kerjakan(s, 1)
	assert_eq(_aktif(s), 2, "tugas tahap 1 saja sudah menyelesaikan tahap 1")
	assert_true(_ada_email(s, 2), "email tahap 2 datang tanpa perlu membuka BELAJAR")


func test_belajar_hanya_panduan_opsional() -> void:
	var s := _sesi()
	_kerjakan(s, 1)
	assert_true(Misi.tandai_baca(s, "misi_1", 1), "materi tahap 1 tetap bisa dibuka sebagai panduan")
	assert_eq(_aktif(s), 2, "membaca materi tidak mengubah tahap aktif")
	assert_true(_bisa(s, 1), "materi tahap yang sudah selesai tetap bisa dibuka")
	assert_false(_bisa(s, 3), "materi tahap yang belum terbuka tidak bisa dibuka")


func test_tahap_yang_belum_aktif_tidak_bisa_ditandai() -> void:
	var s := _sesi()
	assert_false(Misi.tandai_baca(s, "misi_1", 3), "tahap 3 belum aktif")
	assert_false(s.jaringan.progres.has(Misi.baca_flag("misi_1", 3)), "tidak ada flag untuk tahap 3")

func test_tugas_lebih_awal_tidak_melewati_urutan() -> void:
	var s := _sesi()
	for n in range(1, 13):
		_kerjakan(s, n)
	assert_eq(_aktif(s), 13, "tahap 13 aktif")
	# Tugas tahap 14 dikerjakan lebih dulu. Tahap 14 belum terbuka sebelum tahap 13 selesai.
	_kerjakan(s, 14)
	assert_eq(_aktif(s), 13, "tugas tahap 14 yang lebih awal tidak membuka tahap 13")
	assert_false(_ada_email(s, 14), "email tahap 14 belum datang")
	assert_false(_bisa(s, 14), "materi tahap 14 belum bisa dibuka")
	_kerjakan(s, 13)
	assert_eq(_aktif(s), 15, "setelah tahap 13 selesai, tahap 14 yang sudah tuntas ikut terbuka")
	assert_true(_ada_email(s, 14), "email tahap 14 datang")
	assert_true(_ada_email(s, 15), "email tahap 15 datang")


func test_urutan_penuh_26_tahap() -> void:
	var s := _sesi()
	for n in range(1, 26):
		assert_eq(_aktif(s), n, "tahap aktif harus %d" % n)
		assert_true(_bisa(s, n), "materi %d bisa dibuka" % n)
		if n < 26:
			assert_false(_bisa(s, n + 1), "materi %d belum bisa dibuka" % (n + 1))
		_kerjakan(s, n)
	# Tahap 26 tidak punya tugas, jadi selesai bersama tahap 25 dan misi ikut selesai.
	assert_eq(_aktif(s), 0, "semua tahap selesai")
	assert_eq(String(s.misi.get("misi_1", "")), "selesai", "misi selesai setelah tugas tahap 25")
	assert_true(s.hadiah_diambil.has("misi_1"), "hadiah diberikan")


func test_misi_belum_selesai_sebelum_tugas_terakhir() -> void:
	var s := _sesi()
	for n in range(1, 25):
		_kerjakan(s, n)
	assert_eq(_aktif(s), 25, "tahap 25 aktif")
	assert_eq(String(s.misi.get("misi_1", "")), "aktif", "misi belum selesai sebelum tugas tahap 25")
	assert_false(s.hadiah_diambil.has("misi_1"), "hadiah belum diberikan")
	_kerjakan(s, 25)
	assert_eq(String(s.misi.get("misi_1", "")), "selesai", "misi selesai setelah tugas tahap 25")


func test_progres_tahap_tetap_setelah_dimuat_ulang() -> void:
	var s := _sesi()
	for n in range(1, 6):
		Misi.tandai_baca(s, "misi_1", n)
		_kerjakan(s, n)
	assert_eq(_aktif(s), 6, "tahap 6 aktif sebelum disimpan")
	var d = JSON.parse_string(JSON.stringify(s.to_dict()))
	var s2 := ShellSession.dari_dict(d)
	assert_eq(_aktif(s2), 6, "tahap 6 tetap aktif setelah dimuat ulang")
	assert_true(_bisa(s2, 6), "materi tahap 6 bisa dibaca setelah dimuat ulang")
	assert_true(_bisa(s2, 5), "materi tahap 5 tetap bisa dibuka sebagai panduan setelah dimuat ulang")
	assert_false(_bisa(s2, 7), "materi tahap 7 tetap terkunci setelah dimuat ulang")
	Misi.perbarui(s2)
	Misi.perbarui(s2)
	assert_eq(_jumlah_email(s2, 6), 1, "email tahap 6 tidak berulang")
