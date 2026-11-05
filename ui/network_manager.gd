class_name NetworkManager
extends Control

# Network Manager: pengujian Wi-Fi laboratorium dalam bentuk layar. Setiap tombol menjalankan
# perintah yang sama dengan Terminal (wifi-scanner, network, security, audit) lewat ShellSession,
# sehingga status pemindaian, analisis, dan akses selalu sama dengan yang tampil di Terminal.

const WARNA_TERKUNCI := Color(0.55, 0.62, 0.6)

var _sesi: ShellSession
var _kolom: VBoxContainer
var _keluaran: Label
var _baris_terakhir: Array = []
var _pesan_sandi: Dictionary = {}   # SSID -> teks kata sandi yang sedang diketik

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesi = SesiUtama.ambil()
	var latar := ColorRect.new()
	latar.color = Color("0d1117")
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(margin, 16)
	add_child(margin)
	var gulir := ScrollContainer.new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(gulir)
	_kolom = VBoxContainer.new()
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_constant_override("separation", 12)
	gulir.add_child(_kolom)
	Bahasa.daftar_penyegar(self, _segarkan)

func _segarkan() -> void:
	for c in _kolom.get_children():
		c.queue_free()
	_kolom.add_child(_teks(Bahasa.t("netmgr.judul"), Tema.TEAL, 34))
	_kolom.add_child(_teks(Bahasa.t("netmgr.hint"), Tema.TEKS_REDUP, 20))
	_kolom.add_child(_bagian(Bahasa.t("netmgr.perangkat")))
	_kolom.add_child(_kartu_perangkat())
	_kolom.add_child(_bagian(Bahasa.t("netmgr.tahap")))
	_kolom.add_child(_kartu_tahap())
	_kolom.add_child(_bagian(Bahasa.t("netmgr.jaringan")))
	if not _sesi.wifi.sudah_scan():
		_kolom.add_child(_teks(Bahasa.t("netmgr.belum_scan"), WARNA_TERKUNCI, 22))
	else:
		for ssid in _sesi.wifi.ditemukan:
			_kolom.add_child(_kartu_jaringan(String(ssid)))
	_kolom.add_child(_tombol(Bahasa.t("netmgr.scan"), _sesi.perangkat.terhubung(), _pindai))
	_kolom.add_child(_bagian(Bahasa.t("netmgr.keluaran")))
	_keluaran = _teks("", Tema.TEKS, 20)
	_keluaran.text = _teks_keluaran()
	_kolom.add_child(_keluaran)

# Status perangkat diambil dari sumber yang sama dengan device di Terminal.
func _kartu_perangkat() -> PanelContainer:
	var p := _sesi.perangkat
	var isi := Bahasa.t("netmgr.belum_rakit")
	if p.sudah_dirakit():
		var status := Bahasa.t("dev.terhubung") if p.terhubung() else Bahasa.t("dev.tidak_terhubung")
		var driver := p.driver_aktif() if p.driver_aktif() != "" else Bahasa.t("dev.belum_driver")
		isi = Bahasa.t("netmgr.rincian_perangkat") % [String(Perangkat.info(p.adapter())["nama"]), status, driver]
	return _kartu([_teks(isi, Tema.TEKS, 22)])

func _kartu_tahap() -> PanelContainer:
	var s := _sesi
	var langkah := [
		[Bahasa.t("netmgr.t_perangkat"), s.perangkat.terhubung()],
		[Bahasa.t("netmgr.t_scan"), s.wifi.sudah_scan()],
		[Bahasa.t("netmgr.t_pilih"), s.wifi.terpilih != ""],
		[Bahasa.t("netmgr.t_analisis"), not s.wifi.dianalisis.is_empty()],
		[Bahasa.t("netmgr.t_auth"), not s.wifi.handshake.is_empty()],
		[Bahasa.t("netmgr.t_audit"), not s.wifi.kata_sandi_ditemukan.is_empty()],
		[Bahasa.t("netmgr.t_akses"), not s.wifi.terakses.is_empty()],
	]
	var barisan: Array = []
	for l in langkah:
		barisan.append(_teks(("[x] " if bool(l[1]) else "[ ] ") + String(l[0]), Tema.TEAL if bool(l[1]) else Tema.TEKS_REDUP, 20))
	return _kartu(barisan)

func _kartu_jaringan(ssid: String) -> PanelContainer:
	var j := WifiLab.jaringan(ssid)
	var s := _sesi
	var bagian: Array = [
		_teks("%s  %s" % [ssid, _label_status(ssid)], Tema.TEKS, 24),
		_teks(Bahasa.t("netmgr.detail") % [int(j["kanal"]), int(j["sinyal"]), String(j["enkripsi"])], Tema.TEKS_REDUP, 19),
	]
	# Tombol tahap berikutnya saja yang aktif. Urutan sama dengan perintah Terminal.
	if s.wifi.terakses.has(ssid):
		bagian.append(_teks(Bahasa.t("netmgr.akses_terbuka"), Tema.AMBER, 20))
	elif not s.wifi.kata_sandi_ditemukan.has(ssid):
		var aksi := _aksi_berikutnya(ssid)
		if aksi != null:
			bagian.append(aksi)
	else:
		bagian.append(_verifikasi(ssid))
	return _kartu(bagian)

func _aksi_berikutnya(ssid: String) -> Control:
	var s := _sesi
	if s.wifi.terpilih != ssid:
		return _tombol(Bahasa.t("netmgr.pilih"), true, func(): _jalankan("network inspect " + ssid))
	if not s.wifi.dianalisis.has(ssid):
		return _tombol(Bahasa.t("netmgr.analisis"), true, func(): _jalankan("security analyze " + ssid))
	if not s.wifi.handshake.has(ssid):
		return _tombol(Bahasa.t("netmgr.auth"), true, func(): _jalankan("audit auth " + ssid))
	return _tombol(Bahasa.t("netmgr.audit"), true, func(): _jalankan("audit run " + ssid))

# Kata sandi diketik pemain, bukan diisi otomatis: verifikasi harus lewat hasil audit.
func _verifikasi(ssid: String) -> Control:
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 8)
	var isian := LineEdit.new()
	isian.placeholder_text = Bahasa.t("netmgr.kata_sandi")
	isian.custom_minimum_size = Vector2(0, 64)
	isian.text = String(_pesan_sandi.get(ssid, ""))
	isian.text_changed.connect(func(t: String): _pesan_sandi[ssid] = t)
	kolom.add_child(isian)
	kolom.add_child(_tombol(Bahasa.t("netmgr.verifikasi"), true, func(): _jalankan("security verify %s %s" % [ssid, String(_pesan_sandi.get(ssid, ""))])))
	return kolom

func _label_status(ssid: String) -> String:
	var s := _sesi
	if s.wifi.terakses.has(ssid):
		return Bahasa.t("netmgr.st_akses")
	if s.wifi.kata_sandi_ditemukan.has(ssid):
		return Bahasa.t("netmgr.st_kata")
	if s.wifi.handshake.has(ssid):
		return Bahasa.t("netmgr.st_handshake")
	if s.wifi.dianalisis.has(ssid):
		return Bahasa.t("netmgr.st_analisis")
	if s.wifi.terpilih == ssid:
		return Bahasa.t("netmgr.st_pilih")
	return Bahasa.t("netmgr.st_terlihat")

func _pindai() -> void:
	_jalankan("wifi-scanner --scan")

# Menjalankan perintah lewat sesi yang sama dengan Terminal, lalu menyimpan dan memperbarui misi.
func _jalankan(perintah: String) -> void:
	_baris_terakhir = _sesi.jalankan(perintah)
	# Aplikasi ini sudah terbuka, jadi tidak perlu meminta jendela lain.
	_sesi.permintaan_aplikasi = ""
	Misi.perbarui(_sesi)
	Penyimpanan.simpan_sesi(_sesi)
	_segarkan()

func _teks_keluaran() -> String:
	var bagian: Array = []
	for b in _baris_terakhir:
		if String(b.get("tipe", "")) != "clear":
			bagian.append(ShellSession.teks_baris(b))
	return "\n".join(PackedStringArray(bagian)) if not bagian.is_empty() else Bahasa.t("netmgr.keluaran_kosong")

func _kartu(isi: Array) -> PanelContainer:
	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 14))
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 14)
	kartu.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	for c in isi:
		v.add_child(c)
	return kartu

func _tombol(teks: String, aktif: bool, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	b.disabled = not aktif
	b.custom_minimum_size = Vector2(0, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(aksi)
	return b

func _bagian(teks: String) -> Label:
	return _teks(teks, Tema.AMBER, 24)

func _teks(isi: String, warna: Color, ukuran: int) -> Label:
	var l := Tema.label(isi, warna, ukuran)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
