extends SceneTree

# Smoke test layar Black Market: tampil, pindah penjual, dan pembelian memakai sesi yang sama dengan Terminal.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("LULUS: ", pesan)
	else:
		print("GAGAL: ", pesan)
		_gagal += 1

func _initialize() -> void:
	Penyimpanan.berkas_aktif = "user://uji_sesi_pasar.json"
	await process_frame
	SesiUtama.sesi = ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))
	var layar := PasarScreen.new()
	layar.size = Vector2(1080, 1920)
	root.add_child(layar)
	await process_frame
	_cek(layar._tombol_penjual.size() == 4, "empat tombol penjual tampil")
	_cek(layar._daftar.get_child_count() == 3, "katalog penjual A tampil")

	layar._pilih_penjual("c")
	await process_frame  # queue_free() baru menghapus anak pada frame berikutnya
	_cek(layar._daftar.get_child_count() == 1, "penjual C terkunci hanya menampilkan pesan")

	layar._pilih_penjual("a")
	layar._beli("a1")
	_cek(SesiUtama.ambil().inventory.punya("packet_inspector"), "pembelian dari layar menambah tool di sesi bersama")
	_cek(SesiUtama.ambil().economy.saldo == 100, "saldo berkurang sesuai harga 400 Kr")
	_cek(layar._pesan.text.begins_with("Dibeli"), "pesan keberhasilan tampil")

	layar._beli("a1")
	_cek(layar._pesan.text != "" and not layar._pesan.text.begins_with("Dibeli"), "pembelian ulang ditolak dengan pesan")
	_cek(SesiUtama.ambil().economy.saldo == 100, "saldo tidak berubah saat ditolak")

	layar.free()
	print("HASIL PASAR: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
