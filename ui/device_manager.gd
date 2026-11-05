class_name DeviceManager
extends Control

# Device Manager: komponen yang dimiliki dan perangkat yang dirakit. Tombol memanggil logika yang sama
# dengan perintah device di Terminal (Perangkat dan PerangkatCommands), sehingga status selalu sama.

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
	_kolom.add_child(_teks(Bahasa.t("perangkat.judul"), Tema.TEAL, 34))
	_kolom.add_child(_bagian(Bahasa.t("perangkat.komponen")))
	var ids := _sesi.perangkat.dimiliki_dan_terpasang().keys()
	ids.sort()
	if ids.is_empty():
		_kolom.add_child(_teks(Bahasa.t("perangkat.kosong"), WARNA_TERKUNCI, 22))
	for id in ids:
		_kolom.add_child(_teks("%s  x%d  ·  %s" % [String(Perangkat.info(String(id))["nama"]), int(_sesi.perangkat.dimiliki_dan_terpasang()[id]), _status_komponen(String(id))], Tema.TEKS, 22))
	_kolom.add_child(_bagian(Bahasa.t("perangkat.status")))
	_kolom.add_child(_kartu_status())
	_pesan = _teks("", Tema.AMBER, 22)
	_kolom.add_child(_pesan)
	_kolom.add_child(_tombol_tindakan())

# Status tiap komponen: dimiliki, terpasang di rakitan, atau berasal dari misi.
func _status_komponen(id: String) -> String:
	var p := _sesi.perangkat
	if id == Perangkat.ID_KIT:
		return Bahasa.t("dm.st_misi")
	if p.sudah_dirakit() and (id == p.adapter() or Perangkat.info(id).get("tipe", "") == "antena"):
		return Bahasa.t("dm.st_terpasang")
	return Bahasa.t("dm.st_dimiliki")

func _kartu_status() -> PanelContainer:
	var kartu := PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 14))
	var m := MarginContainer.new()
	Tema.margin_seragam(m, 16)
	kartu.add_child(m)
	var isi := VBoxContainer.new()
	isi.add_theme_constant_override("separation", 8)
	m.add_child(isi)
	var p := _sesi.perangkat
	if not p.sudah_dirakit():
		isi.add_child(_teks(Bahasa.t("perangkat.belum_rakit"), Tema.TEKS_REDUP, 22))
		return kartu
	isi.add_child(_teks(String(Perangkat.info(p.adapter())["nama"]), Tema.TEKS, 26))
	var status := Bahasa.t("dev.terhubung") if p.terhubung() else Bahasa.t("dev.tidak_terhubung")
	var driver := p.driver_aktif() if p.driver_aktif() != "" else Bahasa.t("dev.belum_driver")
	isi.add_child(_teks(Bahasa.t("perangkat.rincian") % [p.antena(), status, driver], Tema.TEKS_REDUP, 22))
	isi.add_child(_teks(_kompatibilitas(), Tema.AMBER if not _kompatibel() else Tema.TEAL, 21))
	return kartu

# Chipset adapter dicocokkan dengan driver yang benar-benar terpasang di Tools Repository.
func _kompatibel() -> bool:
	var p := _sesi.perangkat
	var chipset := Perangkat.chipset_adapter(p.adapter())
	var drv := p.driver_aktif()
	return drv != "" and _sesi.repositori.punya(drv) and Array(Repositori.item(drv).get("chipset", [])).has(chipset)

func _kompatibilitas() -> String:
	var p := _sesi.perangkat
	var chipset := Perangkat.chipset_adapter(p.adapter())
	if p.driver_aktif() == "":
		return Bahasa.t("dm.kompat_belum") % chipset
	if _kompatibel():
		return Bahasa.t("dm.kompat_ok") % [chipset, String(Repositori.item(p.driver_aktif())["nama"])]
	return Bahasa.t("dm.kompat_tidak") % chipset

# Tombol tindakan. Setiap tombol hanya aktif bila syaratnya terpenuhi.
func _tombol_tindakan() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var p := _sesi.perangkat
	grid.add_child(_tombol("perangkat.rakit", not p.sudah_dirakit() and not p.adapter_dimiliki().is_empty(), _rakit))
	grid.add_child(_tombol("perangkat.hubungkan", p.sudah_dirakit() and not p.terhubung(), _hubungkan))
	grid.add_child(_tombol("perangkat.putuskan", p.terhubung(), _putuskan))
	grid.add_child(_tombol("perangkat.upgrade", p.sudah_dirakit() and p.antena() < 2 and p.punya("antena_penguat"), _upgrade))
	return grid

func _tombol(kunci: String, aktif: bool, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = Bahasa.t(kunci)
	b.disabled = not aktif
	b.custom_minimum_size = Vector2(0, 88)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(aksi)
	return b

func _rakit() -> void:
	var h := _sesi.perangkat.rakit()
	if bool(h["ok"]):
		_sesi.jaringan.buka("rakit:wifi_kit")
	_selesai(h)

func _hubungkan() -> void:
	_selesai(PerangkatCommands.hubungkan(_sesi))

func _putuskan() -> void:
	_selesai(_sesi.perangkat.putuskan())

func _upgrade() -> void:
	var h := _sesi.perangkat.upgrade_antena()
	if bool(h["ok"]):
		_sesi.jaringan.buka("upgrade:antena")
	_selesai(h)

func _selesai(h: Dictionary) -> void:
	if bool(h["ok"]):
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)
	_segarkan()
	_pesan.text = Bahasa.t(String(h["kunci"])) % Array(h.get("args", []))

func _bagian(kunci: String) -> Label:
	return _teks(kunci, Tema.AMBER, 24)

func _teks(isi: String, warna: Color, ukuran: int) -> Label:
	var l := Tema.label(isi, warna, ukuran)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
