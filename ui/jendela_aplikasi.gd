class_name JendelaAplikasi
extends PanelContainer

# Jendela aplikasi untuk Android portrait: title bar dengan ikon, judul, dan tombol minimize,
# maximize, close. Tidak ada drag atau resize. Posisi dan ukuran diatur ManajerJendela.

signal fokus_diminta(id: String)
signal minimize_diminta(id: String)
signal maximize_diminta(id: String)
signal tutup_diminta(id: String)

const TINGGI_HEADER := 88
const UKURAN_TOMBOL := 88
const JARAK_KONTEN := 10

const JENDELA_DIR := "res://assets/ikon/jendela/"

var id := ""
var judul := ""
var maksimal := false
var diminimize := false

var _area: Control
var isi: Control  # konten aplikasi di dalam jendela

# Dipanggil sebelum node masuk pohon. Membangun seluruh isi jendela.
func setup(p_id: String, p_judul: String, p_ikon: String, konten: Control) -> void:
    id = p_id
    isi = konten
    judul = p_judul
    add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 0))
    mouse_filter = Control.MOUSE_FILTER_STOP

    var kolom := VBoxContainer.new()
    kolom.add_theme_constant_override("separation", 0)
    add_child(kolom)

    var header := PanelContainer.new()
    header.add_theme_stylebox_override("panel", Tema.header_bawah(Tema.LATAR_HEADER, Tema.TEAL))
    header.custom_minimum_size = Vector2(0, TINGGI_HEADER)
    kolom.add_child(header)
    var baris := HBoxContainer.new()
    baris.add_theme_constant_override("separation", 10)
    header.add_child(baris)

    var ikon := TextureRect.new()
    ikon.texture = load(p_ikon) as Texture2D
    ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    ikon.custom_minimum_size = Vector2(56, 56)
    ikon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    baris.add_child(ikon)

    var label := Tema.label(p_judul, Tema.TEKS, 26)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    baris.add_child(label)

    baris.add_child(_tombol("minimize", func(): minimize_diminta.emit(id)))
    baris.add_child(_tombol("maximize", func(): maximize_diminta.emit(id)))
    baris.add_child(_tombol("close", func(): tutup_diminta.emit(id)))

    var margin := MarginContainer.new()
    margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    Tema.margin_seragam(margin, JARAK_KONTEN)
    kolom.add_child(margin)
    _area = Control.new()
    _area.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _area.clip_contents = true
    margin.add_child(_area)
    konten.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _area.add_child(konten)

    gui_input.connect(_saat_input)

# Klik pada area jendela (di luar tombol) memfokuskan jendela ini.
func _saat_input(e: InputEvent) -> void:
    if e is InputEventMouseButton and e.pressed:
        fokus_diminta.emit(id)

# Tombol gambar dari aset jendela. Keadaan tekan memakai file *_tekan.png.
func _tombol(nama: String, aksi: Callable) -> TextureButton:
    var t := TextureButton.new()
    t.texture_normal = load(JENDELA_DIR + "win_%s_normal.png" % nama) as Texture2D
    t.texture_pressed = load(JENDELA_DIR + "win_%s_tekan.png" % nama) as Texture2D
    t.ignore_texture_size = true
    t.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    t.custom_minimum_size = Vector2(UKURAN_TOMBOL, UKURAN_TOMBOL)
    t.focus_mode = Control.FOCUS_NONE
    t.pressed.connect(aksi)
    return t
