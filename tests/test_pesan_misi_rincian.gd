extends GutTest

# Email masuk misi memuat rincian lengkap, dan email tiap tahap memuat tujuan tahap itu.

func before_each() -> void:
	Bahasa.kode = "id"

func _sesi() -> ShellSession:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	return s

func test_email_masuk_memuat_rincian() -> void:
	var s := _sesi()
	var p: Dictionary = s.pesan_misi[0]
	assert_eq(String(p["subjek"]).findn("Tutorial Misi 1") >= 0, true)
	var isi := Bahasa.pilih(String(p["isi"]))
	assert_true(isi.contains("Tujuan:"), "rincian tujuan harus ada")
	assert_true(isi.contains("Pembayaran: Kr 150"), "rincian pembayaran harus ada")
	assert_true(isi.contains("Persyaratan:"), "rincian persyaratan harus ada")
	assert_true(isi.contains("Buka aplikasi Misi"), "email pembuka mengarahkan ke aplikasi Misi")
	assert_false(isi.contains("Tahap 1"), "email pembuka tidak menumpuk daftar tahap")

func test_email_tahap_memuat_tujuan_tahap() -> void:
	var s := _sesi()
	s.jalankan("help")
	s.jalankan("lsusb")
	_baca_tahap_aktif(s)
	var isi := ""
	for p in s.pesan_misi:
		if String(p["subjek"]).contains("Tahap 1"):
			isi = Bahasa.pilih(String(p["isi"]))
	assert_true(isi.contains("Tujuan tahap ini:"), "email tahap harus memuat tujuan tahap")

func test_email_misi_muncul_di_kotak_masuk() -> void:
	var s := _sesi()
	var masuk := Email.daftar(s, "masuk")
	var ada := false
	for p in masuk:
		if String(p["id"]) == "misi:0":
			ada = true
	assert_true(ada, "pesan misi harus muncul di kotak masuk Email")
	assert_eq(Email.jumlah_belum_dibaca(s) >= 1, true)
	Email.tandai_dibaca(s, "misi:0")
	assert_true(Email.sudah_dibaca(s, "misi:0"))

func _ada_subjek(s: ShellSession, teks: String) -> bool:
	for p in s.pesan_misi:
		if String(p["subjek"]).contains(teks):
			return true
	return false

func test_email_tahap_datang_berurutan() -> void:
	var s := _sesi()
	assert_true(_ada_subjek(s, "Tahap 1"), "tahap 1 datang saat misi diterima")
	assert_false(_ada_subjek(s, "Tahap 2"), "tahap 2 belum datang sebelum tahap 1 selesai")
	s.jalankan("help")
	_baca_tahap_aktif(s)
	assert_true(_ada_subjek(s, "Tahap 2"), "tahap 2 datang setelah tahap 1 selesai")
	assert_false(_ada_subjek(s, "Tahap 3"), "tahap 3 belum datang sebelum tahap 2 selesai")
	s.jalankan("lsusb")
	_baca_tahap_aktif(s)
	assert_true(_ada_subjek(s, "Tahap 3"), "tahap 3 datang setelah tahap 2 selesai")
	assert_false(_ada_subjek(s, "Tahap 4"), "tahap 4 belum datang")

# Pemain membaca materi tahap yang sedang aktif (tombol KEMBALI), lalu menyelesaikan tugasnya.
func _baca_tahap_aktif(s: ShellSession) -> void:
	var m := Misi.temukan("misi_1")
	var n := Misi.tahap_aktif(s, m)
	while n > 0 and not s.jaringan.progres.has(Misi.baca_flag("misi_1", n)):
		if not Misi.tandai_baca(s, "misi_1", n):
			break
		n = Misi.tahap_aktif(s, m)
