extends GutTest

# Sesi Terminal harus bertahan saat layarnya dilepas (kembali ke Desktop) lalu dibuka lagi:
# riwayat tampilan, direktori kerja, riwayat perintah, dan sesi SSH.

func _fs_uji() -> Dictionary:
	var pemilik := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-xr-x"}
	var dokumen := pemilik.duplicate()
	dokumen["isi"] = {
		"kunci_arsip.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "arsip:TK-7731", "ukuran": 13}
	}
	var operator := pemilik.duplicate()
	operator["isi"] = {"dokumen": dokumen}
	return {
		"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x",
		"isi": {"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": operator}}}
	}

func before_each() -> void:
	TerminalScreen._sesi_bersama = null
	TerminalScreen._buffer_bersama = ""
	TerminalScreen._scroll_bersama = 0.0
	TerminalScreen._ikut_bawah_bersama = true
	SesiUtama.sesi = ShellSession.new(Vfs.new(_fs_uji()))

func _buka() -> TerminalScreen:
	var layar := TerminalScreen.new()
	add_child(layar)
	return layar

# Simulasi pemain kembali ke Desktop: layar dilepas dari tree dan dibebaskan.
func _tutup(layar: TerminalScreen) -> void:
	remove_child(layar)
	layar.free()

func _teks(layar: TerminalScreen) -> String:
	return layar._keluaran.get_parsed_text()

func _kirim_selesai(layar: TerminalScreen, perintah: String) -> void:
	layar._kirim(perintah)
	layar._selesaikan_cepat()

func test_output_dan_riwayat_bertahan_saat_layar_dibuka_ulang() -> void:
	var l1 := _buka()
	_kirim_selesai(l1, "ping -c 1 gerbang")
	_kirim_selesai(l1, "nmap gerbang")
	_kirim_selesai(l1, "ping -c 4 gerbang")
	_tutup(l1)

	var l2 := _buka()
	var teks := _teks(l2)
	assert_true(teks.contains("nmap gerbang"), "perintah nmap masih terlihat")
	assert_true(teks.contains("Memindai gerbang"), "output nmap masih terlihat")
	assert_true(teks.contains("ping -c 4 gerbang"), "perintah ping masih terlihat")
	assert_eq(teks.count("Terminal siap"), 1, "banner tidak diulang saat dibuka lagi")
	assert_eq(l2._riwayat_idx, TerminalScreen._sesi_bersama.riwayat.size(), "indeks riwayat mengikuti sesi")
	assert_true(TerminalScreen._sesi_bersama.riwayat.has("nmap gerbang"))
	_tutup(l2)

func test_direktori_kerja_bertahan() -> void:
	var l1 := _buka()
	_kirim_selesai(l1, "cd dokumen")
	_tutup(l1)

	var l2 := _buka()
	assert_eq(TerminalScreen._sesi_bersama.cwd, "/home/operator/dokumen")
	_kirim_selesai(l2, "pwd")
	assert_true(_teks(l2).contains("/home/operator/dokumen"), "pwd menunjukkan direktori yang sama")
	_tutup(l2)

func test_animasi_belum_selesai_diselesaikan_saat_layar_dilepas() -> void:
	var l1 := _buka()
	l1._kirim("nmap gerbang")
	assert_true(l1._busy, "animasi sedang berjalan")
	_tutup(l1)

	var l2 := _buka()
	var teks := _teks(l2)
	assert_true(teks.contains("Pemindaian selesai"), "output lengkap tersimpan walau animasi belum selesai")
	_tutup(l2)

func test_sesi_ssh_bertahan_saat_layar_dibuka_ulang() -> void:
	var l1 := _buka()
	_kirim_selesai(l1, "ping -c 1 gerbang")
	_kirim_selesai(l1, "ping -c 1 arsip")
	_kirim_selesai(l1, "ssh operator@arsip")
	assert_not_null(TerminalScreen._sesi_bersama.ssh_aktif, "ssh berhasil")
	_tutup(l1)

	var l2 := _buka()
	assert_not_null(TerminalScreen._sesi_bersama.ssh_aktif, "sesi ssh masih aktif setelah layar dibuka lagi")
	assert_true(l2._label_prompt.text.contains("arsip"), "prompt menunjukkan host SSH")
	_kirim_selesai(l2, "exit")
	assert_null(TerminalScreen._sesi_bersama.ssh_aktif, "exit menutup sesi ssh")
	assert_true(_teks(l2).contains("ditutup"), "pesan penutupan tampil")
	_tutup(l2)

func test_sesi_baru_hanya_dibuat_saat_belum_ada() -> void:
	var l1 := _buka()
	var pertama := TerminalScreen._sesi_bersama
	_tutup(l1)
	var l2 := _buka()
	assert_true(pertama == TerminalScreen._sesi_bersama, "objek sesi yang sama dipakai ulang")
	_tutup(l2)
