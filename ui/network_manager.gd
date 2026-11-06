class_name NetworkManager
extends Control

# Network Manager: aplikasi pemantauan dan pengelolaan jaringan. Tidak ada tahap atau checklist di sini;
# progres tutorial ada di aplikasi Misi. Semua data berasal dari ShellSession yang sama dengan Terminal,
# sehingga pemindaian di Terminal langsung tampil di sini (lewat pemeriksaan berkala).
# Autentikasi, audit kata sandi, dan verifikasi tetap dijalankan lewat Terminal dan Tools.

const WARNA_TERKUNCI := Color(0.55, 0.62, 0.6)
const WARNA_BAHAYA := Color(0.94, 0.27, 0.27)
const TABS := ["antarmuka", "pindai", "detail", "analisis", "riwayat"]
const JEDA_REVEAL := 0.32     # detik antara satu jaringan muncul dan jaringan berikutnya
const PERIKSA_TIAP := 0.5     # detik antara pemeriksaan perubahan dari Terminal

var _sesi: ShellSession
var _tab := "pindai"
var _root: VBoxContainer
var _gulir: ScrollContainer
var _isi: VBoxContainer
var _tombol_tab: Dictionary = {}
var _sig := ""
var _jumlah_riwayat := 0
var _pesan_pindai := ""
var _memindai := false
var _reveal_n := 0
var _baris_hasil: Array = []
var _radar: NetmgrRadar
var _label_hitung: Label
var _terbuka: Dictionary = {}   # indeks riwayat -> true bila badannya sedang dibuka
var _timer_reveal: Timer
var _timer_periksa: Timer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesi = SesiUtama.ambil()
	_jumlah_riwayat = _sesi.wifi.riwayat.size()
	_sig = _signature()
	# Membuka aplikasi dicatat sebagai flag, dipakai langkah tutorial.
	_sesi.jaringan.buka("ui:netmgr")
	Misi.perbarui(_sesi)
	Penyimpanan.simpan_sesi(_sesi)
	var latar := ColorRect.new()
	latar.color = Color("0d1117")
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(margin, 16)
	add_child(margin)
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 12)
	margin.add_child(_root)
	_timer_reveal = Timer.new()
	_timer_reveal.wait_time = JEDA_REVEAL
	_timer_reveal.timeout.connect(_langkah_reveal)
	add_child(_timer_reveal)
	_timer_periksa = Timer.new()
	_timer_periksa.wait_time = PERIKSA_TIAP
	_timer_periksa.timeout.connect(_periksa)
	add_child(_timer_periksa)
	_timer_periksa.start()
	Bahasa.daftar_penyegar(self, _bangun)
	_bangun()

# Seluruh layar dibangun ulang: dipakai saat pertama tampil dan saat bahasa diganti.
func _bangun() -> void:
	_kosongkan(_root)
	_root.add_child(_teks(Bahasa.t("netmgr.judul"), Tema.TEAL, 34))
	_root.add_child(_bar_tab())
	_gulir = ScrollContainer.new()
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(_gulir)
	_isi = VBoxContainer.new()
	_isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_isi.add_theme_constant_override("separation", 12)
	_gulir.add_child(_isi)
	_bangun_tab()

# Hanya isi tab yang dibangun ulang. Dipakai saat data berubah dan saat pindah tab.
func _bangun_tab() -> void:
	_kosongkan(_isi)
	_baris_hasil.clear()
	_radar = null
	_label_hitung = null
	match _tab:
		"antarmuka":
			_isi_antarmuka()
		"pindai":
			_isi_pindai()
		"detail":
			_isi_detail()
		"analisis":
			_isi_analisis()
		"riwayat":
			_isi_riwayat()
	_perbarui_tab_aktif()
	_animasi_masuk(_isi)

func _kosongkan(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

func _animasi_masuk(node: Control) -> void:
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.25)

# ---------- Tab ----------

func _bar_tab() -> Control:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	_tombol_tab.clear()
	for t in TABS:
		var b := Button.new()
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.focus_mode = Control.FOCUS_NONE
		b.text = Bahasa.t("netmgr.tab_" + t)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 64)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(_pilih_tab.bind(t))
		_efek_tekan(b)
		baris.add_child(b)
		_tombol_tab[t] = b
	return baris

func _perbarui_tab_aktif() -> void:
	for t in _tombol_tab:
		var b: Button = _tombol_tab[t]
		var aktif: bool = t == _tab
		var isi := _kotak_tab(Color(0.06, 0.2, 0.2) if aktif else Color(0.04, 0.07, 0.09), Tema.TEAL if aktif else Color(0.2, 0.3, 0.3), 2 if aktif else 1)
		b.add_theme_stylebox_override("normal", isi)
		b.add_theme_stylebox_override("hover", isi)
		b.add_theme_stylebox_override("pressed", _kotak_tab(Color(0.06, 0.2, 0.2), Tema.TEAL, 2))
		b.add_theme_color_override("font_color", Tema.TEAL if aktif else Tema.TEKS_REDUP)

# Kotak tab dengan margin samping kecil agar label muat di layar HP.
func _kotak_tab(bg: Color, batas: Color, lebar: int) -> StyleBoxFlat:
	var k := Tema.kotak(bg, batas, lebar, 12)
	k.content_margin_left = 4.0
	k.content_margin_right = 4.0
	return k

func _pilih_tab(t: String) -> void:
	_tab = t
	_bangun_tab()

# ---------- Antarmuka ----------

func _isi_antarmuka() -> void:
	var p := _sesi.perangkat
	var st := p.status()
	var gel := NetmgrGelombang.new()
	gel.set_status(st)
	if not p.sudah_dirakit():
		_isi.add_child(gel)
		_isi.add_child(_teks(Bahasa.t("netmgr.belum_rakit"), WARNA_TERKUNCI, 22))
		return
	var batas := Tema.TEAL
	var warna_status := Tema.TEKS_REDUP
	match st:
		"aktif":
			warna_status = Tema.TEAL
		"terputus":
			batas = Tema.AMBER
			warna_status = Tema.AMBER
		"kesalahan":
			batas = WARNA_BAHAYA
			warna_status = WARNA_BAHAYA
	var chipset := Perangkat.chipset_adapter(p.adapter())
	var mode := Bahasa.t("netmgr.mode_monitor") if WifiLab.mendukung_monitor(chipset) else Bahasa.t("netmgr.mode_managed")
	var status_teks := Bahasa.t("netmgr.st_" + st)
	_isi.add_child(_kartu([
		gel,
		_teks(String(Perangkat.info(p.adapter())["nama"]), Tema.TEKS, 26),
		_grid([
			[Bahasa.t("netmgr.if_nama"), "wlan0", Tema.TEKS],
			[Bahasa.t("netmgr.if_adapter"), String(Perangkat.info(p.adapter())["nama"]), Tema.TEKS],
			[Bahasa.t("netmgr.if_chipset"), chipset, Tema.TEKS],
			[Bahasa.t("netmgr.if_driver"), p.driver_aktif() if p.driver_aktif() != "" else Bahasa.t("netmgr.tanpa_nilai"), Tema.TEKS],
			[Bahasa.t("netmgr.if_status"), status_teks, warna_status],
			[Bahasa.t("netmgr.if_mode"), mode, Tema.TEKS],
			[Bahasa.t("netmgr.if_koneksi"), Bahasa.t("netmgr.koneksi_ya") if p.terhubung() else Bahasa.t("netmgr.koneksi_tidak"), Tema.TEKS],
		]),
	], batas))

# ---------- Pindai ----------

func _isi_pindai() -> void:
	var w := _sesi.wifi
	_radar = NetmgrRadar.new()
	_radar.set_aktif(_memindai)
	_radar.set_titik(_titik_radar(_reveal_n if _memindai else w.ditemukan.size()))
	_isi.add_child(_radar)
	_label_hitung = _teks(_teks_hitung(), Tema.AMBER, 22)
	_isi.add_child(_label_hitung)
	var terhubung := _sesi.perangkat.terhubung()
	var tombol := _tombol(Bahasa.t("netmgr.scan"), terhubung and not _memindai, _pindai)
	_isi.add_child(tombol)
	if not terhubung:
		_isi.add_child(_teks(Bahasa.t("netmgr.perlu_terhubung"), WARNA_TERKUNCI, 20))
	if _pesan_pindai != "":
		_isi.add_child(_teks(_pesan_pindai, WARNA_BAHAYA, 20))
	if not w.sudah_scan():
		_isi.add_child(_teks(Bahasa.t("netmgr.belum_scan"), WARNA_TERKUNCI, 22))
		return
	_isi.add_child(_teks(Bahasa.t("netmgr.ketuk_detail"), Tema.TEKS_REDUP, 19))
	for i in range(w.ditemukan.size()):
		var kartu := _kartu_jaringan(String(w.ditemukan[i]))
		kartu.modulate.a = 1.0 if (not _memindai or i < _reveal_n) else 0.0
		_isi.add_child(kartu)
		_baris_hasil.append(kartu)

func _teks_hitung() -> String:
	var w := _sesi.wifi
	if _memindai:
		return "%s %d/%d" % [Bahasa.t("netmgr.memindai"), _reveal_n, w.ditemukan.size()]
	if not w.sudah_scan():
		return ""
	return Bahasa.t("netmgr.selesai") % w.ditemukan.size()

func _kartu_jaringan(ssid: String) -> PanelContainer:
	var j := WifiLab.jaringan(ssid)
	var teks := VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.add_theme_constant_override("separation", 4)
	teks.add_child(_teks(ssid, Tema.TEKS, 26))
	teks.add_child(_teks("%s · %s %d · %s" % [String(j["bssid"]), Bahasa.t("netmgr.kol_kanal"), int(j["kanal"]), WifiLab.frekuensi(j)], Tema.TEKS_REDUP, 18))
	teks.add_child(_teks(Bahasa.t("netmgr.kol_keamanan") + ": " + String(j["enkripsi"]), _warna_keamanan(String(j["enkripsi"])), 19))
	var waktu := String(_sesi.wifi.waktu_lihat.get(ssid, ""))
	if waktu != "":
		teks.add_child(_teks(Bahasa.t("netmgr.kol_terlihat") + ": " + waktu, Tema.TEKS_REDUP, 17))
	var sinyal := NetmgrSinyal.new()
	sinyal.set_dbm(int(j["sinyal"]))
	sinyal.custom_minimum_size = Vector2(56, 36)
	var kanan := VBoxContainer.new()
	kanan.alignment = BoxContainer.ALIGNMENT_CENTER
	kanan.custom_minimum_size = Vector2(104, 0)
	kanan.add_child(sinyal)
	var dbm := _teks("%d dBm" % int(j["sinyal"]), Tema.TEKS_REDUP, 17)
	dbm.autowrap_mode = TextServer.AUTOWRAP_OFF
	kanan.add_child(dbm)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	baris.add_child(teks)
	baris.add_child(kanan)
	var kartu := _kartu([baris])
	_kartu_tekan(kartu, _pilih_jaringan.bind(ssid))
	return kartu

func _titik_radar(n: int) -> Array:
	var hasil: Array = []
	var daftar := _sesi.wifi.ditemukan
	for i in range(mini(n, daftar.size())):
		var ssid := String(daftar[i])
		var j := WifiLab.jaringan(ssid)
		var sudut := float(absi(ssid.hash()) % 360) * PI / 180.0
		var t := clampf((float(int(j["sinyal"])) + 80.0) / 40.0, 0.0, 1.0)
		hasil.append(Vector2(cos(sudut), sin(sudut)) * lerpf(0.92, 0.28, t))
	return hasil

func _pindai() -> void:
	if _memindai or not _sesi.perangkat.terhubung():
		return
	var keluaran := _jalankan("wifi-scanner --scan")
	_pesan_pindai = ""
	for b in keluaran:
		if String(b.get("tipe", "")) == "error":
			_pesan_pindai = ShellSession.teks_baris(b)
	if _pesan_pindai == "" and _sesi.wifi.sudah_scan():
		_mulai_reveal()
	else:
		_bangun_tab()

# Hasil pemindaian sudah tercatat. Jaringan ditampilkan satu per satu sambil radar bergerak,
# dan pemindaian dianggap selesai hanya setelah semua jaringan tampil.
func _mulai_reveal() -> void:
	_memindai = true
	_reveal_n = 0
	_timer_reveal.start()
	_bangun_tab()

func _langkah_reveal() -> void:
	var total := _sesi.wifi.ditemukan.size()
	_reveal_n += 1
	if _reveal_n > total:
		_selesai_reveal()
		return
	if _tab == "pindai":
		if _reveal_n - 1 < _baris_hasil.size():
			var baris: Control = _baris_hasil[_reveal_n - 1]
			create_tween().tween_property(baris, "modulate:a", 1.0, 0.3)
		if _radar != null:
			_radar.set_titik(_titik_radar(_reveal_n))
		if _label_hitung != null:
			_label_hitung.text = _teks_hitung()

func _selesai_reveal() -> void:
	_timer_reveal.stop()
	_memindai = false
	_sig = _signature()
	if _tab == "pindai":
		if _radar != null:
			_radar.set_aktif(false)
			_radar.set_titik(_titik_radar(_sesi.wifi.ditemukan.size()))
		if _label_hitung != null:
			_label_hitung.text = _teks_hitung()
		for baris in _baris_hasil:
			baris.modulate.a = 1.0

func _pilih_jaringan(ssid: String) -> void:
	_jalankan("network inspect " + ssid)
	_tab = "detail"
	_bangun_tab()

# ---------- Detail ----------

func _isi_detail() -> void:
	var w := _sesi.wifi
	var ssid := w.terpilih
	if ssid == "" or not w.terlihat(ssid):
		_isi.add_child(_teks(Bahasa.t("netmgr.detail_kosong"), WARNA_TERKUNCI, 22))
		return
	var j := WifiLab.jaringan(ssid)
	var dbm := int(j["sinyal"])
	_isi.add_child(_kartu([
		_teks(Bahasa.t("netmgr.d_identitas"), Tema.AMBER, 22),
		_teks(ssid, Tema.TEKS, 30),
		_grid([
			["BSSID", String(j["bssid"]), Tema.TEKS],
			[Bahasa.t("netmgr.k_vendor"), "%s %s" % [String(j["vendor"]), String(j["model"])], Tema.TEKS],
			[Bahasa.t("netmgr.kol_frekuensi"), WifiLab.frekuensi(j), Tema.TEKS],
			[Bahasa.t("netmgr.kol_kanal"), str(int(j["kanal"])), Tema.TEKS],
			[Bahasa.t("netmgr.k_lebar"), "%d MHz" % int(j["lebar_kanal"]), Tema.TEKS],
		]),
	]))
	var sinyal := NetmgrSinyal.new()
	sinyal.set_dbm(dbm)
	sinyal.custom_minimum_size = Vector2(160, 90)
	_isi.add_child(_kartu([
		_teks(Bahasa.t("netmgr.d_sinyal"), Tema.AMBER, 22),
		sinyal,
		_teks("%d dBm" % dbm, Tema.TEKS, 26),
	]))
	var enk := String(j["enkripsi"])
	var kelemahan_teks: Array = []
	for k in WifiLab.kelemahan(ssid):
		var t := WifiLab.tingkat_pair(String(k["tingkat"]))
		kelemahan_teks.append(_teks("[%s] %s" % [Bahasa.dua(t[0], t[1]), Bahasa.dua(String(k["id"]), String(k["en"]))], _warna_tingkat(String(k["tingkat"])), 19))
	var kartu_keamanan: Array = [
		_teks(Bahasa.t("netmgr.d_keamanan"), Tema.AMBER, 22),
		_teks(enk, _warna_keamanan(enk), 26),
		_grid([[Bahasa.t("netmgr.k_wps"), Bahasa.t("netmgr.wps_aktif") if bool(j["wps"]) else Bahasa.t("netmgr.wps_nonaktif"), Tema.TEKS]]),
	]
	kartu_keamanan.append_array(kelemahan_teks)
	_isi.add_child(_kartu(kartu_keamanan))
	_isi.add_child(_kartu([
		_teks(Bahasa.t("netmgr.d_konfigurasi"), Tema.AMBER, 22),
		_grid([
			[Bahasa.t("netmgr.k_klien"), str(int(j["klien"])), Tema.TEKS],
			[Bahasa.t("netmgr.k_wps"), Bahasa.t("netmgr.wps_aktif") if bool(j["wps"]) else Bahasa.t("netmgr.wps_nonaktif"), Tema.TEKS],
		]),
	]))
	var riwayat_isi: Array = [_teks(Bahasa.t("netmgr.d_riwayat"), Tema.AMBER, 22)]
	for e in w.riwayat_jaringan(ssid):
		riwayat_isi.append(_teks("%s · %s" % [String(e["waktu"]), Bahasa.t("netmgr.r_jumlah") % int(e["jumlah"])], Tema.TEKS_REDUP, 19))
	_isi.add_child(_kartu(riwayat_isi))
	var analisis_isi: Array = [_teks(Bahasa.t("netmgr.d_analisis"), Tema.AMBER, 22)]
	if w.dianalisis.has(ssid):
		var r := WifiLab.tingkat_pair(WifiLab.tingkat_risiko(ssid))
		analisis_isi.append(_teks(Bahasa.t("netmgr.a_tingkat") % Bahasa.dua(r[0], r[1]), _warna_tingkat(WifiLab.tingkat_risiko(ssid)), 24))
	else:
		analisis_isi.append(_teks(Bahasa.t("netmgr.d_belum_analisis"), WARNA_TERKUNCI, 19))
		analisis_isi.append(_tombol(Bahasa.t("netmgr.btn_analisis"), true, _analisis.bind(ssid)))
	_isi.add_child(_kartu(analisis_isi))
	_isi.add_child(_teks(Bahasa.t("netmgr.lewat_terminal"), Tema.TEKS_REDUP, 18))

func _analisis(ssid: String) -> void:
	_jalankan("security analyze " + ssid)
	_tab = "analisis"
	_bangun_tab()

# ---------- Analisis ----------

func _isi_analisis() -> void:
	var w := _sesi.wifi
	var daftar: Array = w.dianalisis.keys()
	daftar.sort()
	if daftar.is_empty():
		_isi.add_child(_teks(Bahasa.t("netmgr.a_kosong"), WARNA_TERKUNCI, 22))
		return
	for i in range(daftar.size()):
		var ssid := String(daftar[i])
		var kartu := _kartu_analisis(ssid)
		_isi.add_child(kartu)
		# Hasil ditampilkan bertahap, satu jaringan setiap saat.
		kartu.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.25 * float(i))
		tw.tween_property(kartu, "modulate:a", 1.0, 0.3)

func _kartu_analisis(ssid: String) -> PanelContainer:
	var w := _sesi.wifi
	var tingkat := WifiLab.tingkat_risiko(ssid)
	var r := WifiLab.tingkat_pair(tingkat)
	var isi: Array = [
		_teks(ssid, Tema.TEKS, 26),
		_teks(Bahasa.t("netmgr.a_tingkat") % Bahasa.dua(r[0], r[1]), _warna_tingkat(tingkat), 24),
		_teks(Bahasa.t("netmgr.a_temuan"), Tema.AMBER, 21),
	]
	var daftar := WifiLab.kelemahan(ssid)
	if daftar.is_empty():
		isi.append(_teks(Bahasa.t("netmgr.a_aman"), Tema.TEAL, 19))
	for k in daftar:
		var t := WifiLab.tingkat_pair(String(k["tingkat"]))
		isi.append(_teks("[%s] %s" % [Bahasa.dua(t[0], t[1]), Bahasa.dua(String(k["id"]), String(k["en"]))], _warna_tingkat(String(k["tingkat"])), 19))
	if not daftar.is_empty():
		isi.append(_teks(Bahasa.t("netmgr.a_rekomendasi"), Tema.AMBER, 21))
		for k in daftar:
			isi.append(_teks("- " + Bahasa.dua(String(k["rek_id"]), String(k["rek_en"])), Tema.TEKS, 19))
	isi.append(_teks(Bahasa.t("netmgr.a_periksa"), Tema.AMBER, 21))
	isi.append(_status_cek(w.handshake.has(ssid), "netmgr.a_handshake_ada", "netmgr.a_handshake_belum"))
	isi.append(_status_cek(w.kata_sandi_ditemukan.has(ssid), "netmgr.a_kata_ada", "netmgr.a_kata_belum"))
	isi.append(_status_cek(w.terakses.has(ssid), "netmgr.a_akses_ada", "netmgr.a_akses_belum"))
	return _kartu(isi, _warna_tingkat(tingkat))

func _status_cek(ya: bool, kunci_ya: String, kunci_tidak: String) -> Label:
	return _teks(("[x] " if ya else "[ ] ") + Bahasa.t(kunci_ya if ya else kunci_tidak), Tema.TEAL if ya else Tema.AMBER, 19)

# ---------- Riwayat ----------

func _isi_riwayat() -> void:
	var w := _sesi.wifi
	if w.riwayat.is_empty():
		_isi.add_child(_teks(Bahasa.t("netmgr.riwayat_kosong"), WARNA_TERKUNCI, 22))
		return
	for i in range(w.riwayat.size()):
		var e: Dictionary = w.riwayat[i]
		var terbuka := bool(_terbuka.get(i, false))
		var isi: Array = [
			_teks("%s · %s" % [String(e["waktu"]), Bahasa.t("netmgr.r_jumlah") % int(e["jumlah"])], Tema.TEKS, 22),
		]
		if terbuka:
			var perangkat_id := String(e.get("perangkat", ""))
			var nama_perangkat := String(Perangkat.info(perangkat_id).get("nama", "-")) if perangkat_id != "" else "-"
			isi.append(_teks(Bahasa.t("netmgr.r_perangkat") % nama_perangkat, Tema.TEKS_REDUP, 19))
			for ssid in e["jaringan"]:
				var nama := String(ssid)
				var analisis := Dictionary(e["analisis"])
				var catatan := ""
				if analisis.has(nama):
					var r := WifiLab.tingkat_pair(String(analisis[nama]))
					catatan = "  ·  " + Bahasa.dua(r[0], r[1])
				isi.append(_teks("- %s%s" % [nama, catatan], Tema.TEKS, 19))
			var dipilih := String(e.get("dipilih", ""))
			isi.append(_teks(Bahasa.t("netmgr.r_dipilih") % dipilih if dipilih != "" else Bahasa.t("netmgr.r_tidak_dipilih"), Tema.AMBER, 19))
		var kartu := _kartu(isi)
		_kartu_tekan(kartu, _buka_riwayat.bind(i))
		_isi.add_child(kartu)

func _buka_riwayat(i: int) -> void:
	_terbuka[i] = not bool(_terbuka.get(i, false))
	_bangun_tab()

# ---------- Sinkronisasi dengan Terminal ----------

func _signature() -> String:
	var w := _sesi.wifi
	return "%d|%s|%s|%s|%s|%s|%s|%s" % [w.riwayat.size(), str(w.ditemukan), w.terpilih, str(w.dianalisis.keys()), str(w.handshake.keys()), str(w.kata_sandi_ditemukan.keys()), str(w.terakses.keys()), _sesi.perangkat.status()]

# Memeriksa perubahan dari Terminal. Pemindaian baru dari Terminal juga ditampilkan bertahap.
func _periksa() -> void:
	if _memindai:
		return
	var sig := _signature()
	if sig == _sig:
		return
	_sig = sig
	var n := _sesi.wifi.riwayat.size()
	if n > _jumlah_riwayat and _sesi.wifi.sudah_scan():
		_jumlah_riwayat = n
		_mulai_reveal()
		return
	_jumlah_riwayat = n
	_bangun_tab()

# Menjalankan perintah lewat sesi yang sama dengan Terminal, lalu menyimpan dan memperbarui misi.
func _jalankan(perintah: String) -> Array:
	var keluaran := _sesi.jalankan(perintah)
	_sesi.permintaan_aplikasi = ""
	Misi.perbarui(_sesi)
	Penyimpanan.simpan_sesi(_sesi)
	_sig = _signature()
	_jumlah_riwayat = _sesi.wifi.riwayat.size()
	return keluaran

# ---------- Warna dan komponen bersama ----------

func _warna_keamanan(enk: String) -> Color:
	match enk:
		"WEP":
			return WARNA_BAHAYA
		"WPA3":
			return Tema.TEAL
	return Tema.AMBER

func _warna_tingkat(tingkat: String) -> Color:
	match tingkat:
		"tinggi":
			return WARNA_BAHAYA
		"sedang":
			return Tema.AMBER
	return Tema.TEAL

func _kartu(isi: Array, batas: Color = Tema.TEAL) -> PanelContainer:
	var kartu := PanelContainer.new()
	# Sentuhan geser diteruskan ke daftar agar layar bisa digulir ke atas dan bawah.
	kartu.mouse_filter = Control.MOUSE_FILTER_PASS
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, batas, 2, 14))
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 14)
	kartu.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	for c in isi:
		v.add_child(c)
	return kartu

# Kartu yang bisa diketuk. Gulir tetap berfungsi karena sentuhan tidak ditelan.
func _kartu_tekan(kartu: Control, aksi: Callable) -> void:
	kartu.mouse_filter = Control.MOUSE_FILTER_PASS
	var awal := [Vector2.ZERO]
	kartu.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := ev as InputEventMouseButton
			if mb.pressed:
				awal[0] = mb.position
			elif mb.position.distance_to(awal[0]) < 24.0:
				aksi.call())

func _tombol(teks: String, aktif: bool, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not aktif
	b.custom_minimum_size = Vector2(0, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(aksi)
	_efek_tekan(b)
	return b

# Tombol mengecil sedikit saat ditekan, lalu kembali saat dilepas.
func _efek_tekan(b: BaseButton) -> void:
	b.pivot_offset_ratio = Vector2(0.5, 0.5)
	b.button_down.connect(func(): create_tween().tween_property(b, "scale", Vector2(0.96, 0.96), 0.08))
	b.button_up.connect(func(): create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))

# Baris label dan nilai dalam dua kolom yang rapi.
func _grid(pasangan: Array) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 6)
	for p in pasangan:
		var a := _teks(String(p[0]), Tema.TEKS_REDUP, 19)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		a.size_flags_stretch_ratio = 0.9
		var b := _teks(String(p[1]), p[2] if p.size() > 2 else Tema.TEKS, 19)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = 1.1
		g.add_child(a)
		g.add_child(b)
	return g

func _teks(isi: String, warna: Color = Tema.TEKS, ukuran: int = 22) -> Label:
	var l := Tema.label(isi, warna, ukuran)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
