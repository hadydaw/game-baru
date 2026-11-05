class_name PasarScreen
extends Control

# Layar Black Market. Memakai sesi pemain yang sama dengan Terminal, dan pembelian
# diproses lewat BlackMarket.beli(), sama seperti perintah bm di terminal.

const TINGGI_BANNER := 150.0
const WARNA_TERKUNCI := Color(0.55, 0.62, 0.6)

var _sesi: ShellSession
var _penjual_aktif := "a"
var _info: Label
var _daftar: VBoxContainer
var _tombol_penjual: Dictionary = {}
var _pesan: Label
var _tombol_komponen: Button
var _tampil_komponen := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesi = SesiUtama.ambil()
	var latar := ColorRect.new()
	latar.color = Color("0d1117")
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(margin, 16)
	add_child(margin)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	margin.add_child(kolom)

	var banner := TextureRect.new()
	banner.texture = load("res://assets/banner/banner_pasar.png") as Texture2D
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner.custom_minimum_size = Vector2(0, TINGGI_BANNER)
	kolom.add_child(banner)

	_info = Tema.label("", Tema.TEAL, 24)
	kolom.add_child(_info)

	var baris_penjual := HBoxContainer.new()
	baris_penjual.add_theme_constant_override("separation", 8)
	kolom.add_child(baris_penjual)
	for pid in BlackMarket.penjual_ids():
		var b := Button.new()
		var nama_pendek := func(): b.text = Bahasa.pilih(BlackMarket.nama_penjual(pid)).split("—")[-1].strip_edges()
		Bahasa.daftar_penyegar(b, nama_pendek)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(_pilih_penjual.bind(String(pid)))
		baris_penjual.add_child(b)
		_tombol_penjual[String(pid)] = b
	_tombol_komponen = Button.new()
	_tombol_komponen.text = Bahasa.t("pasar.komponen")
	_tombol_komponen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_komponen.custom_minimum_size = Vector2(0, 56)
	_tombol_komponen.pressed.connect(_pilih_komponen)
	baris_penjual.add_child(_tombol_komponen)

	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kolom.add_child(gulir)
	_daftar = VBoxContainer.new()
	_daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_theme_constant_override("separation", 10)
	gulir.add_child(_daftar)

	_pesan = Tema.label("", Tema.AMBER, 20)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_meta("bsegar", Callable(self, "_segarkan_pesan"))
	kolom.add_child(_pesan)
	_pilih_penjual(_penjual_aktif)

func _pilih_penjual(pid: String) -> void:
	_penjual_aktif = pid
	_tampil_komponen = false
	_pesan.text = ""
	_segarkan()

func _pilih_komponen() -> void:
	_tampil_komponen = true
	_pesan.text = ""
	_segarkan()

func _segarkan() -> void:
	_info.text = Bahasa.t("pasar.saldo") % [_sesi.economy.saldo, Reputation.nama_grup("kolektif_senja"), _sesi.reputation.get_nilai("kolektif_senja")]
	for pid in _tombol_penjual:
		_tombol_penjual[pid].modulate = Color(0.45, 1.0, 0.85) if (pid == _penjual_aktif and not _tampil_komponen) else Color(1, 1, 1)
	_tombol_komponen.modulate = Color(0.45, 1.0, 0.85) if _tampil_komponen else Color(1, 1, 1)
	for anak in _daftar.get_children():
		anak.queue_free()
	if _tampil_komponen:
		for id in Perangkat.semua_id():
			if not bool(Perangkat.info(String(id)).get("tidak_dijual", false)):
				_daftar.add_child(_kartu_komponen(String(id)))
		return
	var p := BlackMarket.penjual(_penjual_aktif)
	if not BlackMarket.penjual_terbuka(_penjual_aktif, _sesi.reputation):
		_daftar.add_child(Tema.label(Bahasa.t("pasar.terkunci") % int(p.get("syarat_rep", 0)), WARNA_TERKUNCI, 22))
		return
	for it in p.get("item", []):
		_daftar.add_child(_kartu_item(it))

func _kartu_item(it: Dictionary) -> Control:
	var id := String(it["id"])
	var tool := String(it["tool"])
	var tgt := int(it["tingkat"])
	var status := _sesi.market.status_item(id, _sesi.inventory)
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
	teks.add_child(Tema.label("%s  T%d" % [ToolDefs.nama(tool), tgt], Tema.TEKS, 24))
	teks.add_child(Tema.label(Bahasa.t("pasar.harga") % [ToolDefs.harga(tool, tgt), _sesi.market.sisa(id), String(it["kelangkaan"]).replace("_", " ")], Tema.TEKS_REDUP, 19))
	teks.add_child(Tema.label(_teks_status(status), Tema.AMBER if status == "upgrade" else Tema.TEKS_REDUP, 19))
	var beli := Button.new()
	beli.text = Bahasa.t("pasar.beli")
	beli.custom_minimum_size = Vector2(150, 64)
	beli.disabled = status == "dimiliki" or status == "habis"
	beli.pressed.connect(_beli.bind(id))
	baris.add_child(beli)
	return kartu

# Kartu komponen perangkat keras: harga, jumlah yang dimiliki, dan deskripsi.
func _kartu_komponen(id: String) -> Control:
	var it := Perangkat.info(id)
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
	teks.add_child(Tema.label(String(it["nama"]), Tema.TEKS, 24))
	teks.add_child(Tema.label(Bahasa.t("pasar.harga_komponen") % [int(it["harga"]), _sesi.perangkat.jumlah(id)], Tema.TEKS_REDUP, 19))
	teks.add_child(Tema.label(Bahasa.t(String(it["deskripsi_kunci"])), Tema.TEKS_REDUP, 17))
	var beli := Button.new()
	beli.text = Bahasa.t("pasar.beli")
	beli.custom_minimum_size = Vector2(150, 64)
	beli.pressed.connect(_beli_komponen.bind(id))
	baris.add_child(beli)
	return kartu

func _beli_komponen(id: String) -> void:
	var h := _sesi.perangkat.beli(id, _sesi.economy)
	if bool(h["ok"]):
		_sesi.jaringan.buka("beli:" + id)
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)
	_tampilkan_pesan(Bahasa.t(String(h["kunci"])) % Array(h.get("args", [])))
	_segarkan()

func _teks_status(status: String) -> String:
	match status:
		"dimiliki":
			return Bahasa.t("pasar.dimiliki")
		"upgrade":
			return Bahasa.t("pasar.tingkat")
		"habis":
			return Bahasa.t("pasar.habis")
	return Bahasa.t("pasar.tersedia")

func _beli(id: String) -> void:
	var hasil := _sesi.market.beli(id, _sesi)
	_tampilkan_pesan(String(hasil["pesan"]))
	if bool(hasil["ok"]):
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)
	_segarkan()

# Pesan pembelian disimpan sebagai pasangan dua-bahasa, lalu dipilih sesuai bahasa aktif.
var _pesan_asli := ""

func _segarkan_pesan() -> void:
	if _pesan != null:
		_pesan.text = Bahasa.pilih(_pesan_asli)

func _tampilkan_pesan(teks: String) -> void:
	_pesan_asli = teks
	_pesan.text = Bahasa.pilih(teks)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _sesi != null:
			Misi.perbarui(_sesi)
			Penyimpanan.simpan_sesi(_sesi)
