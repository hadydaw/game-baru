class_name PusatMisi
extends Control

# Aplikasi Misi: pesan masuk, misi aktif, dan misi selesai. Membaca sesi yang sama dengan Terminal.
# Misi yang belum diterima tidak ditampilkan, supaya pemain menemukan misi lewat pesan.

const WARNA_SELESAI := Color(0.55, 0.62, 0.6)

var _sesi: ShellSession
var _kolom: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesi = SesiUtama.ambil()
	var latar := ColorRect.new()
	latar.color = Color("0d1117")
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var gulir := ScrollContainer.new()
	gulir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(gulir)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tema.margin_seragam(margin, 20)
	gulir.add_child(margin)
	_kolom = VBoxContainer.new()
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_constant_override("separation", 14)
	margin.add_child(_kolom)
	_segarkan()

func _segarkan() -> void:
	for anak in _kolom.get_children():
		anak.queue_free()
	_kolom.add_child(Tema.label(Bahasa.t("misi.judul"), Tema.TEAL, 34))
	_kolom.add_child(_bagian(Bahasa.t("misi.pesan_masuk")))
	if _sesi.pesan_misi.is_empty():
		_kolom.add_child(_teks(Bahasa.t("misi.belum_pesan"), Tema.TEKS_REDUP))
	var terbaru := _sesi.pesan_misi.duplicate()
	terbaru.reverse()
	for p in terbaru:
		_kartu_pesan(p)  # kartu sudah masuk kolom
	var aktif: Array = []
	var selesai: Array = []
	for m in Misi.daftar():
		var st := String(_sesi.misi.get(String(m["id"]), ""))
		if st == "aktif":
			aktif.append(m)
		elif st == "selesai":
			selesai.append(m)
	_kolom.add_child(_bagian(Bahasa.t("misi.aktif")))
	if aktif.is_empty():
		_kolom.add_child(_teks(Bahasa.t("misi.tidak_aktif"), Tema.TEKS_REDUP))
	for m in aktif:
		_kartu_misi(m, false)  # kartu sudah masuk kolom
	_kolom.add_child(_bagian(Bahasa.t("misi.selesai")))
	if selesai.is_empty():
		_kolom.add_child(_teks(Bahasa.t("misi.belum_selesai"), Tema.TEKS_REDUP))
	for m in selesai:
		_kartu_misi(m, true)  # kartu sudah masuk kolom

func _bagian(judul: String) -> Label:
	var l := Tema.label("— " + judul, Tema.AMBER, 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _teks(isi: String, warna: Color) -> Label:
	var l := Tema.label(isi, warna, 22)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

func _teks_hadiah(id: String) -> String:
	var h: Dictionary = Hadiah.data().get(id, {})
	if h.is_empty():
		return Bahasa.t("misi.hadiah_kosong")
	var bagian: Array = [Bahasa.t("panel.saldo") % int(h.get("kredit", 0))]
	for g in h.get("reputasi", {}):
		bagian.append(Bahasa.t("misi.reputasi") % [g, int(h["reputasi"][g])])
	return Bahasa.t("misi.hadiah") + ", ".join(PackedStringArray(bagian))
