class_name MainController
extends Control

# Pengatur alur layar: Splash → Desktop → Aplikasi.
# Ukuran semua layar diset eksplisit ke ukuran viewport dan dihitung ulang saat layar berubah,
# supaya tidak bergantung pada urutan layout. Area aman (notch, status bar) dibaca dari perangkat.

const LATAR := Color("0d1117")
const LOGO := "res://assets/logo/logo_jtn.png"

var _desktop: DesktopView
var _frame: AppFrame
var _aman := Vector4.ZERO  # kiri, atas, kanan, bawah dalam satuan viewport

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    get_viewport().size_changed.connect(_sesuaikan_ukuran)
    _sesuaikan_ukuran()
    _tampilkan_splash()

func _sesuaikan_ukuran() -> void:
    var vp := get_viewport_rect().size
    position = Vector2.ZERO
    size = vp
    _aman = _hitung_area_aman(vp)
    for anak in get_children():
        if anak is Control:
            anak.position = Vector2.ZERO
            anak.size = vp
    if is_instance_valid(_desktop):
        _desktop.atur_aman(_aman)
    if is_instance_valid(_frame):
        _frame.atur_aman(_aman)

# Mengubah area aman dari piksel layar ke satuan viewport. Dengan stretch canvas_items
# dan aspect expand, skala seragam di kedua sumbu, jadi cukup satu nilai skala.
func _hitung_area_aman(vp: Vector2) -> Vector4:
    var layar := Vector2(DisplayServer.screen_get_size())
    if layar.x <= 0.0 or layar.y <= 0.0:
        return Vector4.ZERO
    var aman := Rect2(DisplayServer.get_display_safe_area())
    var skala := minf(vp.x / layar.x, vp.y / layar.y)
    return Vector4(
        aman.position.x * skala,
        aman.position.y * skala,
        (layar.x - aman.end.x) * skala,
        (layar.y - aman.end.y) * skala
    )

func _tampilkan_splash() -> void:
    var splash := Control.new()
    splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash.size = size
    var latar := ColorRect.new()
    latar.color = LATAR
    latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash.add_child(latar)
    var tengah := CenterContainer.new()
    tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash.add_child(tengah)
    var logo := TextureRect.new()
    logo.texture = load(LOGO) as Texture2D
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.custom_minimum_size = Vector2.ONE * minf(size.x, size.y) * 0.5
    tengah.add_child(logo)
    add_child(splash)
    await get_tree().create_timer(1.6).timeout
    if not is_instance_valid(splash):
        return
    var tween := create_tween()
    tween.tween_property(splash, "modulate:a", 0.0, 0.4)
    await tween.finished
    splash.queue_free()
    _tampilkan_menu()

# Menu utama adalah layar pertama setelah splash. Dari sini pemain masuk ke Desktop.
func _tampilkan_menu() -> void:
    var menu := MenuUtama.new()
    menu.size = size
    menu.atur_aman(_aman)
    menu.mulai.connect(_mulai_dari_menu.bind(menu))
    menu.keluar_diminta.connect(func(): get_tree().quit())
    add_child(menu)
    menu.position = Vector2.ZERO
    menu.size = size

func _mulai_dari_menu(_mode: String, menu: MenuUtama) -> void:
    menu.queue_free()
    _tampilkan_desktop()

func _tampilkan_desktop() -> void:
    _desktop = DesktopView.new()
    _desktop.aman = _aman
    _desktop.buka_aplikasi.connect(_buka_aplikasi)
    add_child(_desktop)
    _desktop.position = Vector2.ZERO
    _desktop.size = size

func _buka_aplikasi(id: String) -> void:
    _desktop.visible = false
    _frame = AppFrame.new()
    _frame.aman = _aman
    add_child(_frame)
    _frame.position = Vector2.ZERO
    _frame.size = size
    _frame.kembali.connect(_tutup_aplikasi)
    _frame.setup(DesktopView.nama_aplikasi(id), _buat_konten(id))

func _tutup_aplikasi() -> void:
    if is_instance_valid(_frame):
        _frame.queue_free()
    _frame = null
    _desktop.visible = true

func _buat_konten(id: String) -> Control:
    match id:
        "terminal":
            return TerminalScreen.new()
        "peta":
            return NetworkMap.new()
        "pasar":
            return PasarScreen.new()
        _:
            return _konten_segera_hadir(DesktopView.nama_aplikasi(id))

func _konten_segera_hadir(nama: String) -> Control:
    var teks := Tema.label("%s akan tersedia pada tahap berikutnya." % nama, Tema.TEKS, 24)
    teks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return teks
