class_name DesktopView
extends Control

# Desktop JTN: wallpaper sesuai orientasi, status bar, grid ikon aplikasi, dan taskbar.

signal buka_aplikasi(id: String)

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
const KOLOM := 4
const WALL_POTRET := "res://assets/wallpaper/wallpaper_potret.png"
const WALL_LANSKAP := "res://assets/wallpaper/wallpaper_lanskap.png"

# Nilai awal. Saldo dan koneksi akan diganti saat sistem ekonomi dan jaringan dibuat.
const SALDO_AWAL := 500

static func nama_aplikasi(id: String) -> String:
    for a in APLIKASI:
        if a["id"] == id:
            return a["nama"]
    return id

var _wallpaper: TextureRect
var _grid: GridContainer
var _sel: Array = []
var _label_jam: Label
var _orientasi_landscape: bool = false
var _wallpaper_terpasang: String = ""

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _wallpaper = TextureRect.new()
    _wallpaper.set_anchors_preset(Control.PRESET_FULL_RECT)
    _wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_wallpaper)
    var redup := ColorRect.new()
    redup.color = Color(0, 0, 0, 0.25)
    redup.set_anchors_preset(Control.PRESET_FULL_RECT)
    redup.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(redup)

    var kolom := VBoxContainer.new()
    kolom.set_anchors_preset(Control.PRESET_FULL_RECT)
    kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(kolom)
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

func _spasi() -> Control:
    var s := Control.new()
    s.size_flags_vertical = Control.SIZE_EXPAND_FILL
    s.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return s

func _label(teks: String) -> Label:
    var l := Label.new()
    l.text = teks
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _buat_status_bar() -> Control:
    var panel := PanelContainer.new()
    var gaya := StyleBoxFlat.new()
    gaya.bg_color = Color(0.05, 0.07, 0.09, 0.85)
    panel.add_theme_stylebox_override("panel", gaya)
    var baris := HBoxContainer.new()
    panel.add_child(baris)
    baris.add_child(_label("Kr %d" % SALDO_AWAL))
    var sisa := Control.new()
    sisa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sisa.mouse_filter = Control.MOUSE_FILTER_IGNORE
    baris.add_child(sisa)
    baris.add_child(_label("● Lokal"))
    return panel

func _buat_taskbar() -> Control:
    var panel := PanelContainer.new()
    var gaya := StyleBoxFlat.new()
    gaya.bg_color = Color(0.05, 0.07, 0.09, 0.85)
    panel.add_theme_stylebox_override("panel", gaya)
    var baris := HBoxContainer.new()
    panel.add_child(baris)
    baris.add_child(_label("operator@jtn"))
    var sisa := Control.new()
    sisa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sisa.mouse_filter = Control.MOUSE_FILTER_IGNORE
    baris.add_child(sisa)
    _label_jam = _label("")
    baris.add_child(_label_jam)
    return panel

func _perbarui_jam() -> void:
    var w := Time.get_time_dict_from_system()
    _label_jam.text = "%02d:%02d" % [w["hour"], w["minute"]]

func _buat_sel_ikon(a: Dictionary) -> Button:
    var tombol := Button.new()
    tombol.flat = true
    tombol.focus_mode = Control.FOCUS_NONE
    var kolom := VBoxContainer.new()
    kolom.set_anchors_preset(Control.PRESET_FULL_RECT)
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
    var label := _label(a["nama"])
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    kolom.add_child(label)
    var id: String = a["id"]
    tombol.pressed.connect(func(): buka_aplikasi.emit(id))
    _sel.append({"tombol": tombol, "gambar": gambar, "label": label})
    return tombol

# Menyesuaikan wallpaper dan ukuran ikon dengan orientasi layar saat ini.
func _susun() -> void:
    var ukuran := get_viewport_rect().size
    var landscape := ukuran.x > ukuran.y
    var wall := WALL_LANSKAP if landscape else WALL_POTRET
    if wall != _wallpaper_terpasang:
        _wallpaper.texture = load(wall) as Texture2D
        _wallpaper_terpasang = wall
    _orientasi_landscape = landscape

    var sel := minf(ukuran.x / (KOLOM + 1.0), 220.0)
    var jarak := int(sel * 0.12)
    _grid.add_theme_constant_override("h_separation", jarak)
    _grid.add_theme_constant_override("v_separation", jarak)
    for s in _sel:
        s["tombol"].custom_minimum_size = Vector2(sel, sel * 1.25)
        s["gambar"].custom_minimum_size = Vector2(sel * 0.6, sel * 0.6)
        s["label"].add_theme_font_size_override("font_size", int(clampf(sel * 0.14, 22.0, 36.0)))
