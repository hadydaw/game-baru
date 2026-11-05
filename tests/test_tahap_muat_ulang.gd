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
	s.jalankan("device list")
	var d = JSON.parse_string(JSON.stringify(s.to_dict()))
	var s2 := ShellSession.dari_dict(d)
	Misi.perbarui(s2)
	Misi.perbarui(s2)
	assert_eq(_jumlah_subjek(s2, "Tahap 2"), 1, "tahap 2 tetap satu email")
	assert_eq(_jumlah_subjek(s2, "Tahap 1"), 1, "tahap 1 tetap satu email")
