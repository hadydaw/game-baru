class_name DesktopView
extends Control

# Desktop JTN: wallpaper penuh layar, bingkai utama di dalam area aman, status bar, grid ikon, dan taskbar.

signal buka_aplikasi(id: String)
signal menu_diminta
signal menu_aplikasi_diminta

const APLIKASI := [
    {"id": "terminal", "nama": "app.terminal", "ikon": "res://assets/ikon/aplikasi/app_terminal.png"},
    {"id": "peta", "nama": "app.peta", "ikon": "res://assets/ikon/aplikasi/app_peta.png"},
    {"id": "berkas", "nama": "app.berkas", "ikon": "res://assets/ikon/aplikasi/app_berkas.png"},
    {"id": "tools", "nama": "app.tools", "ikon": "res://assets/ikon/aplikasi/app_tools.png"},
    {"id": "forum", "nama": "app.forum", "ikon": "res://assets/ikon/aplikasi/app_forum.png"},
    {"id": "pasar", "nama": "app.pasar", "ikon": "res://assets/ikon/aplikasi/app_pasar.png"},
    {"id": "misi", "nama": "app.misi", "ikon": "res://assets/ikon/aplikasi/app_misi.png"},
    {"id": "log", "nama": "app.log", "ikon": "res://assets/ikon/aplikasi/app_log.png"},
]
const KOLOM := 4
const WALL_POTRET := "res://assets/wallpaper/wp_potret.png"
const WALL_LANSKAP := "res://assets/wallpaper/wp_lanskap.png"
const JARAK_BINGKAI := 14
# Tinggi panel atas dan taskbar. Jendela aplikasi mengisi ruang di antara keduanya.
const TINGGI_PANEL := PanelAtas.TINGGI
const TINGGI_TASKBAR := HotBar.TINGGI

# Area aman perangkat: kiri, atas, kanan, bawah (diisi oleh MainController).
var aman := Vector4.ZERO

static func nama_aplikasi(id: String) -> String:
    for a in APLIKASI:
        if a["id"] == id:
            return Bahasa.t(a["nama"])
    return id

static func ikon_aplikasi(id: String) -> String:
    for a in APLIKASI:
        if a["id"] == id:
            return a["ikon"]
    return ""

var _wallpaper: TextureRect
var _margin: MarginContainer
var _grid: GridContainer
var _sel: Array = []
var _panel: PanelAtas
var _hotbar: HotBar
var _jendela: ManajerJendela
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
    _panel = PanelAtas.new()
    _panel.menu_aplikasi_diminta.connect(func(): menu_aplikasi_diminta.emit())
    kolom.add_child(_panel)
    kolom.add_child(_spasi())
    _grid = GridContainer.new()
    _grid.columns = KOLOM
    _grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    kolom.add_child(_grid)
    for a in APLIKASI:
        _grid.add_child(_buat_sel_ikon(a))
    kolom.add_child(_spasi())
    _hotbar = HotBar.new()
    _hotbar.home_diminta.connect(func(): menu_aplikasi_diminta.emit())
    _hotbar.aplikasi_diketuk.connect(_ketuk_aplikasi)
    kolom.add_child(_hotbar)
    _segarkan_hotbar()

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

# Menghubungkan hotbar ke manajer jendela. Dipanggil MainController setelah manajer dibuat.
func hubungkan_jendela(m: ManajerJendela) -> void:
    _jendela = m
    m.daftar_berubah.connect(_segarkan_hotbar)
    _segarkan_hotbar()

func _segarkan_hotbar() -> void:
    if is_instance_valid(_hotbar):
        _hotbar.segarkan(_jendela.daftar() if is_instance_valid(_jendela) else [])

# Ketuk aplikasi di hotbar: buka jika belum terbuka; memfokuskan jika terbuka tapi tidak aktif;
# meminimize jika sudah aktif (perilaku taskbar Xfce).
func _ketuk_aplikasi(id: String) -> void:
    if is_instance_valid(_jendela) and _jendela.ada(id):
        if _jendela.aktif() == id:
            _jendela.minimize(id)
        else:
            _jendela.fokus(id)
    else:
        buka_aplikasi.emit(id)

func _perbarui_jam() -> void:
    if is_instance_valid(_panel):
        _panel.segarkan()

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
    var label := Tema.label(Bahasa.t(a["nama"]), Tema.TEKS, 22)
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
