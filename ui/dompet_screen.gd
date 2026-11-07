class_name DompetScreen
extends Control

# Dompet: saldo kredit, XP, dan reputasi per grup. Hanya membaca keadaan sesi yang sama dengan Terminal.

var _sesi: ShellSession
var _kolom: VBoxContainer

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
	_kolom = VBoxContainer.new()
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_constant_override("separation", 12)
	margin.add_child(_kolom)
	Bahasa.daftar_penyegar(self, _segarkan)

func _segarkan() -> void:
	for c in _kolom.get_children():
		c.queue_free()
	_kolom.add_child(_teks(Bahasa.t("dompet.judul"), Tema.TEAL, 34))
	_kolom.add_child(_teks(Bahasa.t("dompet.saldo") % _sesi.economy.saldo, Tema.AMBER, 28))
	_kolom.add_child(_teks(Bahasa.t("dompet.xp") % _sesi.xp, Tema.TEKS, 24))
	_kolom.add_child(_teks(Bahasa.t("dompet.reputasi"), Tema.TEKS_REDUP, 22))
	var grup: Dictionary = Economy.data_ekonomi().get("grup", {})
	var ids := grup.keys()
	ids.sort()
	for id in ids:
		var nilai := _sesi.reputation.get_nilai(String(id))
		_kolom.add_child(_teks(Bahasa.t("dompet.grup") % [Reputation.nama_grup(String(id)), nilai, Reputation.tingkat_teks(nilai)], Tema.TEKS, 22))

func _teks(isi: String, warna: Color, ukuran: int) -> Label:
	var l := Label.new()
	l.text = isi
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", warna)
	l.add_theme_font_size_override("font_size", ukuran)
	return l
