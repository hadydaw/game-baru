class_name AlatScreen
extends Control

# Alat Lapangan: perangkat lunak permainan yang sebelumnya dipanggil lewat perintah Terminal
# (scan, inspeksi, trace, decode, analyze). Tombol memanggil handler yang sama dengan sesi aktif,
# sehingga efek, flag misi, dan galatnya sama dengan sebelumnya.

var _sesi: ShellSession
var _input: LineEdit
var _keluaran: Label
var _gulir: ScrollContainer

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
	var judul := Label.new()
	judul.text = Bahasa.t("alat.judul")
	judul.add_theme_color_override("font_color", Tema.TEAL)
	judul.add_theme_font_size_override("font_size", 34)
	kolom.add_child(judul)
	_input = LineEdit.new()
	_input.placeholder_text = Bahasa.t("alat.input")
	_input.custom_minimum_size = Vector2(0, 80)
	_input.add_theme_font_size_override("font_size", 24)
	kolom.add_child(_input)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	kolom.add_child(grid)
	for pasangan in [["alat.scan", "scan"], ["alat.inspeksi", "inspeksi"], ["alat.trace", "trace"], ["alat.decode", "decode"], ["alat.analyze", "analyze"]]:
		var b := Button.new()
		b.text = Bahasa.t(pasangan[0])
		b.custom_minimum_size = Vector2(0, 72)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_jalankan.bind(String(pasangan[1])))
		grid.add_child(b)
	_gulir = ScrollContainer.new()
	_gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(_gulir)
	_keluaran = Label.new()
	_keluaran.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_keluaran.add_theme_font_size_override("font_size", 22)
	_keluaran.add_theme_color_override("font_color", Tema.TEKS)
	_keluaran.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gulir.add_child(_keluaran)
	Bahasa.daftar_penyegar(self, _segarkan)

func _segarkan() -> void:
	_input.placeholder_text = Bahasa.t("alat.input")

# Menjalankan handler yang sama dengan Terminal. Argumen berasal dari kolom input.
func _jalankan(nama: String) -> void:
	var teks := _input.text.strip_edges()
	var argumen: Array = [] if teks == "" else Array(teks.split(" ", false))
	var hasil: Array = AlatCommands.jalankan(_sesi, nama, argumen)
	var baris: PackedStringArray = []
	for b in hasil:
		baris.append(Bahasa.pilih(String(b["teks"])))
	_keluaran.text = "\n".join(baris)
	Misi.perbarui(_sesi)
	Penyimpanan.simpan_sesi(_sesi)
