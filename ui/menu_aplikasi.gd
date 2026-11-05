class_name MenuAplikasi
extends Control

# Menu Aplikasi Desktop JTN (Android portrait), gaya menu Start Xfce: empat kategori, kolom pencarian,
# dan tombol Keluar yang kembali ke Menu Utama. Dibuka dari tombol home di hotbar dan logo di panel atas.

signal buka_aplikasi(id: String)
signal keluar_diminta
signal tutup_diminta

const KATEGORI := [
    {"kunci": "sistem", "teks": "kategori.sistem", "apl": ["terminal", "berkas", "log"]},
    {"kunci": "jaringan", "teks": "kategori.jaringan", "apl": ["peta", "tools"]},
    {"kunci": "pasar", "teks": "kategori.pasar", "apl": ["pasar", "misi"]},
    {"kunci": "komunitas", "teks": "kategori.komunitas", "apl": ["forum"]},
]
const IKON_CARI := "res://assets/ikon/menu/menu_cari.png"
const IKON_KELUAR := "res://assets/ikon/menu/menu_keluar.png"
const KOLOM_APLIKASI := 3
const WARNA_TEAL := Color("#2dd4bf")

var _panel: PanelContainer
var _kolom: VBoxContainer
var _cari: LineEdit
var _tab: Dictionary = {}
var _grid: GridContainer
var _kategori := "sistem"

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var latar := ColorRect.new()
    latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    latar.color = Color(0, 0, 0, 0.55)
    latar.mouse_filter = Control.MOUSE_FILTER_STOP
    latar.gui_input.connect(_saat_latar)
    add_child(latar)

    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_HEADER, WARNA_TEAL, 2, 22))
    add_child(_panel)

    _kolom = VBoxContainer.new()
    _kolom.add_theme_constant_override("separation", 12)
    _panel.add_child(_kolom)

    _kolom.add_child(Tema.label(Bahasa.t("menu_app.judul"), WARNA_TEAL, 30))

    _cari = LineEdit.new()
    _cari.placeholder_text = Bahasa.t("menu_app.cari")
    _cari.clear_button_enabled = true
    _cari.custom_minimum_size = Vector2(0, 68)
    _cari.add_theme_font_size_override("font_size", 24)
    _cari.text_changed.connect(_saat_cari)
    _kolom.add_child(_cari)

    var baris_tab := HBoxContainer.new()
    baris_tab.add_theme_constant_override("separation", 8)
    _kolom.add_child(baris_tab)
    for k in KATEGORI:
        var b := Button.new()
        b.text = Bahasa.t(k["teks"])
        b.custom_minimum_size = Vector2(0, 64)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_font_size_override("font_size", 22)
        b.pressed.connect(_pilih_kategori.bind(k["kunci"]))
        baris_tab.add_child(b)
        _tab[k["kunci"]] = b

    var gulir := ScrollContainer.new()
    gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
    gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _kolom.add_child(gulir)
    _grid = GridContainer.new()
    _grid.columns = KOLOM_APLIKASI
    _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _grid.add_theme_constant_override("h_separation", 12)
    _grid.add_theme_constant_override("v_separation", 12)
    gulir.add_child(_grid)

    var keluar := Button.new()
    keluar.text = Bahasa.t("menu_app.keluar")
    keluar.custom_minimum_size = Vector2(0, 76)
    keluar.focus_mode = Control.FOCUS_NONE
    keluar.add_theme_font_size_override("font_size", 26)
    keluar.add_theme_stylebox_override("normal", Tema.kotak(Color(0.06, 0.1, 0.12), WARNA_TEAL, 2, 12))
    keluar.add_theme_stylebox_override("hover", Tema.kotak(Color(0.06, 0.2, 0.2), WARNA_TEAL, 2, 12))
    keluar.add_theme_stylebox_override("pressed", Tema.kotak(Color(0.06, 0.2, 0.2), WARNA_TEAL, 2, 12))
    if ResourceLoader.exists(IKON_KELUAR):
        var ikon := TextureRect.new()
        ikon.texture = load(IKON_KELUAR) as Texture2D
        ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ikon.custom_minimum_size = Vector2(48, 48)
        ikon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
        ikon.offset_left = 18.0
        ikon.offset_right = 66.0
        ikon.offset_top = -24.0
        ikon.offset_bottom = 24.0
        ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        keluar.add_child(ikon)
    keluar.pressed.connect(func(): keluar_diminta.emit())
    _kolom.add_child(keluar)

    _pilih_kategori("sistem")

# Mengatur jarak panel dari tepi atas dan bawah agar tidak menutupi panel atas dan hotbar.
func atur_area(atas: float, bawah: float) -> void:
    _panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel.offset_top = atas
    _panel.offset_bottom = -bawah
    _panel.offset_left = 14.0
    _panel.offset_right = -14.0

func _pilih_kategori(kunci: String) -> void:
    _kategori = kunci
    _cari.text = ""
    for k in _tab:
        (_tab[k] as Button).modulate = Color(0.45, 1.0, 0.85) if k == kunci else Color(1, 1, 1)
    isi_daftar()

func _saat_cari(_teks: String) -> void:
    isi_daftar()

# Aplikasi yang tampil: kategori aktif, atau hasil pencarian dari semua kategori.
func daftar_terlihat() -> Array:
    var kata := _cari.text.strip_edges().to_lower()
    var hasil: Array = []
    if kata != "":
        for k in KATEGORI:
            for id in k["apl"]:
                if DesktopView.nama_aplikasi(id).to_lower().contains(kata) and not hasil.has(id):
                    hasil.append(id)
    else:
        for k in KATEGORI:
            if k["kunci"] == _kategori:
                hasil = k["apl"].duplicate()
    return hasil

func isi_daftar() -> void:
    if not is_instance_valid(_grid):
        return
    for anak in _grid.get_children():
        _grid.remove_child(anak)
        anak.queue_free()
    var terlihat := daftar_terlihat()
    for id in terlihat:
        _grid.add_child(_buat_ubin(id))
    if terlihat.is_empty():
        _grid.add_child(Tema.label(Bahasa.t("menu_app.kosong"), Tema.TEKS_REDUP, 22))

func _buat_ubin(id: String) -> Button:
    var tombol := Button.new()
    tombol.flat = true
    tombol.focus_mode = Control.FOCUS_NONE
    tombol.custom_minimum_size = Vector2(200, 200)
    tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var kolom := VBoxContainer.new()
    kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    kolom.alignment = BoxContainer.ALIGNMENT_CENTER
    kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tombol.add_child(kolom)
    var gambar := TextureRect.new()
    var path := DesktopView.ikon_aplikasi(id)
    if ResourceLoader.exists(path):
        gambar.texture = load(path) as Texture2D
    gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    gambar.custom_minimum_size = Vector2(110, 110)
    gambar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    kolom.add_child(gambar)
    var label := Tema.label(DesktopView.nama_aplikasi(id), Tema.TEKS, 22)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    kolom.add_child(label)
    tombol.pressed.connect(func(): buka_aplikasi.emit(id))
    return tombol

func _saat_latar(e: InputEvent) -> void:
    if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        tutup_diminta.emit()
