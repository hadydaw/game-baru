extends GutTest

# Regresi: setelah save dimuat ulang (JSON memuat nomor tahap sebagai float), email tahap tidak terkirim ulang.

func before_each() -> void:
	Bahasa.kode = "id"

func _jumlah_subjek(s: ShellSession, teks: String) -> int:
	var n := 0
	for p in s.pesan_misi:
		if String(p["subjek"]).contains(teks):
			n += 1
	return n

func test_email_tahap_tidak_berulang_setelah_muat_ulang() -> void:
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	s.jalankan("help")
	s.jalankan("lsusb")
	_baca_tahap_aktif(s)
	var d = JSON.parse_string(JSON.stringify(s.to_dict()))
	var s2 := ShellSession.dari_dict(d)
	Misi.perbarui(s2)
	Misi.perbarui(s2)
	assert_eq(_jumlah_subjek(s2, "Tahap 2"), 1, "tahap 2 tetap satu email")
	assert_eq(_jumlah_subjek(s2, "Tahap 1"), 1, "tahap 1 tetap satu email")

# Pemain membaca materi tahap yang sedang aktif (tombol KEMBALI), lalu menyelesaikan tugasnya.
func _baca_tahap_aktif(s: ShellSession) -> void:
	var m := Misi.temukan("misi_1")
	var n := Misi.tahap_aktif(s, m)
	while n > 0 and not s.jaringan.progres.has(Misi.baca_flag("misi_1", n)):
		if not Misi.tandai_baca(s, "misi_1", n):
			break
		n = Misi.tahap_aktif(s, m)
