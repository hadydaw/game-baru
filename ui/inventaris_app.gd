class_name InventarisApp
extends Control

# Inventaris: ringkasan keadaan pemain dari sesi yang sama dengan Terminal, Pasar, Device Manager,
# Tools Repository, dan Misi. Tidak menyimpan data sendiri, jadi selalu sejalan dengan sistem lain.

const WARNA_REDUP := Color(0.55, 0.62, 0.6)

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
	var gulir := ScrollContainer.new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(gulir)
	_kolom = VBoxContainer.new()
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_constant_override("separation", 10)
	gulir.add_child(_kolom)
	Bahasa.daftar_penyegar(self, _segarkan)

func _segarkan() -> void:
	for c in _kolom.get_children():
		c.queue_free()
	var s := _sesi
	_kolom.add_child(_teks(Bahasa.t("inv.judul"), Tema.TEAL, 34))
	_kolom.add_child(_teks(Bahasa.t("inv.saldo") % s.economy.saldo, Tema.TEKS, 24))
	_kolom.add_child(_teks(Bahasa.t("inv.xp") % s.xp, Tema.TEKS, 24))
	_kolom.add_child(_bagian(Bahasa.t("inv.reputasi")))
	var grup: Dictionary = Economy.data_ekonomi().get("grup", {})
	var ids := grup.keys()
	ids.sort()
	for id in ids:
		var nilai := s.reputation.get_nilai(String(id))
		_kolom.add_child(_teks("%s: %d (%s)" % [Reputation.nama_grup(String(id)), nilai, Reputation.tingkat_teks(nilai)], Tema.TEKS, 22))
	_kolom.add_child(_bagian(Bahasa.t("inv.tool")))
	_daftar(s.inventory.milik.keys().map(func(id): return "%s  T%d" % [ToolDefs.nama(String(id)), s.inventory.tingkat(String(id))]), "inv.tool_kosong")
	_kolom.add_child(_bagian(Bahasa.t("inv.komponen")))
	var komp_dict: Dictionary = s.perangkat.dimiliki_dan_terpasang()
	var komp := komp_dict.keys()
	komp.sort()
	_daftar(komp.map(func(id): return "%s  x%d" % [String(Perangkat.info(String(id))["nama"]), int(komp_dict[id])]), "inv.komponen_kosong")
	_kolom.add_child(_bagian(Bahasa.t("inv.software")))
	var sw := s.repositori.terpasang.keys()
	sw.sort()
	_daftar(sw.map(func(id): return "%s  v%s" % [String(Repositori.item(String(id))["nama"]), s.repositori.versi(String(id))]), "inv.software_kosong")
	_kolom.add_child(_bagian(Bahasa.t("inv.misi")))
	var misi_ids := s.misi.keys()
	misi_ids.sort()
	var daftar_misi: Array = []
	for id in misi_ids:
		var m := Misi.temukan(String(id))
		var status := "[x]" if String(s.misi[id]) == "selesai" else "[ ]"
		daftar_misi.append("%s %s" % [status, Bahasa.pilih(String(m.get("judul", id)))])
	_daftar(daftar_misi, "inv.misi_kosong")
	_kolom.add_child(_bagian(Bahasa.t("inv.hadiah")))
	_daftar(s.hadiah_diambil, "inv.hadiah_kosong")

func _daftar(baris: Array, kunci_kosong: String) -> void:
	if baris.is_empty():
		_kolom.add_child(_teks(Bahasa.t(kunci_kosong), WARNA_REDUP, 20))
		return
	for b in baris:
		_kolom.add_child(_teks(String(b), Tema.TEKS, 22))

func _bagian(teks: String) -> Label:
	return _teks(teks, Tema.AMBER, 24)

func _teks(isi: String, warna: Color, ukuran: int) -> Label:
	var l := Tema.label(isi, warna, ukuran)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
