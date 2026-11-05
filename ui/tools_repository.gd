class_name ToolsRepository
extends Control

# Tools Repository: cari, pasang, dan perbarui software serta driver. Memakai Repositori dan
# sesi yang sama dengan perintah tools di Terminal, sehingga status keduanya selalu sama.

const WARNA_TERKUNCI := Color(0.55, 0.62, 0.6)

var _sesi: ShellSession
var _cari: LineEdit
var _daftar: VBoxContainer
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
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	margin.add_child(kolom)
	kolom.add_child(Tema.label(Bahasa.t("repo.judul_repo"), Tema.TEAL, 32))
	_cari = LineEdit.new()
	_cari.custom_minimum_size = Vector2(0, 64)
	_cari.text_changed.connect(func(_t): _segarkan())
	kolom.add_child(_cari)
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(gulir)
	_daftar = VBoxContainer.new()
	_daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_theme_constant_override("separation", 10)
	gulir.add_child(_daftar)
	_pesan = Tema.label("", Tema.AMBER, 20)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(_pesan)
	Bahasa.daftar_penyegar(self, _segarkan)

func _segarkan() -> void:
	_cari.placeholder_text = Bahasa.t("repo.cari")
	for c in _daftar.get_children():
		c.queue_free()
	var ids := Repositori.cari(_cari.text)
	if ids.is_empty():
		_daftar.add_child(Tema.label(Bahasa.t("repo.kosong"), WARNA_TERKUNCI, 22))
		return
	for id in ids:
		_daftar.add_child(_kartu(String(id)))

func _kartu(id: String) -> PanelContainer:
	var it := Repositori.item(id)
	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Color(0.06, 0.09, 0.12), Tema.TEAL, 1, 12))
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 12)
	kartu.add_child(m)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	m.add_child(baris)
	var teks := VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(teks)
	teks.add_child(Tema.label("%s  v%s" % [String(it["nama"]), String(it["versi"])], Tema.TEKS, 24))
	teks.add_child(Tema.label(Bahasa.t("repo.ukuran") % [String(it["ukuran"]), int(it["harga"])], Tema.TEKS_REDUP, 18))
	teks.add_child(Tema.label(Bahasa.t(String(it["deskripsi_kunci"])), Tema.TEKS_REDUP, 18))
	var deps: Array = it.get("deps", [])
	if not deps.is_empty():
		teks.add_child(Tema.label(Bahasa.t("repo.dep_kurang") % ", ".join(PackedStringArray(deps)), Tema.AMBER, 18))
	var tombol := Button.new()
	tombol.custom_minimum_size = Vector2(170, 72)
	if not _sesi.repositori.punya(id):
		tombol.text = Bahasa.t("repo.pasang")
		tombol.pressed.connect(_pasang.bind(id))
	elif _sesi.repositori.versi(id) != String(it["versi"]):
		tombol.text = Bahasa.t("repo.perbarui")
		tombol.pressed.connect(_perbarui.bind(id))
	else:
		tombol.text = Bahasa.t("repo.terpasang_label")
		tombol.disabled = true
	baris.add_child(tombol)
	return kartu

func _pasang(id: String) -> void:
	var h := _sesi.repositori.pasang(id, _sesi.economy, _sesi.perangkat)
	if bool(h["ok"]):
		_sesi.jaringan.buka("pasang:" + id)
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)
	_pesan.text = Bahasa.t(String(h["kunci"])) % Array(h.get("args", []))
	_segarkan()

func _perbarui(id: String) -> void:
	var h := _sesi.repositori.perbarui(id)
	if bool(h["ok"]):
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)
	_pesan.text = Bahasa.t(String(h["kunci"])) % Array(h.get("args", []))
	_segarkan()
