extends SceneTree

# Smoke test aplikasi Toko Perangkat, Dompet, dan Alat Lapangan: layar dibuka dengan sesi nyata,
# lalu aksi utamanya dijalankan lewat jalur yang sama dengan tombol.
# Keluar dengan kode 1 bila ada yang gagal.

var _gagal := 0

func _cek(k: bool, p: String) -> void:
	print(("LULUS: " if k else "GAGAL: ") + p)
	if not k:
		_gagal += 1

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_apl.json"
	Penyimpanan.arsipkan("user://uji_smoke_apl.json")
	SesiUtama.reset()
	Bahasa.kode = "id"

	var toko := TokoScreen.new()
	root.add_child(toko)
	await process_frame
	await process_frame
	_cek(toko.get_child_count() > 0, "Toko Perangkat membangun isi layar")
	var sesi: ShellSession = SesiUtama.ambil()
	sesi.economy.saldo = 2000
	toko.call("_beli", "usb_wireless_adapter")
	_cek(sesi.perangkat.jumlah("usb_wireless_adapter") > 0, "tombol Beli menambah perangkat")
	_cek(sesi.jaringan.progres.has("beli:usb_wireless_adapter"), "tombol Beli mencatat flag misi")
	toko.queue_free()
	await process_frame

	var dompet := DompetScreen.new()
	root.add_child(dompet)
	await process_frame
	await process_frame
	_cek(dompet.get_child_count() > 0, "Dompet membangun isi layar")
	dompet.queue_free()
	await process_frame

	var alat := AlatScreen.new()
	root.add_child(alat)
	await process_frame
	await process_frame
	var input: LineEdit = alat.get("_input")
	input.text = "gerbang"
	alat.call("_jalankan", "trace")
	var keluaran: Label = alat.get("_keluaran")
	_cek(keluaran.text.contains("perintah tidak ditemukan"), "Alat menolak trace sebelum Signal Tracer dimiliki")
	input.text = "10.7.0.8"
	alat.call("_jalankan", "scan")
	_cek(keluaran.text != "", "Alat menjalankan scan tanpa tool")
	alat.queue_free()
	await process_frame

	print("HASIL APLIKASI BARU: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
