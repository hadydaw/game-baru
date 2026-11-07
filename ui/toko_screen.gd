class_name TokoScreen
extends Control

# Toko Perangkat: membeli komponen perangkat keras dengan saldo pemain. Memakai logika yang sama
# dengan Perangkat.beli(), sehingga status dan misi selalu sinkron dengan perintah sebelumnya.

const WARNA_TERKUNCI := Color(0.55, 0.62, 0.6)

var _sesi: ShellSession
var _kolom: VBoxContainer
var _pesan: Label

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
	_kolom.add_child(_teks(Bahasa.t("toko.judul"), Tema.TEAL, 34))
	_kolom.add_child(_teks(Bahasa.t("dompet.saldo") % _sesi.economy.saldo, Tema.AMBER, 24))
	for id in Perangkat.semua_id():
		var it := Perangkat.info(String(id))
		if bool(it.get("tidak_dijual", false)):
			continue
		_kolom.add_child(_baris_item(String(id), it))
	_pesan = _teks("", Tema.AMBER, 22)
	_kolom.add_child(_pesan)

func _baris_item(id: String, it: Dictionary) -> PanelContainer:
	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 14))
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 14)
	kartu.add_child(m)
	var baris := VBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	m.add_child(baris)
	var harga := int(it["harga"])
	var nama := String(it["nama"])
	baris.add_child(_teks(nama, Tema.TEKS, 26))
	baris.add_child(_teks(Bahasa.t("toko.baris") % [id, harga, _sesi.perangkat.jumlah(id)], Tema.TEKS_REDUP, 20))
	var tombol := Button.new()
	tombol.text = Bahasa.t("toko.beli")
	tombol.custom_minimum_size = Vector2(0, 72)
	tombol.add_theme_font_size_override("font_size", 24)
	tombol.disabled = not _sesi.economy.bisa_bayar(harga)
	tombol.pressed.connect(_beli.bind(id))
	baris.add_child(tombol)
	return kartu

func _beli(id: String) -> void:
	var h := _sesi.perangkat.beli(id, _sesi.economy)
	if bool(h["ok"]):
		_sesi.jaringan.buka("beli:" + id)
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)
		_pesan.text = Bahasa.t("toko.berhasil") % String(Perangkat.info(id)["nama"])
		_segarkan()
	else:
		_pesan.text = Bahasa.t("toko.gagal") % (Bahasa.t(String(h["kunci"])) % h.get("args", []))

func _teks(isi: String, warna: Color, ukuran: int) -> Label:
	var l := Label.new()
	l.text = isi
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", warna)
	l.add_theme_font_size_override("font_size", ukuran)
	return l
