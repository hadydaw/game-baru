class_name DesktopView
extends Control

# Desktop JTN: wallpaper penuh layar, bingkai utama di dalam area aman, grid ikon bebas, dan hotbar.

signal buka_aplikasi(id: String)
signal menu_diminta
signal menu_aplikasi_diminta

const APLIKASI := [
    {"id": "terminal", "nama": "Terminal", "ikon": "res://assets/ikon/aplikasi/app_terminal.png"},
    {"id": "peta", "nama": "Peta Jaringan", "ikon": "res://assets/ikon/aplikasi/app_peta.png"},
    {"id": "berkas", "nama": "Berkas", "ikon": "res://assets/ikon/aplikasi/app_berkas.png"},
    {"id": "tools", "nama": "Tools", "ikon": "res://assets/ikon/aplikasi/app_tools.png"},
    {"id": "forum", "nama": "Forum", "ikon": "res://assets/ikon/aplikasi/app_forum.png"},
    {"id": "pasar", "nama": "Black Market", "ikon": "res://assets/ikon/aplikasi/app_pasar.png"},
    {"id": "misi", "nama": "Misi", "ikon": "res://assets/ikon/aplikasi/app_misi.png"},
    {"id": "log", "nama": "Log", "ikon": "res://assets/ikon/aplikasi/app_log.png"},
]
# Grid ikon: kolom x baris. Harus sama dengan Pengaturan.KOLOM_DESKTOP dan BARIS_DESKTOP.
const KOLOM := 4
const BARIS := 3
const WALL_POTRET := "res://assets/wallpaper/wp_potret.png"
const WALL_LANSKAP := "res://assets/wallpaper/wp_lanskap.png"
const JARAK_BINGKAI := 14
# Tinggi panel atas dan taskbar. Jendela aplikasi mengisi ruang di antara keduanya.
const TINGGI_PANEL := PanelAtas.TINGGI
const TINGGI_TASKBAR := HotBar.TINGGI
# Pindah ikon: tekan-tahan TAHAN_DETIK memulai mode pindah; geser untuk memilih sel; lepas untuk menaruh.
const TAHAN_DETIK := 0.4

# Area aman perangkat: kiri, atas, kanan, bawah (diisi oleh MainController).
var aman := Vector4.ZERO

static func nama_aplikasi(id: String) -> String:
    for a in APLIKASI:
        if a["id"] == id:
            return a["nama"]
    return id

static func ikon_aplikasi(id: String) -> String:
    for a in APLIKASI:
        if a["id"] == id:
            return a["ikon"]
    return ""

var _wallpaper: TextureRect
var _margin: MarginContainer
var _area: Control
var _sel: Array = []
var _posisi: Dictionary = {}      # id -> Vector2i (kolom, baris)
var _cw := 0.0                    # lebar sel termasuk jarak
var _ch := 0.0                    # tinggi sel termasuk jarak
var _sel_px := Vector2.ZERO       # ukuran tombol ikon
var _panel: PanelAtas
var _hotbar: HotBar
var _jendela: ManajerJendela
var _wallpaper_terpasang: String = ""
var _tahan_timer: Timer
var _tahan_id := ""
var _tahan_terpicu := false
var _pindah_id := ""
var _hantu: TextureRect           # salinan ikon yang mengikuti jari
var _penanda: ColorRect           # sel tempat ikon akan diletakkan

# Posisi semua ikon: posisi tersimpan lebih dulu, lalu aplikasi baru ditaruh di sel kosong terdekat posisi awalnya.
static func posisi_tampil() -> Dictionary:
    var p := {}
    var terpakai := {}
    var simpan := Pengaturan.posisi_desktop()
    for id in simpan:
        var v: Array = simpan[id]
        var sel := Vector2i(int(v[0]), int(v[1]))
        p[id] = sel
        terpakai[sel] = true
    for i in range(APLIKASI.size()):
        var id: String = APLIKASI[i]["id"]
        if p.has(id):
            continue
        var awal := Vector2i(i % KOLOM, int(i / float(KOLOM)))
        var sel := _cari_kosong(terpakai, awal)
        p[id] = sel
        terpakai[sel] = true
    return p

# Sel kosong terdekat dari posisi "dari". Mengembalikan (-1, -1) jika grid penuh.
static func _cari_kosong(terpakai: Dictionary, dari: Vector2i) -> Vector2i:
    var terbaik := Vector2i(-1, -1)
    var jarak_terbaik := INF
    for r in range(BARIS):
        for c in range(KOLOM):
            var sel := Vector2i(c, r)
            if terpakai.has(sel):
                continue
            var jarak := Vector2(sel - dari).length_squared()
            if jarak < jarak_terbaik:
                jarak_terbaik = jarak
                terbaik = sel
    return terbaik

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
    _area = Control.new()
    _area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _area.mouse_filter = Control.MOUSE_FILTER_IGNORE
    kolom.add_child(_area)
    for a in APLIKASI:
        _area.add_child(_buat_sel_ikon(a))
    _posisi = posisi_tampil()
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

    _tahan_timer = Timer.new()
    _tahan_timer.one_shot = true
    _tahan_timer.wait_time = TAHAN_DETIK
    _tahan_timer.timeout.connect(_mulai_pindah)
    add_child(_tahan_timer)

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
    var label := Tema.label(a["nama"], Tema.TEKS, 22)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    kolom.add_child(label)
    var id: String = a["id"]
    tombol.set_meta("id", id)
    tombol.set_meta("ikon_tekstur", gambar.texture)
    tombol.gui_input.connect(_saat_input_sel.bind(tombol))
    tombol.pressed.connect(_ketuk_sel.bind(id))
    _sel.append({"tombol": tombol, "gambar": gambar, "label": label})
    return tombol

func _ketuk_sel(id: String) -> void:
    if _tahan_terpicu:
        return
    buka_aplikasi.emit(id)

func _saat_input_sel(e: InputEvent, tombol: Button) -> void:
    var id := String(tombol.get_meta("id"))
    if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
        if e.pressed:
            _tahan_id = id
            _tahan_terpicu = false
            _tahan_timer.start(TAHAN_DETIK)
        else:
            _tahan_timer.stop()
            if _pindah_id != "":
                _selesai_pindah(e.global_position)
    elif e is InputEventMouseMotion and _pindah_id != "":
        _sorot_tujuan(e.global_position)

# Dipanggil setelah tekan-tahan. Ikon asli meredup dan salinannya mengikuti jari.
func _mulai_pindah() -> void:
    if _tahan_id == "":
        return
    _tahan_terpicu = true
    _pindah_id = _tahan_id
    var t := _tombol_id(_pindah_id)
    t.modulate = Color(1, 1, 1, 0.25)
    _hantu = TextureRect.new()
    _hantu.texture = t.get_meta("ikon_tekstur") as Texture2D
    _hantu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _hantu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _hantu.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hantu.size = _sel_px * 0.7
    _hantu.custom_minimum_size = _hantu.size
    add_child(_hantu)
    _hantu.global_position = t.get_global_rect().get_center() - _hantu.size * 0.5
    _penanda = ColorRect.new()
    _penanda.color = Color(0.2, 0.9, 0.75, 0.28)
    _penanda.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _penanda.size = _sel_px
    _area.add_child(_penanda)
    _area.move_child(_penanda, 0)
    _penanda.position = t.position

func _tombol_id(id: String) -> Button:
    for s in _sel:
        if String(s["tombol"].get_meta("id")) == id:
            return s["tombol"]
    return null

# Sel grid di bawah pointer. Di luar grid, dipakai sel tepi terdekat.
func _sel_di_bawah(pos: Vector2) -> Vector2i:
    if _cw <= 0.0 or _ch <= 0.0:
        return Vector2i.ZERO
    var lokal := pos - _area.get_global_rect().position
    var c := clampi(int(floor(lokal.x / _cw)), 0, KOLOM - 1)
    var r := clampi(int(floor(lokal.y / _ch)), 0, BARIS - 1)
    return Vector2i(c, r)

# Sel akhir untuk ikon "id" jika dilepas di "sel": sel itu sendiri bila kosong, atau sel kosong terdekat.
func _tujuan(id: String, sel: Vector2i) -> Vector2i:
    var terpakai := {}
    for k in _posisi:
        if k != id:
            terpakai[_posisi[k]] = true
    return _cari_kosong(terpakai, sel)

func _sorot_tujuan(pos: Vector2) -> void:
    if is_instance_valid(_hantu):
        _hantu.global_position = pos - _hantu.size * 0.5
    if is_instance_valid(_penanda):
        var sel := _tujuan(_pindah_id, _sel_di_bawah(pos))
        _penanda.position = Vector2(sel.x * _cw, sel.y * _ch)

func _selesai_pindah(pos: Vector2) -> void:
    var id := _pindah_id
    _pindah_id = ""
    _tahan_id = ""
    if is_instance_valid(_hantu):
        _hantu.queue_free()
    _hantu = null
    if is_instance_valid(_penanda):
        _penanda.queue_free()
    _penanda = null
    for s in _sel:
        s["tombol"].modulate = Color(1, 1, 1)
    _pindahkan_ke(id, _sel_di_bawah(pos))

# Menaruh ikon di sel "sel" (atau sel kosong terdekat) lalu menyimpan posisinya.
func _pindahkan_ke(id: String, sel: Vector2i) -> bool:
    if not _posisi.has(id):
        return false
    _posisi[id] = _tujuan(id, sel)
    _tata_ulang()
    return _simpan_posisi()

# Menempatkan setiap ikon di selnya masing-masing.
func _tata_ulang() -> void:
    for s in _sel:
        var t: Button = s["tombol"]
        var id := String(t.get_meta("id"))
        if not _posisi.has(id):
            continue
        var sel: Vector2i = _posisi[id]
        t.position = Vector2(sel.x * _cw, sel.y * _ch)
        t.size = _sel_px

func _simpan_posisi() -> bool:
    var d := {}
    for id in _posisi:
        var sel: Vector2i = _posisi[id]
        d[id] = [sel.x, sel.y]
    return Pengaturan.set_posisi_desktop(d)

# Menyesuaikan wallpaper, ukuran sel, dan ukuran ikon dengan orientasi dan ukuran layar saat ini.
func _susun() -> void:
    var vp := get_viewport_rect().size
    var landscape := vp.x > vp.y
    var wall := WALL_LANSKAP if landscape else WALL_POTRET
    if wall != _wallpaper_terpasang:
        _wallpaper.texture = load(wall) as Texture2D
        _wallpaper_terpasang = wall

    var lebar_tersedia := vp.x - aman.x - aman.z - JARAK_BINGKAI * 2 - 28
    var sel := minf(lebar_tersedia / (KOLOM + 0.4), vp.y * 0.2)
    var jarak := sel * 0.12
    _sel_px = Vector2(sel, sel * 1.3)
    _cw = sel + jarak
    _ch = sel * 1.3 + jarak
    _area.custom_minimum_size = Vector2(KOLOM * _cw - jarak, BARIS * _ch - jarak)
    for s in _sel:
        s["tombol"].custom_minimum_size = _sel_px
        s["gambar"].custom_minimum_size = Vector2(sel * 0.62, sel * 0.62)
        s["label"].add_theme_font_size_override("font_size", int(clampf(sel * 0.13, 20.0, 30.0)))
    _tata_ulang()
