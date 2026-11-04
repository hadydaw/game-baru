class_name MainController
extends Control

# Pengatur alur layar: Splash → Desktop → Aplikasi.
# Hanya mengatur tampilan. Logika shell tetap di core/shell.

const LATAR := Color("0d1117")
const LOGO := "res://assets/logo/logo_jtn.png"
const BANNER_PASAR := "res://assets/banner/banner_pasar.png"

var _desktop: DesktopView

func _ready() -> void:
    # Ukuran root harus sudah pasti sebelum anak-anaknya dibuat. Jika tidak, anak
    # memakai ukuran nol dan semua layar tampil kecil di pojok kiri atas.
    position = Vector2.ZERO
    size = get_viewport_rect().size
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _tampilkan_splash()

func _tampilkan_splash() -> void:
    var splash := Control.new()
    splash.set_anchors_preset(Control.PRESET_FULL_RECT)
    var latar := ColorRect.new()
    latar.color = LATAR
    latar.set_anchors_preset(Control.PRESET_FULL_RECT)
    splash.add_child(latar)
    var tengah := CenterContainer.new()
    tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
    splash.add_child(tengah)
    var logo := TextureRect.new()
    logo.texture = load(LOGO) as Texture2D
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var s := get_viewport_rect().size
    logo.custom_minimum_size = Vector2.ONE * minf(s.x, s.y) * 0.5
    tengah.add_child(logo)
    add_child(splash)
    await get_tree().create_timer(1.6).timeout
    if not is_instance_valid(splash):
        return
    var tween := create_tween()
    tween.tween_property(splash, "modulate:a", 0.0, 0.4)
    await tween.finished
    splash.queue_free()
    _tampilkan_desktop()

func _tampilkan_desktop() -> void:
    _desktop = DesktopView.new()
    _desktop.buka_aplikasi.connect(_buka_aplikasi)
    add_child(_desktop)

func _buka_aplikasi(id: String) -> void:
    _desktop.visible = false
    var frame := AppFrame.new()
    add_child(frame)
    frame.kembali.connect(func(): _tutup_aplikasi(frame))
    frame.setup(DesktopView.nama_aplikasi(id), _buat_konten(id))

func _tutup_aplikasi(frame: AppFrame) -> void:
    frame.queue_free()
    _desktop.visible = true

func _buat_konten(id: String) -> Control:
    match id:
        "terminal":
            return TerminalScreen.new()
        "pasar":
            return _konten_pasar()
        _:
            return _konten_segera_hadir(DesktopView.nama_aplikasi(id))

func _konten_pasar() -> Control:
    var kolom := VBoxContainer.new()
    kolom.set_anchors_preset(Control.PRESET_FULL_RECT)
    var banner := TextureRect.new()
    banner.texture = load(BANNER_PASAR) as Texture2D
    banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    banner.custom_minimum_size = Vector2(0, 220)
    kolom.add_child(banner)
    var teks := Label.new()
    teks.text = "Black Market akan tersedia pada tahap berikutnya."
    teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    kolom.add_child(teks)
    return kolom

func _konten_segera_hadir(nama: String) -> Control:
    # Label langsung dengan anchor penuh (bukan di dalam CenterContainer), supaya
    # lebarnya mengikuti layar dan tidak menyempit menjadi satu huruf per baris.
    var teks := Label.new()
    teks.set_anchors_preset(Control.PRESET_FULL_RECT)
    teks.text = "%s akan tersedia pada tahap berikutnya." % nama
    teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return teks
