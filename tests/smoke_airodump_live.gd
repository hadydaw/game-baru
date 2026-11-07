extends SceneTree

const UA := preload("res://tests/uji_aplikasi.gd")

# Smoke Terminal: airodump-ng berjalan sebagai mode live di layar HP, bingkai diperbarui,
# dan Ctrl+C (aksi "batal") menghentikannya tanpa mengubah monitor mode atau progres.
var _gagal := 0

func _cek(k: bool, p: String) -> void:
	print(("LULUS: " if k else "GAGAL: ") + p)
	if not k:
		_gagal += 1

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_airodump_live.json"
	Penyimpanan.arsipkan("user://uji_smoke_airodump_live.json")
	SesiUtama.reset()
	var env := (OS.get_environment("UKURAN_HP") if OS.get_environment("UKURAN_HP") != "" else "360x640").split("x")
	var lebar := float(env[0])
	var tinggi := float(env[1])
	var wadah := Control.new()
	wadah.size = Vector2(lebar, tinggi)
	root.add_child(wadah)
	var layar: Control = TerminalScreen.new()
	layar.size = Vector2(lebar, tinggi)
	wadah.add_child(layar)
	for i in range(3):
		await process_frame
	var s: ShellSession = layar.get("_sesi")
	for c in ["__beli__usb_wireless_adapter", "__beli__antena_eksternal", "__beli__kabel_usb", "__rakit__", "apt install -y driver-ar9271", "__hubungkan__", "apt install -y aircrack-ng", "airmon-ng start wlan0"]:
		UA.jalan(s, c)
	layar.call("_kirim", "airodump-ng wlan0mon")
	layar.call("_selesaikan_cepat")
	for i in range(3):
		await process_frame
	_cek(bool(layar.get("_live")), "mode live aktif setelah airodump-ng dijalankan dari Terminal")
	var teks_awal: String = (layar.get("_keluaran") as RichTextLabel).get_parsed_text()
	_cek(teks_awal.contains("[SIMULASI]"), "label simulasi tampil di layar")
	_cek(teks_awal.contains("Elapsed: 0 s"), "bingkai pertama tampil")
	await create_timer(1.3).timeout
	var teks_lanjut: String = (layar.get("_keluaran") as RichTextLabel).get_parsed_text()
	_cek(teks_lanjut.contains("Elapsed: 1 s"), "bingkai diperbarui setelah satu detik")
	_cek(teks_lanjut.count("Elapsed") == 1, "bingkai lama diganti, bukan ditumpuk")
	var lebar_layar: int = s.lebar_kolom
	_cek((layar.get("_keluaran") as RichTextLabel).autowrap_mode != TextServer.AUTOWRAP_OFF, "keluaran membungkus teks di layar HP")
	get_root().get_texture().get_image().save_png("user://airodump_live_bingkai_%dx%d.png" % [lebar, tinggi])
	_cek(lebar_layar >= 20 and lebar_layar < 92, "lebar layar %d kolom membuat tabel ringkas" % lebar_layar)
	var masukan: LineEdit = layar.get("_masukan")
	layar.call("_kirim", "help")
	_cek(bool(layar.get("_live")), "input saat live tidak menghentikan mode live")
	_cek((layar.get("_antrean") as Array).is_empty(), "input saat live tidak diantrikan")
	layar.call("_jalankan_aksi", "batal")
	await process_frame
	_cek(not bool(layar.get("_live")), "Ctrl+C menghentikan mode live")
	_cek(not s.live_aktif(), "keadaan live di sesi ikut berhenti")
	_cek(s.wifi.monitor == "wlan0mon", "monitor mode tetap aktif setelah Ctrl+C")
	_cek(s.jaringan.progres.has("wifi:scan"), "progres pemindaian tetap tercatat")
	var teks_akhir: String = (layar.get("_keluaran") as RichTextLabel).get_parsed_text()
	_cek(teks_akhir.contains("^C"), "^C tampil setelah Ctrl+C")
	await create_timer(1.2).timeout
	var teks_setelah: String = (layar.get("_keluaran") as RichTextLabel).get_parsed_text()
	_cek(teks_setelah.count("Elapsed") == teks_akhir.count("Elapsed"), "tidak ada bingkai baru setelah berhenti")
	_cek(not bool(layar.get("_busy")), "prompt kembali setelah Ctrl+C")
	_cek(not teks_setelah.contains("Perintah yang tersedia"), "input yang diketik saat live tidak dijalankan setelah Ctrl+C")
	# Ctrl+C saat animasi pembuka (belum live) tidak boleh memulai mode live.
	SesiUtama.reset()
	var layar2: Control = TerminalScreen.new()
	layar2.size = Vector2(lebar, tinggi)
	wadah.add_child(layar2)
	for i in range(3):
		await process_frame
	var s2: ShellSession = layar2.get("_sesi")
	for c in ["__beli__usb_wireless_adapter", "__beli__antena_eksternal", "__beli__kabel_usb", "__rakit__", "apt install -y driver-ar9271", "__hubungkan__", "apt install -y aircrack-ng", "airmon-ng start wlan0"]:
		UA.jalan(s2, c)
	layar2.call("_kirim", "airodump-ng wlan0mon")
	_cek(bool(layar2.get("_busy")) and not bool(layar2.get("_live")), "animasi pembuka berjalan sebelum live")
	layar2.call("_jalankan_aksi", "batal")
	for i in range(3):
		await process_frame
	await create_timer(1.2).timeout
	_cek(not bool(layar2.get("_live")), "Ctrl+C saat animasi pembuka tidak memulai mode live")
	_cek(not s2.live_aktif(), "sesi tidak menyimpan keadaan live")
	_cek(not bool(layar2.get("_busy")), "prompt kembali setelah Ctrl+C saat animasi pembuka")
	print("HASIL AIRODUMP LIVE %dx%d gagal=%d" % [lebar, tinggi, _gagal])
	quit(1 if _gagal > 0 else 0)
