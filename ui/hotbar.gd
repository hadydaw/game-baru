class_name HotBar
extends PanelContainer

# Hotbar bawah Desktop JTN (Android portrait), gaya taskbar Kali Xfce di layar sentuh.
# Kiri: tombol Home/Windows yang membuka Menu Aplikasi. Lalu aplikasi favorit dan jendela yang
# sedang terbuka. Jendela aktif diberi garis teal; jendela yang diminimize tampil redup.

signal home_diminta
signal aplikasi_diketuk(id: String)

const TINGGI := 96
const UKURAN_IKON := 68
const UKURAN_TOMBOL := 84
const IKON_HOME := "res://assets/logo/sys_logo_menu.png"
const IKON_APLIKASI := "res://assets/ikon/aplikasi/app_%s.png"

# Aplikasi yang selalu tampil di hotbar. Dapat diubah tanpa mengubah struktur.
const FAVORIT := ["terminal", "peta", "misi", "pasar"]

var _baris: HBoxContainer

func _ready() -> void:
    custom_minimum_size = Vector2(0, TINGGI)
    add_theme_stylebox_override("panel", Tema.header_bawah(Tema.LATAR_HEADER, Tema.TEAL))
    _baris = HBoxContainer.new()
    _baris.add_theme_constant_override("separation", 8)
    _baris.alignment = BoxContainer.ALIGNMENT_BEGIN
    add_child(_baris)
    _baris.add_child(_tombol_home())
    segarkan([])

# Membangun ulang isi hotbar dari daftar jendela (ManajerJendela.daftar()).
# Favorit selalu tampil, lalu jendela terbuka yang bukan favorit.
func segarkan(jendela: Array) -> void:
    for i in range(_baris.get_child_count() - 1, 0, -1):
        var anak := _baris.get_child(i)
        _baris.remove_child(anak)
        anak.queue_free()
    var status := {}
    for j in jendela:
        status[String(j["id"])] = j
    var tampil: Array = FAVORIT.duplicate()
    for j in jendela:
        if not tampil.has(String(j["id"])):
            tampil.append(String(j["id"]))
    for id in tampil:
        _baris.add_child(_tombol_aplikasi(String(id), status.get(String(id), {})))

func jumlah_aplikasi() -> int:
    return _baris.get_child_count() - 1

func _tombol_home() -> Button:
    var t := Button.new()
    t.name = "TombolHome"
    t.icon = load(IKON_HOME) as Texture2D
    t.expand_icon = true
    t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    t.focus_mode = Control.FOCUS_NONE
    t.custom_minimum_size = Vector2(UKURAN_TOMBOL + 12, UKURAN_TOMBOL + 12)
    t.add_theme_stylebox_override("normal", Tema.kotak(Color(0.06, 0.1, 0.12), Tema.TEAL, 2, 14))
    t.add_theme_stylebox_override("hover", Tema.kotak(Color(0.1, 0.18, 0.2), Tema.TEAL, 2, 14))
    t.add_theme_stylebox_override("pressed", Tema.kotak(Color(0.1, 0.18, 0.2), Tema.TEAL, 2, 14))
    t.pressed.connect(func(): home_diminta.emit())
    return t

# Satu tombol aplikasi. status kosong berarti aplikasi tidak sedang terbuka.
func _tombol_aplikasi(id: String, status: Dictionary) -> Control:
    var kolom := VBoxContainer.new()
    kolom.add_theme_constant_override("separation", 0)
    kolom.custom_minimum_size = Vector2(UKURAN_TOMBOL, TINGGI - 4)
    var t := Button.new()
    t.flat = true
    var path := IKON_APLIKASI % id
    if ResourceLoader.exists(path):
        t.icon = load(path) as Texture2D
    t.expand_icon = true
    t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    t.focus_mode = Control.FOCUS_NONE
    t.custom_minimum_size = Vector2(UKURAN_TOMBOL, UKURAN_TOMBOL)
    t.tooltip_text = DesktopView.nama_aplikasi(id)
    t.pressed.connect(func(): aplikasi_diketuk.emit(id))
    kolom.add_child(t)
    if id == "email" and Email.ada_belum_dibaca_utama():
        Tema.titik_notif(t)

    var terbuka := not status.is_empty()
    var aktif := terbuka and bool(status.get("aktif", false))
    if terbuka and bool(status.get("diminimize", false)):
        t.modulate = Color(1, 1, 1, 0.45)
    var garis := ColorRect.new()
    garis.custom_minimum_size = Vector2(UKURAN_TOMBOL - 20, 4)
    garis.color = Tema.TEAL if aktif else (Tema.TEKS_REDUP if terbuka else Color(0, 0, 0, 0))
    garis.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    garis.mouse_filter = Control.MOUSE_FILTER_IGNORE
    kolom.add_child(garis)
    return kolom
