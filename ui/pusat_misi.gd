class_name PusatMisi
extends Control

# Aplikasi Misi. Tampilan awal berupa "Misi Tersedia": kisi kategori dengan ikon.
# Memilih kategori lalu PILIH membuka daftar misi di kategori itu: pesan masuk, misi aktif, dan misi selesai.
# Membaca sesi yang sama dengan Terminal. Misi yang belum diterima tidak ditampilkan.

const WARNA_SELESAI := Color(0.55, 0.62, 0.6)
const LATAR_KARTU := Color(0.04, 0.07, 0.09, 1.0)

var _sesi: ShellSession
var _terpilih := ""              # kunci kategori yang sedang dipilih di kisi
var _tampil_daftar := ""         # kunci kategori yang daftarnya sedang tampil; "" = kisi kategori
var _judul: Label
var _kisi_wrap: VBoxContainer
var _grid: GridContainer
var _tombol_kategori: Dictionary = {}
var _daftar_wrap: VBoxContainer
var _kolom: VBoxContainer
var _hint: Label
var _bawah: HBoxContainer

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
	Tema.margin_seragam(margin, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	_judul = Tema.label("", Tema.TEAL, 34)
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_judul)

	# Kisi kategori.
	_kisi_wrap = VBoxContainer.new()
	_kisi_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_kisi_wrap)
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_kisi_wrap.add_child(gulir)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	gulir.add_child(_grid)

	# Daftar misi dalam satu kategori.
	_daftar_wrap = VBoxContainer.new()
	_daftar_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_daftar_wrap.visible = false
	root.add_child(_daftar_wrap)
	var gulir_daftar := ScrollContainer.new()
	gulir_daftar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir_daftar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_daftar_wrap.add_child(gulir_daftar)
	_kolom = VBoxContainer.new()
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_constant_override("separation", 14)
	gulir_daftar.add_child(_kolom)

	_hint = Tema.label("", Tema.AMBER, 22)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	# Tombol bawah: KELUAR dan PILIH, sama seperti pola tombol di layar lain.
	_bawah = HBoxContainer.new()
	_bawah.add_theme_constant_override("separation", 14)
	root.add_child(_bawah)

	Bahasa.daftar_penyegar(self, _segarkan_semua)

func _segarkan_semua() -> void:
	_judul.text = Bahasa.t("misi.judul_tersedia") if _tampil_daftar == "" else Bahasa.t(_judul_kategori(_tampil_daftar))
	_bangun_kisi()
	_bangun_daftar()
	_bangun_tombol()
	_kisi_wrap.visible = _tampil_daftar == ""
	_daftar_wrap.visible = _tampil_daftar != ""
	if _tampil_daftar == "":
		_hint.text = ""

func _judul_kategori(kunci: String) -> String:
	for k in Misi.KATEGORI:
		if String(k["kunci"]) == kunci:
			return String(k["judul"])
	return "misi.judul_tersedia"

# Kisi kategori: setiap sel berisi ikon, nama kategori, dan jumlah misi.
func _bangun_kisi() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_tombol_kategori.clear()
	for k in Misi.KATEGORI:
		var kunci := String(k["kunci"])
		var tombol := Button.new()
		tombol.focus_mode = Control.FOCUS_NONE
		tombol.custom_minimum_size = Vector2(0, 250)
		tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dipilih := kunci == _terpilih
		var batas := Tema.AMBER if dipilih else Tema.TEAL
		tombol.add_theme_stylebox_override("normal", Tema.kotak(LATAR_KARTU, batas, 3 if dipilih else 2, 14))
		tombol.add_theme_stylebox_override("hover", Tema.kotak(LATAR_KARTU, Tema.AMBER, 3, 14))
		tombol.add_theme_stylebox_override("pressed", Tema.kotak(LATAR_KARTU, Tema.AMBER, 3, 14))
		tombol.add_theme_stylebox_override("focus", Tema.kotak(LATAR_KARTU, Tema.AMBER, 3, 14))

		var pad := MarginContainer.new()
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		Tema.margin_seragam(pad, 14)
		tombol.add_child(pad)
		var isi := VBoxContainer.new()
		isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.alignment = BoxContainer.ALIGNMENT_CENTER
		isi.add_theme_constant_override("separation", 10)
		pad.add_child(isi)

		var ikon := TextureRect.new()
		ikon.texture = load(Misi.ikon_kategori(kunci)) as Texture2D
		ikon.custom_minimum_size = Vector2(0, 110)
		ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.add_child(ikon)

		var nama := Tema.label("", Tema.TEKS, 24)
		nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		isi.add_child(nama)
		Bahasa.isi(nama, String(k["judul"]))

		var jumlah := Tema.label("", Tema.TEKS_REDUP, 20)
		jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi.add_child(jumlah)
		var banyak := Misi.daftar_kategori(kunci).size()
		Bahasa.daftar_penyegar(jumlah, func():
			if is_instance_valid(jumlah):
				jumlah.text = Bahasa.t("misi.jumlah") % banyak if banyak > 0 else Bahasa.t("misi.belum_ada_kategori"))

		tombol.pressed.connect(_pilih_kategori.bind(kunci))
		_grid.add_child(tombol)
		_tombol_kategori[kunci] = tombol

func _pilih_kategori(kunci: String) -> void:
	_terpilih = kunci
	_hint.text = ""
	_bangun_kisi()
	_bangun_tombol()

# Daftar misi kategori terpilih: pesan masuk, misi aktif, lalu misi selesai.
func _bangun_daftar() -> void:
	for c in _kolom.get_children():
		c.queue_free()
	if _tampil_daftar == "":
		return
	var misi_kat := Misi.daftar_kategori(_tampil_daftar)
	var id_kat := {}
	for m in misi_kat:
		id_kat[String(m["id"])] = true
	if misi_kat.is_empty():
		_kolom.add_child(_teks_kunci("misi.kategori_kosong", Tema.TEKS_REDUP))
		return
	var pesan_kat: Array = []
	for p in _sesi.pesan_misi:
		if id_kat.has(String(p.get("misi", ""))):
			pesan_kat.append(p)
	pesan_kat.reverse()
	if not pesan_kat.is_empty():
		_kolom.add_child(_teks_kunci("misi.pesan_masuk", Tema.AMBER, true))
		for p in pesan_kat:
			_kartu_pesan(p)
	var aktif: Array = []
	var selesai: Array = []
	for m in misi_kat:
		var st := String(_sesi.misi.get(String(m["id"]), ""))
		if st == "aktif":
			aktif.append(m)
		elif st == "selesai":
			selesai.append(m)
	_kolom.add_child(_teks_kunci("misi.aktif", Tema.AMBER, true))
	if aktif.is_empty():
		_kolom.add_child(_teks_kunci("misi.tidak_aktif", Tema.TEKS_REDUP))
	for m in aktif:
		_kartu_misi(m, false)
	_kolom.add_child(_teks_kunci("misi.selesai", Tema.AMBER, true))
	if selesai.is_empty():
		_kolom.add_child(_teks_kunci("misi.belum_selesai", Tema.TEKS_REDUP))
	for m in selesai:
		_kartu_misi(m, true)

# Tombol bawah. Di kisi: KELUAR membatalkan pilihan, PILIH membuka kategori terpilih.
# Di daftar: KELUAR kembali ke kisi.
func _bangun_tombol() -> void:
	for c in _bawah.get_children():
		c.queue_free()
	if _tampil_daftar != "":
		var kembali := _tombol_bawah("misi.tombol_keluar", Tema.TEKS_REDUP)
		kembali.pressed.connect(func():
			_tampil_daftar = ""
			_segarkan_semua())
		_bawah.add_child(kembali)
		return
	var keluar := _tombol_bawah("misi.tombol_keluar", Tema.TEKS_REDUP)
	keluar.pressed.connect(func():
		_terpilih = ""
		_hint.text = ""
		_bangun_kisi())
	_bawah.add_child(keluar)
	var pilih := _tombol_bawah("misi.tombol_pilih", Tema.TEAL)
	pilih.disabled = _terpilih == ""
	pilih.pressed.connect(func():
		if _terpilih == "":
			Bahasa.isi(_hint, "misi.pilih_kategori")
			return
		_tampil_daftar = _terpilih
		_segarkan_semua())
	_bawah.add_child(pilih)

func _tombol_bawah(kunci: String, warna_batas: Color) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Tema.TEKS)
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.45, 0.45))
	b.add_theme_stylebox_override("normal", Tema.kotak(Color(0.05, 0.1, 0.12), warna_batas, 2, 16))
	b.add_theme_stylebox_override("hover", Tema.kotak(Color(0.08, 0.18, 0.2), warna_batas, 2, 16))
	b.add_theme_stylebox_override("pressed", Tema.kotak(Color(0.08, 0.18, 0.2), warna_batas, 2, 16))
	b.add_theme_stylebox_override("disabled", Tema.kotak(Color(0.05, 0.06, 0.07), Color(0.25, 0.3, 0.3), 2, 16))
	Bahasa.isi(b, kunci)
	return b

func _bagian(kunci: String) -> Label:
	var l := Tema.label("", Tema.AMBER, 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Bahasa.isi(l, kunci)
	return l

func _teks_kunci(kunci: String, warna: Color, bagian := false) -> Label:
	var l := Tema.label("", warna, 22)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if bagian:
		Bahasa.daftar_penyegar(l, func():
			if is_instance_valid(l):
				l.text = "— " + Bahasa.t(kunci))
	else:
		Bahasa.isi(l, kunci)
	return l

# Kartu berisi kolom vertikal. Kolom diambil dengan isi_kartu(kartu).
func _kartu(warna_batas: Color) -> PanelContainer:
	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, warna_batas, 2, 14))
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_child(kartu)
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 16)
	kartu.add_child(m)
	var isi := VBoxContainer.new()
	isi.add_theme_constant_override("separation", 8)
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(isi)
	return kartu

func isi_kartu(kartu: PanelContainer) -> VBoxContainer:
	return kartu.get_child(0).get_child(0) as VBoxContainer

func _kartu_pesan(p: Dictionary) -> PanelContainer:
	var kartu := _kartu(Tema.TEKS_REDUP)
	var isi := isi_kartu(kartu)
	isi.add_child(Tema.label("%s  ·  %s" % [p["dari"], p["subjek"]], Tema.TEAL, 22))
	isi.add_child(_teks(String(p["isi"]), Tema.TEKS))
	return kartu

func _kartu_misi(m: Dictionary, selesai: bool) -> PanelContainer:
	var kartu := _kartu(Tema.TEAL if not selesai else Tema.TEKS_REDUP)
	var isi := isi_kartu(kartu)
	var judul := String(m["judul"])
	isi.add_child(Tema.label((Bahasa.t("misi.tag_selesai") if selesai else "") + judul, WARNA_SELESAI if selesai else Tema.TEAL, 28))
	isi.add_child(_teks(Bahasa.t("misi.dari") % m["pengirim"], Tema.TEKS_REDUP))
	isi.add_child(_teks(String(m["latar"]), Tema.TEKS))
	isi.add_child(_teks(Bahasa.t("misi.target") % Misi.ganti_ip(_sesi, String(m["target"])), Tema.TEKS))
	if m.has("node"):
		isi.add_child(_teks(Bahasa.t("misi.ip_target") % _sesi.jaringan.ip(String(m["node"])), Tema.TEAL))
	var petunjuk := Misi.petunjuk_ditemukan(_sesi, m)
	isi.add_child(_teks(Bahasa.t("misi.petunjuk") % [petunjuk.size(), m.get("petunjuk", []).size()], Tema.TEKS_REDUP))
	for t in petunjuk:
		isi.add_child(_teks("· " + String(t), Tema.TEKS))
	isi.add_child(_teks(Bahasa.t("misi.tujuan"), Tema.TEKS))
	for t in Misi.status_tujuan(_sesi, m):
		var tanda := "[x] " if bool(t["selesai"]) else "[ ] "
		isi.add_child(_teks(tanda + String(t["teks"]), Tema.TEAL if bool(t["selesai"]) else Tema.TEKS))
	isi.add_child(_teks(_teks_hadiah(String(m["id"])), Tema.TEKS_REDUP))
	return kartu

func _teks(isi: String, warna: Color) -> Label:
	var l := Tema.label(isi, warna, 22)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _teks_hadiah(id: String) -> String:
	var h: Dictionary = Hadiah.data().get(id, {})
	if h.is_empty():
		return Bahasa.t("misi.hadiah_kosong")
	var bagian: Array = [Bahasa.t("panel.saldo") % int(h.get("kredit", 0))]
	for g in h.get("reputasi", {}):
		bagian.append(Bahasa.t("misi.reputasi") % [g, int(h["reputasi"][g])])
	return Bahasa.t("misi.hadiah") + ", ".join(PackedStringArray(bagian))
