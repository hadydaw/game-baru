class_name PanelAtas
extends PanelContainer

# Panel atas Desktop JTN (Android portrait): tombol menu aplikasi, saldo kredit, status jaringan,
# notifikasi Pusat Misi, jam, dan tanggal. Indikator baterai dan suara belum ditampilkan karena
# belum ada sumber data perangkat.

signal menu_aplikasi_diminta

const TINGGI := 72
const UKURAN_LOGO := 56
const UKURAN_IKON := 36

const IKON_LOGO := "res://assets/logo/sys_logo_menu.png"
const IKON_KOIN := "res://assets/ikon/sistem/sys_koin.png"
const IKON_WIFI := "res://assets/ikon/sistem/sys_wifi_aktif.png"
const IKON_NOTIF_KOSONG := "res://assets/ikon/sistem/sys_notifikasi_kosong.png"
const IKON_NOTIF_PESAN := "res://assets/ikon/sistem/sys_notifikasi_pesan.png"

const HARI := ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
const BULAN := ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]

var _saldo: Label
var _notif: TextureRect
var _jam: Label
var _tanggal: Label

func _ready() -> void:
    custom_minimum_size = Vector2(0, TINGGI)
    add_theme_stylebox_override("panel", Tema.header_bawah(Tema.LATAR_HEADER, Tema.TEAL))
    var baris := HBoxContainer.new()
    baris.add_theme_constant_override("separation", 10)
    baris.alignment = BoxContainer.ALIGNMENT_BEGIN
    add_child(baris)

    var logo := TextureButton.new()
    logo.texture_normal = load(IKON_LOGO) as Texture2D
    logo.ignore_texture_size = true
    logo.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    logo.custom_minimum_size = Vector2(UKURAN_LOGO, UKURAN_LOGO)
    logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    logo.focus_mode = Control.FOCUS_NONE
    logo.pressed.connect(func(): menu_aplikasi_diminta.emit())
    baris.add_child(logo)

    baris.add_child(_ikon(IKON_KOIN, UKURAN_IKON))
    _saldo = Tema.label("", Tema.AMBER, 26)
    _saldo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    baris.add_child(_saldo)

    var sisa := Control.new()
    sisa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sisa.mouse_filter = Control.MOUSE_FILTER_IGNORE
    baris.add_child(sisa)

    var status := Tema.label("● Lokal", Tema.TEAL, 22)
    status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    baris.add_child(status)
    baris.add_child(_ikon(IKON_WIFI, 30))

    _notif = _ikon(IKON_NOTIF_KOSONG, UKURAN_IKON)
    baris.add_child(_notif)

    var jam_tanggal := VBoxContainer.new()
    jam_tanggal.alignment = BoxContainer.ALIGNMENT_CENTER
    jam_tanggal.add_theme_constant_override("separation", 0)
    baris.add_child(jam_tanggal)
    _jam = Tema.label("", Tema.TEKS, 24)
    _jam.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    jam_tanggal.add_child(_jam)
    _tanggal = Tema.label("", Tema.TEKS_REDUP, 17)
    _tanggal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    jam_tanggal.add_child(_tanggal)

    segarkan()

# Memperbarui saldo, notifikasi, jam, dan tanggal. Dipanggil saat dibuat dan berkala dari Desktop.
func segarkan() -> void:
    var s := SesiUtama.ambil()
    if s != null:
        _saldo.text = "Kr %d" % s.economy.saldo
        var pesan := ada_misi_aktif(s)
        _notif.texture = load(IKON_NOTIF_PESAN if pesan else IKON_NOTIF_KOSONG) as Texture2D
    var w := Time.get_datetime_dict_from_system()
    _jam.text = "%02d:%02d" % [w["hour"], w["minute"]]
    _tanggal.text = format_tanggal(w)

# Tanggal singkat dalam Bahasa Indonesia, misalnya "Kam, 5 Nov 2026".
static func format_tanggal(w: Dictionary) -> String:
    return "%s, %d %s %d" % [HARI[int(w["weekday"])], int(w["day"]), BULAN[int(w["month"]) - 1], int(w["year"])]

# Ada misi yang sudah diterima dan masih berjalan.
static func ada_misi_aktif(s: ShellSession) -> bool:
    for id in s.misi:
        if String(s.misi[id]) == "aktif":
            return true
    return false

func _ikon(path: String, px: int) -> TextureRect:
    var g := TextureRect.new()
    g.texture = load(path) as Texture2D
    g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    g.custom_minimum_size = Vector2(px, px)
    g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    g.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return g
