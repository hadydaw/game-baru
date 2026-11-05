class_name DesktopView
extends Control

# Desktop JTN: wallpaper penuh layar, bingkai utama di dalam area aman, status bar, grid ikon, dan taskbar.

signal buka_aplikasi(id: String)
signal menu_diminta

const APLIKASI := [
    {"id": "terminal", "nama": "Terminal", "ikon": "res://assets/ikon/icon_terminal.png"},
    {"id": "peta", "nama": "Peta Jaringan", "ikon": "res://assets/ikon/icon_peta.png"},
    {"id": "berkas", "nama": "Berkas", "ikon": "res://assets/ikon/icon_berkas.png"},
    {"id": "tools", "nama": "Tools", "ikon": "res://assets/ikon/icon_tools.png"},
    {"id": "forum", "nama": "Forum", "ikon": "res://assets/ikon/icon_forum.png"},
    {"id": "pasar", "nama": "Black Market", "ikon": "res://assets/ikon/icon_pasar.png"},
    {"id": "misi", "nama": "Misi", "ikon": "res://assets/ikon/icon_misi.png"},
    {"id": "log", "nama": "Log", "ikon": "res://assets/ikon/icon_log.png"},
]
const IKON_KOIN := "res://assets/ikon/ikon_koin.png"
const IKON_WIFI := "res://assets/ikon/ikon_wifi.png"
const IKON_USER := "res://assets/ikon/ikon_user.png"
const KOLOM := 4
const WALL_POTRET := "res://assets/wallpaper/wallpaper_potret.png"
const WALL_LANSKAP := "res://assets/wallpaper/wallpaper_lanskap.png"
const JARAK_BINGKAI := 14

# Nilai awal. Saldo dan koneksi akan diganti saat sistem ekonomi dan jaringan dibuat.
const SALDO_AWAL := 500

# Area aman perangkat: kiri, atas, kanan, bawah (diisi oleh MainController).
var aman := Vector4.ZERO

static func nama_aplikasi(id: String) -> String:
    for a in APLIKASI:
        if a["id"] == id:
            return a["nama"]
    return id

var _wallpaper: TextureRect
var _margin: MarginContainer
var _grid: GridContainer
var _sel: Array = []
var _label_jam: Label
var _wallpaper_terpasang: String = ""

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _wallpaper = TextureRect.new()
    _wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_wallpaper)

    _margin = MarginContainer.new()
    _margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_margin)
    atur_aman(aman)

    var bingkai := PanelContainer.new()
    bingkai.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 24))
    _margin.add_child(bingkai)

    var kolom := VBoxContainer.new()
    kolom.add_theme_constant_override("separation", 12)
    bingkai.add_child(kolom)
    kolom.add_child(_buat_status_bar())
    kolom.add_child(_spasi())
    _grid = GridContainer.new()
    _grid.columns = KOLOM
    _grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    kolom.add_child(_grid)
    for a in APLIKASI:
        _grid.add_child(_buat_sel_ikon(a))
    kolom.add_child(_spasi())
    kolom.add_child(_buat_taskbar())

    var jam := Timer.new()
    jam.wait_time = 30.0
    jam.timeout.connect(_perbarui_jam)
    add_child(jam)
    jam.start()
    _perbarui_jam()

    get_viewport().size_changed.connect(_susun)
    _susun()

# Dipanggil MainController saat layar berubah atau area aman berubah.
func atur_aman(nilai: Vector4) -> void:
    aman = nilai
    if not is_instance_valid(_margin):
        return
    _margin.add_theme_constant_override("margin_left", int(aman.x) + JARAK_BINGKAI)
    _margin.add_theme_constant_override("margin_top", int(aman.y) + JARAK_BINGKAI)
    _margin.add_theme_constant_override("margin_right", int(aman.z) + JARAK_BINGKAI)
    _margin.add_theme_constant_override("margin_bottom", int(aman.w) + JARAK_BINGKAI)

func _spasi() -> Control:
    var s := Control.new()
    s.size_flags_vertical = Control.SIZE_EXPAND_FILL
    s.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return s

func _ikon_kecil(path: String, px: int) -> TextureRect:
    var g := TextureRect.new()
    g.texture = load(path) as Texture2D
    g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    g.custom_minimum_size = Vector2(px, px)
    g.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return g

func _buat_status_bar() -> Control:
    var baris := HBoxContainer.new()
    baris.add_theme_constant_override("separation", 10)
    baris.add_child(_ikon_kecil(IKON_KOIN, 36))
    baris.add_child(Tema.label("Kr %d" % SALDO_AWAL, Tema.AMBER, 26))
    var sisa := _spasi_horizontal()
    baris.add_child(sisa)
    baris.add_child(Tema.label("● Lokal", Tema.TEAL, 22))
    baris.add_child(_ikon_kecil(IKON_WIFI, 30))
    return baris

func _buat_taskbar() -> Control:
    var baris := HBoxContainer.new()
    baris.add_theme_constant_override("separation", 10)
    baris.add_child(_ikon_kecil(IKON_USER, 30))
    var operator := Tema.label("operator@jtn", Tema.TEKS_REDUP, 22)
    operator.clip_text = true
    operator.custom_minimum_size = Vector2(0, 0)
    operator.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    baris.add_child(operator)
    baris.add_child(_spasi_horizontal())
    baris.add_child(_tombol_menu())
    _label_jam = Tema.label("", Tema.TEKS_REDUP, 22)
    baris.add_child(_label_jam)
    return baris

# Tombol Menu di taskbar: selalu terlihat dan cukup besar untuk disentuh jari.
func _tombol_menu() -> Button:
    var t := Button.new()
    t.text = "≡ Menu"
    t.focus_mode = Control.FOCUS_NONE
    t.custom_minimum_size = Vector2(136, 64)
    t.add_theme_font_size_override("font_size", 24)
    t.add_theme_color_override("font_color", Tema.TEKS)
    var normal := Tema.kotak(Color(0.06, 0.1, 0.12), Tema.TEAL, 2, 10)
    var aktif := Tema.kotak(Color(0.1, 0.18, 0.2), Tema.TEAL, 2, 10)
    t.add_theme_stylebox_override("normal", normal)
    t.add_theme_stylebox_override("hover", aktif)
    t.add_theme_stylebox_override("pressed", aktif)
    t.pressed.connect(func(): menu_diminta.emit())
    return t

func _spasi_horizontal() -> Control:
    var s := Control.new()
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return s

func _perbarui_jam() -> void:
    var w := Time.get_time_dict_from_system()
    _label_jam.text = "%02d:%02d" % [w["hour"], w["minute"]]

func _buat_sel_ikon(a: Dictionary) -> Button:
    var tombol := Button.new()
    tombol.flat = true
    tombol.focus_mode = Control.FOCUS_NONE
    var kolom := VBoxContainer.new()
    kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    kolom.alignment = BoxContainer.ALIGNMENT_CENTER
    kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tombol.add_child(kolom)
    var gambar := TextureRect.new()
    gambar.texture = load(a["ikon"]) as Texture2D
    gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    gambar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    kolom.add_child(gambar)
    var label := Tema.label(a["nama"], Tema.TEKS, 22)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    kolom.add_child(label)
    var id: String = a["id"]
    tombol.pressed.connect(func(): buka_aplikasi.emit(id))
    _sel.append({"tombol": tombol, "gambar": gambar, "label": label})
    return tombol

# Menyesuaikan wallpaper dan ukuran ikon dengan orientasi dan ukuran layar saat ini.
func _susun() -> void:
    var vp := get_viewport_rect().size
    var landscape := vp.x > vp.y
    var wall := WALL_LANSKAP if landscape else WALL_POTRET
    if wall != _wallpaper_terpasang:
        _wallpaper.texture = load(wall) as Texture2D
        _wallpaper_terpasang = wall

    var lebar_tersedia := vp.x - aman.x - aman.z - JARAK_BINGKAI * 2 - 28
    var sel := minf(lebar_tersedia / (KOLOM + 0.4), vp.y * 0.2)
    var jarak := int(sel * 0.12)
    _grid.add_theme_constant_override("h_separation", jarak)
    _grid.add_theme_constant_override("v_separation", jarak)
    for s in _sel:
        s["tombol"].custom_minimum_size = Vector2(sel, sel * 1.3)
        s["gambar"].custom_minimum_size = Vector2(sel * 0.62, sel * 0.62)
        s["label"].add_theme_font_size_override("font_size", int(clampf(sel * 0.13, 20.0, 30.0)))
