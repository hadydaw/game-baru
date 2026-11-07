extends SceneTree

const UA := preload("res://tests/uji_aplikasi.gd")

const CMDS := [
	["help"], ["lsusb"], ["__beli__usb_wireless_adapter"], ["__beli__antena_eksternal"], ["__beli__kabel_usb"],
	["__rakit__"], ["apt search driver"], ["apt install -y driver-ar9271"], ["__hubungkan__"],
	["apt install -y aircrack-ng"], ["airmon-ng start wlan0", "airodump-ng wlan0mon"], ["__netmgr__"], ["airodump-ng --bssid 02:4A:1C:00:01:01 wlan0mon"],
	["apt install -y network-analyzer"], ["network-analyzer analyze LAB-WIFI-01"], ["man password-auditor"],
	["apt install -y password-auditor"],
]
const SHOTS := "user://"

var _gagal := 0
var _lulus := 0
var _ukuran := "x"

func _cek(k: bool, p: String) -> void:
	if k:
		_lulus += 1
		print("LULUS: ", p)
	else:
		_gagal += 1
		print("GAGAL: ", p)

func _tombol(layar: Node, teks_cari: Array) -> Button:
	for b in layar.find_children("*", "Button", true, false):
		var t := (b as Button).text
		if teks_cari.has(t):
			return b
	return null

func _semua_teks(layar: Node) -> Array:
	var hasil := []
	for b in layar.find_children("*", "Button", true, false):
		hasil.append((b as Button).text)
	return hasil

func _keluar_batas(layar: Node, lebar: float) -> Array:
	var bocor := []
	for c in layar.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		if ctl is Label or ctl is Button:
			var r := ctl.get_global_rect()
			if r.size.x <= 0 or r.size.y <= 0:
				continue
			if r.position.x < -0.5 or r.end.x > lebar + 0.5:
				bocor.append((ctl as Control).get_class() + ":" + (ctl.text if "text" in ctl else ""))
	return bocor

func _simpan(path: String) -> void:
	get_root().get_texture().get_image().save_png(path)

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_email_hp.json"
	Penyimpanan.arsipkan("user://uji_email_tmp.json")
	SesiUtama.reset()
	var s := ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	for i in range(CMDS.size()):
		for c in CMDS[i]:
			if c == "__netmgr__":
				s.jaringan.buka("ui:netmgr")
			else:
				UA.jalan(s, c)
			Misi.perbarui(s)
	SesiUtama.sesi = s
	var env := (OS.get_environment("UKURAN_HP") if OS.get_environment("UKURAN_HP") != "" else "360x640")
	var dim := env.split("x")
	var lebar := float(dim[0])
	var tinggi := float(dim[1])
	_ukuran = "%dx%d" % [lebar, tinggi]
	print("UKURAN ", _ukuran, " aktif=", Misi.tahap_aktif(s, Misi.temukan("misi_1")))

	var wadah := Control.new()
	wadah.size = Vector2(lebar, tinggi)
	get_root().add_child(wadah)
	var app := EmailApp.new()
	app.size = Vector2(lebar, tinggi)
	wadah.add_child(app)
	for i in range(3):
		await process_frame
	_cek(_keluar_batas(app, lebar).is_empty(), "daftar email tidak keluar lebar %s" % _ukuran)
	_simpan(SHOTS + "email_daftar_%s.png" % _ukuran)

	# Buka email tahap 18 (aktif) dan periksa tombolnya.
	var target := ""
	for p in Email.daftar(s, "masuk"):
		if int(p.get("tahap", 0)) == 18:
			target = String(p["id"])
	_cek(target != "", "email tahap 18 ada di kotak masuk")
	app._pilih_pesan(target)
	app._aksi_baca()
	for i in range(3):
		await process_frame
	var teks := _semua_teks(app)
	_cek(teks.has("KELUAR") and teks.has("BELAJAR") and teks.has("MENGHAPUS"), "tombol KELUAR, BELAJAR, MENGHAPUS ada")
	_cek(_keluar_batas(app, lebar).is_empty(), "pembaca tidak keluar lebar %s" % _ukuran)
	_simpan(SHOTS + "email_pembaca_t18_%s.png" % _ukuran)
	# Isi pesan harus bisa dijangkau dengan menggulir sampai habis, di layar setinggi apa pun.
	var gulir_pembaca: ScrollContainer = null
	for g in app.find_children("*", "ScrollContainer", true, false):
		if gulir_pembaca == null or (g as ScrollContainer).size.y > gulir_pembaca.size.y:
			gulir_pembaca = g
	_cek(gulir_pembaca != null and gulir_pembaca.get_v_scroll_bar().max_value > 0, "isi pesan bisa digulir di %s" % _ukuran)
	if gulir_pembaca != null:
		gulir_pembaca.scroll_vertical = 100000
		await process_frame
		await process_frame
		_cek(gulir_pembaca.scroll_vertical > 0, "menggulir isi pesan sampai bawah berhasil %s" % _ukuran)

	var belajar := _tombol(app, ["BELAJAR", "LEARN"])
	_cek(belajar != null and not belajar.disabled, "BELAJAR aktif untuk tahap 18")
	belajar.pressed.emit()
	for i in range(3):
		await process_frame
	var isi_belajar := _semua_teks(app)
	_cek(isi_belajar.has("KEMBALI") or isi_belajar.has("BACK"), "materi BELAJAR menampilkan KEMBALI")
	_cek(not isi_belajar.has("SESUDAH") and not isi_belajar.has("SEBELUM") and not isi_belajar.has("NEXT") and not isi_belajar.has("PREVIOUS"), "materi tidak punya tombol lompat tahap")
	_cek(_keluar_batas(app, lebar).is_empty(), "materi tidak keluar lebar %s" % _ukuran)
	_simpan(SHOTS + "email_belajar_t18_%s.png" % _ukuran)

	# Tugas tahap 18 (tools list) belum dijalankan saat KEMBALI ditekan, jadi tahap tetap 18.
	var kembali := _tombol(app, ["KEMBALI", "BACK"])
	kembali.pressed.emit()
	for i in range(3):
		await process_frame
	_cek(Misi.tahap_aktif(s, Misi.temukan("misi_1")) == 18, "KEMBALI tidak mengubah tahap aktif (masih 18 sebelum tugas)")

	# Jalankan tugas tahap 18: email tahap 19 harus datang tanpa KEMBALI.
	s.jalankan("apt list --installed")
	Misi.perbarui(s)
	var ada19 := false
	for p in s.pesan_misi:
		if int(p.get("tahap", 0)) == 19:
			ada19 = true
	_cek(ada19, "email tahap 19 datang setelah tugas tahap 18 selesai")
	_cek(Misi.tahap_aktif(s, Misi.temukan("misi_1")) == 19, "tahap aktif 19")

	# KELUAR menutup pembaca.
	var keluar := _tombol(app, ["KELUAR", "EXIT"])
	_cek(keluar != null, "tombol KELUAR ada di pembaca")
	keluar.pressed.emit()
	for i in range(2):
		await process_frame
	_cek(not _semua_teks(app).has("KELUAR"), "KELUAR menutup pembaca")

	# MENGHAPUS memindahkan email ke SAMPAH.
	var sebelum := Email.daftar(s, "masuk").size()
	app._pilih_pesan(target)
	app._aksi_baca()
	for i in range(2):
		await process_frame
	var hapus := _tombol(app, ["MENGHAPUS", "DELETE"])
	_cek(hapus != null, "tombol MENGHAPUS ada")
	hapus.pressed.emit()
	for i in range(2):
		await process_frame
	_cek(Email.status(s, target) == "sampah", "MENGHAPUS memindahkan email ke sampah (status=%s)" % Email.status(s, target))
	_cek(Email.daftar(s, "masuk").size() == sebelum - 1, "kotak masuk berkurang satu")

	# Pulihkan dari SAMPAH.
	app._ganti_tab("sampah")
	for i in range(2):
		await process_frame
	app._pilih_pesan(target)
	app._aksi_baca()
	for i in range(2):
		await process_frame
	var pulih := _tombol(app, ["PULIHKAN", "RESTORE"])
	_cek(pulih != null, "tombol PULIHKAN ada di sampah")
	pulih.pressed.emit()
	for i in range(2):
		await process_frame
	_cek(Email.status(s, target) == "masuk", "PULIHKAN mengembalikan email ke kotak masuk (status=%s)" % Email.status(s, target))

	# Hapus permanen harus lewat konfirmasi, lalu email hilang.
	app._ganti_tab("sampah")
	app._pilih_pesan(target)
	app._aksi_baca()
	for i in range(2):
		await process_frame
	Email.pindah_ke_sampah(s, target)
	app._pilih_pesan(target)
	app._segarkan()
	for i in range(2):
		await process_frame
	var permanen := _tombol(app, ["HAPUS", "DELETE"])
	_cek(permanen != null, "tombol HAPUS (permanen) ada di sampah")
	if permanen != null:
		permanen.pressed.emit()
		for i in range(2):
			await process_frame
		var konfirmasi := false
		for c in app.find_children("*", "KonfirmasiPanel", true, false):
			konfirmasi = (c as Control).is_visible_in_tree()
		_cek(konfirmasi, "HAPUS permanen menampilkan dialog konfirmasi")
		_cek(Email.cari(target, s).size() > 0, "email belum terhapus sebelum dikonfirmasi")
		app._jalankan_tertunda()
		for i in range(2):
			await process_frame
		var di_sampah := false
		for p in Email.daftar(s, "sampah"):
			if String(p["id"]) == target:
				di_sampah = true
		_cek(Email.status(s, target) == "terhapus" and not di_sampah, "setelah dikonfirmasi email hilang permanen dari sampah (status=%s)" % Email.status(s, target))

	print("HASIL UI %s: lulus=%d gagal=%d" % [_ukuran, _lulus, _gagal])
	quit(1 if _gagal > 0 else 0)
