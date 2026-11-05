class_name TerminalScreen
extends Control

# Aplikasi Terminal: output monospace, prompt berwarna, baris tombol khusus Linux, dan riwayat.
# Logika perintah tetap di core/shell. Layar ini hanya menampilkan dan meneruskan masukan.

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const FS_PATH := "res://data/fs/pemain.json"
const UKURAN_FONT := 26
const UKURAN_TOMBOL := 22
const TINGGI_TOMBOL := 64
const WARNA_USER := "#3fb950"
const WARNA_JALUR := "#2dd4bf"
const WARNA_TEKS := "#e6f7f5"
const WARNA_ERROR := "#ff7b72"
const LATAR := Color("#0d1117")
const TOMBOL := ["/", "-", "_", "|", ".", "~", "Tab", "Ctrl", "Enter", "Backspace", "↑", "↓"]

var _sesi: ShellSession
var _keluaran: RichTextLabel
var _masukan: LineEdit
var _label_prompt: Label
var _margin: MarginContainer
var _font: Font
var _riwayat_idx: int = 0
var _tinggi_keyboard: float = -1.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _font = _muat_font()

    _margin = MarginContainer.new()
    _margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Tema.margin_seragam(_margin, 8)
    add_child(_margin)

    var kolom := VBoxContainer.new()
    kolom.add_theme_constant_override("separation", 8)
    _margin.add_child(kolom)

    _keluaran = RichTextLabel.new()
    _keluaran.bbcode_enabled = true
    _keluaran.scroll_following = true
    _keluaran.selection_enabled = true
    _keluaran.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _keluaran.add_theme_font_override("normal_font", _font)
    _keluaran.add_theme_font_size_override("normal_font_size", UKURAN_FONT)
    _keluaran.add_theme_color_override("default_color", Color(WARNA_TEKS))
    _keluaran.add_theme_stylebox_override("normal", _gaya_latar())
    kolom.add_child(_keluaran)

    var baris := HBoxContainer.new()
    baris.add_theme_constant_override("separation", 8)
    _label_prompt = Label.new()
    _label_prompt.add_theme_font_override("font", _font)
    _label_prompt.add_theme_font_size_override("font_size", UKURAN_FONT)
    _label_prompt.add_theme_color_override("font_color", Color(WARNA_USER))
    baris.add_child(_label_prompt)
    _masukan = LineEdit.new()
    _masukan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _masukan.custom_minimum_size = Vector2(0, TINGGI_TOMBOL)
    _masukan.caret_blink = true
    _masukan.clear_button_enabled = false
    _masukan.add_theme_font_override("font", _font)
    _masukan.add_theme_font_size_override("font_size", UKURAN_FONT)
    _masukan.add_theme_color_override("font_color", Color(WARNA_TEKS))
    _masukan.add_theme_stylebox_override("normal", Tema.kotak(Color(0.05, 0.08, 0.1), Tema.TEAL, 1, 10))
    _masukan.add_theme_stylebox_override("focus", Tema.kotak(Color(0.05, 0.08, 0.1), Tema.TEAL, 2, 10))
    _masukan.text_submitted.connect(_kirim)
    baris.add_child(_masukan)
    kolom.add_child(baris)

    kolom.add_child(_buat_baris_tombol())

    _sesi = _buat_sesi()
    _riwayat_idx = 0
    _perbarui_prompt()
    if _sesi == null:
        return
    _tampil([{"tipe": "info", "teks": "Terminal siap. Ketik \"help\" untuk daftar perintah."}])
    _tampil(_sesi.jalankan("pwd"))

# Membuat sesi shell. Bila gagal, galat ditampilkan di layar agar tidak diam-diam.
# Sesi disimpan di luar layar agar filesystem dan direktori kerja tetap ada saat pindah aplikasi.
static var _sesi_bersama: ShellSession

func _buat_sesi() -> ShellSession:
    if _sesi_bersama != null:
        return _sesi_bersama
    var sesi: ShellSession = null
    var muat := Penyimpanan.muat()
    match String(muat["status"]):
        "ok":
            sesi = ShellSession.dari_dict(muat["data"])
        "pulih_cadangan":
            sesi = ShellSession.dari_dict(muat["data"])
            _tampil([{"tipe": "error", "teks": "Penyimpanan utama rusak. Data dipulihkan dari cadangan. Berkas rusak disimpan di: %s" % muat["pesan"]}])
        "rusak":
            sesi = ShellSession.new(Vfs.new(_baca_fs()))
            _tampil([{"tipe": "error", "teks": "Penyimpanan rusak dan tidak ada cadangan. Mulai dari filesystem awal. Berkas rusak disimpan di: %s" % muat["pesan"]}])
        _:
            sesi = ShellSession.new(Vfs.new(_baca_fs()))
    if sesi == null:
        push_error("TerminalScreen: ShellSession gagal dibuat")
        _tampil([{"tipe": "error", "teks": "Sesi shell gagal dibuat. Lihat log Godot untuk detail."}])
        return null
    _sesi_bersama = sesi
    if not Penyimpanan.simpan_sesi(sesi):
        _tampil([{"tipe": "error", "teks": "Gagal menyimpan filesystem ke penyimpanan HP."}])
    return sesi

# Menyimpan keadaan sesi ke penyimpanan lokal. Dipanggil setelah setiap perintah dan saat aplikasi di-pause.
func _simpan() -> void:
    if _sesi_bersama == null:
        return
    if not Penyimpanan.simpan_sesi(_sesi_bersama):
        _tampil([{"tipe": "error", "teks": "Gagal menyimpan filesystem ke penyimpanan HP."}])

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        _simpan()

func _muat_font() -> Font:
    if ResourceLoader.exists(FONT_PATH):
        return load(FONT_PATH) as Font
    # Cadangan sementara sampai file JetBrains Mono diunggah ke assets/fonts/.
    var sistem := SystemFont.new()
    sistem.font_names = PackedStringArray(["monospace"])
    return sistem

func _gaya_latar() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = LATAR
    s.set_corner_radius_all(10)
    s.content_margin_left = 14.0
    s.content_margin_right = 14.0
    s.content_margin_top = 10.0
    s.content_margin_bottom = 10.0
    return s

func _buat_baris_tombol() -> Control:
    var grid := GridContainer.new()
    grid.columns = 6
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    for t in TOMBOL:
        var b := Button.new()
        b.text = t
        b.focus_mode = Control.FOCUS_NONE
        b.custom_minimum_size = Vector2(0, TINGGI_TOMBOL)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_override("font", _font)
        b.add_theme_font_size_override("font_size", UKURAN_TOMBOL if t != "Backspace" else 18)
        b.add_theme_color_override("font_color", Color(WARNA_TEKS))
        b.add_theme_stylebox_override("normal", _gaya_tombol(Color(0.06, 0.09, 0.12)))
        b.add_theme_stylebox_override("hover", _gaya_tombol(Color(0.08, 0.13, 0.15)))
        b.add_theme_stylebox_override("pressed", _gaya_tombol(Color(0.1, 0.22, 0.22)))
        b.pressed.connect(_tekan_tombol.bind(t))
        grid.add_child(b)
    return grid

func _gaya_tombol(bg: Color) -> StyleBoxFlat:
    var s := Tema.kotak(bg, Tema.TEAL, 1, 10)
    s.content_margin_left = 2.0
    s.content_margin_right = 2.0
    return s

func _process(_delta: float) -> void:
    # Saat keyboard HP muncul, area terminal dinaikkan agar output dan baris input tidak tertutup.
    var tinggi := float(DisplayServer.virtual_keyboard_get_height())
    if is_equal_approx(tinggi, _tinggi_keyboard):
        return
    _tinggi_keyboard = tinggi
    var vp := get_viewport_rect().size
    var layar := Vector2(DisplayServer.screen_get_size())
    var skala := 1.0
    if layar.x > 0.0 and layar.y > 0.0:
        skala = minf(vp.x / layar.x, vp.y / layar.y)
    _margin.add_theme_constant_override("margin_bottom", int(tinggi * skala) + 8)

func _baca_fs() -> Dictionary:
    if not FileAccess.file_exists(FS_PATH):
        _tampil([{"tipe": "error", "teks": "Berkas filesystem tidak ditemukan: %s" % FS_PATH}])
        return _fs_cadangan()
    var data = JSON.parse_string(FileAccess.get_file_as_string(FS_PATH))
    if typeof(data) != TYPE_DICTIONARY or not data.has("/"):
        _tampil([{"tipe": "error", "teks": "Format filesystem tidak valid."}])
        return _fs_cadangan()
    # File JSON membungkus root di bawah kunci "/". Vfs membutuhkan node root langsung.
    return data["/"]

func _fs_cadangan() -> Dictionary:
    return {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}

func _tekan_tombol(t: String) -> void:
    match t:
        "Tab":
            _lengkapi()
        "Ctrl":
            _batalkan()
        "Enter":
            _kirim(_masukan.text)
        "Backspace":
            _masukan.delete_char_at_caret()
        "↑":
            _riwayat(-1)
        "↓":
            _riwayat(1)
        _:
            _masukan.insert_text_at_caret(t)

func _kirim(teks: String) -> void:
    var t := teks.strip_edges()
    _masukan.clear()
    if _sesi == null:
        _tampil([{"tipe": "error", "teks": "Sesi shell belum siap, perintah tidak dijalankan."}])
        return
    if t.is_empty():
        _tampil_perintah("")
        return
    _tampil_perintah(t)
    _tampil(_sesi.jalankan(t))
    _riwayat_idx = _sesi.riwayat.size()
    _perbarui_prompt()
    _simpan()

func _batalkan() -> void:
    _tampil_perintah(_masukan.text + "^C")
    _masukan.clear()

func _riwayat(arah: int) -> void:
    if _sesi == null:
        return
    var r: Array = _sesi.riwayat
    if r.is_empty():
        return
    _riwayat_idx = clampi(_riwayat_idx + arah, 0, r.size())
    _masukan.text = String(r[_riwayat_idx]) if _riwayat_idx < r.size() else ""
    _masukan.caret_column = _masukan.text.length()

# Tab: melengkapi perintah atau nama berkas/direktori. Bila banyak kecocokan, daftarnya ditampilkan.
func _lengkapi() -> void:
    if _sesi == null:
        return
    var hasil := ShellComplete.lengkapi(_sesi, _masukan.text)
    _masukan.text = String(hasil["teks"])
    _masukan.caret_column = _masukan.text.length()
    var pilihan: Array = hasil["pilihan"]
    if pilihan.size() > 1:
        _tampil([{"tipe": "info", "teks": "  ".join(PackedStringArray(pilihan))}])

func _perbarui_prompt() -> void:
    if _sesi == null:
        _label_prompt.text = "$"
        return
    _label_prompt.text = _sesi.prompt()

# Baris perintah yang sudah dikirim, dengan prompt berwarna seperti terminal Linux.
func _tampil_perintah(teks: String) -> void:
    var p := _sesi.prompt() if _sesi != null else "operator@jtn:~$"
    var i := p.find(":")
    var user := p.substr(0, i)
    var jalur := p.substr(i + 1, p.length() - i - 2)
    var bb := "[color=%s]%s[/color]:[color=%s]%s[/color]$ %s" % [WARNA_USER, user, WARNA_JALUR, jalur, _aman(teks)]
    _keluaran.append_text(bb + "\n")

func _tampil(baris: Array) -> void:
    for b in baris:
        if String(b["tipe"]) == "clear":
            _keluaran.clear()
            continue
        var warna := WARNA_ERROR if String(b["tipe"]) == "error" else WARNA_TEKS
        _keluaran.append_text("[color=%s]%s[/color]\n" % [warna, _aman(String(b["teks"]))])

func _aman(s: String) -> String:
    return s.replace("[", "[lb]")
