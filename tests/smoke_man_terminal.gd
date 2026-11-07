extends SceneTree

# Output Terminal untuk man dan galat man lewat animasi mengetik: hanya bahasa aktif yang tampil.
var _gagal := 0

func _cek(k: bool, p: String) -> void:
	print(("LULUS: " if k else "GAGAL: ") + p)
	if not k:
		_gagal += 1

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_man.json"
	Penyimpanan.arsipkan("user://uji_smoke_man.json")
	SesiUtama.reset()
	# Satu bahasa per proses, karena riwayat Terminal dibagi antar layar dalam satu proses.
	var kode := OS.get_environment("KODE_BAHASA") if OS.get_environment("KODE_BAHASA") != "" else "id"
	if true:
		Bahasa.kode = kode
		var layar: Control = TerminalScreen.new()
		root.add_child(layar)
		await process_frame
		await process_frame
		for perintah in ["man handsake", "man aircrack-ng", "man john"]:
			layar.call("_kirim", perintah)
			var lanjut := 0
			while bool(layar.get("_busy")) and lanjut < 20000:
				layar.call("_lanjut")
				lanjut += 1
			await process_frame
		var keluaran: RichTextLabel = layar.get("_keluaran")
		var teks := keluaran.get_parsed_text()
		var ada_penanda := teks.contains(Bahasa.PEMBUKA) or teks.contains(Bahasa.PEMISAH) or teks.contains(Bahasa.PENUTUP)
		_cek(not ada_penanda, "[%s] tidak ada penanda dua bahasa di output" % kode)
		if kode == "id":
			_cek(teks.contains("Tidak ada entri manual untuk handsake"), "[id] galat man handsake dalam Indonesia")
			_cek(not teks.contains("No manual entry"), "[id] galat tidak memuat teks Inggris")
			_cek(teks.contains("uji kunci WPA"), "[id] man aircrack-ng dalam Indonesia")
			_cek(not teks.contains("test WPA keys"), "[id] man aircrack-ng tidak memuat teks Inggris")
		else:
			_cek(teks.contains("No manual entry for handsake"), "[en] galat man handsake dalam Inggris")
			_cek(not teks.contains("Tidak ada entri"), "[en] galat tidak memuat teks Indonesia")
			_cek(teks.contains("test WPA keys"), "[en] man aircrack-ng dalam Inggris")
			_cek(not teks.contains("uji kunci WPA"), "[en] man aircrack-ng tidak memuat teks Indonesia")
		get_root().get_texture().get_image().save_png("user://man_%s.png" % kode)
		layar.queue_free()
		await process_frame
	print("HASIL MAN TERMINAL: gagal=%d" % _gagal)
	quit(1 if _gagal > 0 else 0)
