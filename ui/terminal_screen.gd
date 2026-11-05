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
# Ctrl sebagai modifier: aktif sampai dipakai satu kali atau dibatalkan dengan menekannya lagi.
var _ctrl: bool = false
var _tombol_ctrl: Button
var _teks_terakhir: String = ""

# Animasi pemrosesan perintah. Hasil sudah dihitung; yang dianimasikan hanya tampilannya.
var _timer: Timer
var _status: Label
var _busy: bool = false
var _antrean: Array = []
var _langkah: Array = []
var _ketik_teks: String = ""
var _ketik_tipe: String = "info"
var _ketik_pos: int = 0
var _ketik_aktif: bool = false
var _ketik_jeda: int = 0
var _status_teks: String = ""
var _status_gaya: String = "spinner"
var _status_bar: int = 0
var _status_mulai: int = 0

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
    _masukan.text_changed.connect(_teks_berubah)
    baris.add_child(_masukan)
    _status = Label.new()
    _status.add_theme_font_override("font", _font)
    _status.add_theme_font_size_override("font_size", UKURAN_FONT - 4)
    _status.add_theme_color_override("font_color", Color(WARNA_JALUR))
    _status.visible = false
    kolom.add_child(_status)
    kolom.add_child(baris)

    _timer = Timer.new()
    _timer.one_shot = true
    _timer.timeout.connect(_lanjut)
    add_child(_timer)

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
    # Sesi dipakai bersama dengan Peta Jaringan. Pesan pemulihan hanya ditampilkan saat sesi pertama dibuat.
    var baru := SesiUtama.sesi == null
    var sesi := SesiUtama.ambil()
    if sesi == null:
        push_error("TerminalScreen: ShellSession gagal dibuat")
        _tampil([{"tipe": "error", "teks": "Sesi shell gagal dibuat. Lihat log Godot untuk detail."}])
        return null
    if baru and SesiUtama.pesan_status() != "":
        _tampil([{"tipe": "error", "teks": SesiUtama.pesan_status()}])
    _sesi_bersama = sesi
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
        if t == "Ctrl":
            _tombol_ctrl = b
        b.pressed.connect(_tekan_tombol.bind(t))
        grid.add_child(b)
    return grid

func _gaya_tombol(bg: Color) -> StyleBoxFlat:
    var s := Tema.kotak(bg, Tema.TEAL, 1, 10)
    s.content_margin_left = 2.0
    s.content_margin_right = 2.0
    return s

func _process(_delta: float) -> void:
    _perbarui_status()
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
    if t == "Ctrl":
        _ctrl = not _ctrl
        _perbarui_ctrl()
        return
    if t not in ["Tab", "Enter", "Backspace", "↑", "↓"]:
        # Karakter biasa. Bila Ctrl aktif, _teks_berubah yang memprosesnya.
        _ubah_masukan(func(): _masukan.insert_text_at_caret(t))
        return
    # Tombol fungsi membatalkan Ctrl yang sedang aktif.
    _ctrl = false
    _perbarui_ctrl()
    match t:
        "Tab":
            _lengkapi()
        "Enter":
            _kirim(_masukan.text)
        "Backspace":
            _ubah_masukan(func(): _masukan.delete_char_at_caret())
        "↑":
            _riwayat(-1)
        "↓":
            _riwayat(1)

# Setiap perubahan masukan (tombol layar maupun keyboard HP) lewat sini.
# Bila Ctrl aktif dan satu karakter disisipkan, karakter itu dipakai sebagai kombinasi Ctrl.
func _teks_berubah(baru: String) -> void:
    var lama := _teks_terakhir
    if not _ctrl or baru.length() != lama.length() + 1:
        _teks_terakhir = baru
        return
    var h := ShellControl.sisipan(lama, baru)
    _ctrl = false
    _perbarui_ctrl()
    _set_teks(String(h["teks"]))
    _jalankan_aksi(ShellControl.aksi(String(h["huruf"])))

# Mengubah masukan dari kode. Teks dicatat agar perubahan berikutnya dibandingkan dengan benar,
# karena mengubah text secara program tidak selalu memicu text_changed.
func _set_teks(baru: String) -> void:
    _masukan.text = baru
    _masukan.caret_column = baru.length()
    _teks_terakhir = baru

# Menjalankan perubahan (sisip atau hapus) lalu memastikan Ctrl diproses, dengan atau tanpa sinyal.
func _ubah_masukan(ubah: Callable) -> void:
    _teks_terakhir = _masukan.text
    ubah.call()
    if _masukan.text != _teks_terakhir:
        _teks_berubah(_masukan.text)

func _jalankan_aksi(a: String) -> void:
    if _busy and a == "batal":
        # Ctrl+C saat animasi berjalan: tampilkan sisa output sekarang juga.
        _selesaikan_cepat()
        return
    match a:
        "batal":
            _tampil_perintah(_masukan.text + "^C")
            _set_teks("")
        "bersihkan":
            _keluaran.clear()
        "hapus_baris":
            _set_teks("")

func _perbarui_ctrl() -> void:
    if _tombol_ctrl != null:
        _tombol_ctrl.modulate = Color(0.45, 1.0, 0.85) if _ctrl else Color(1, 1, 1)

func _kirim(teks: String) -> void:
    var t := teks.strip_edges()
    _set_teks("")
    if _sesi == null:
        _tampil([{"tipe": "error", "teks": "Sesi shell belum siap, perintah tidak dijalankan."}])
        return
    if _busy:
        # Perintah yang dikirim saat animasi berjalan menunggu giliran, agar output tidak bercampur.
        if not t.is_empty():
            _antrean.append(t)
        return
    if t.is_empty():
        _tampil_perintah("")
        return
    _mulai(t)

func _mulai(t: String) -> void:
    _tampil_perintah(t)
    var hasil := _sesi.jalankan(t)
    _riwayat_idx = _sesi.riwayat.size()
    _simpan()
    _langkah = Animasi.rencana(t, hasil)
    _busy = true
    _timer.start(0.02)

# Dipanggil Timer: menjalankan satu langkah animasi (status, pengetikan baris, atau jeda).
func _lanjut() -> void:
    if _ketik_aktif:
        var sisa := _ketik_teks.length() - _ketik_pos
        var n := clampi(ceili(sisa / 10.0), 2, 8)
        _keluaran.append_text(_warna_baris(_ketik_tipe, _ketik_teks.substr(_ketik_pos, n)))
        _ketik_pos += n
        if _ketik_pos >= _ketik_teks.length():
            _keluaran.append_text("\n")
            _ketik_aktif = false
            _timer.start(maxf(_ketik_jeda, 10) / 1000.0)
        else:
            _timer.start(0.02)
        return
    if _langkah.is_empty():
        _akhiri()
        return
    var s: Dictionary = _langkah.pop_front()
    match String(s["tipe"]):
        "status":
            _tampil_status(s)
            _timer.start(maxf(int(s["durasi"]), 10) / 1000.0)
        "baris":
            _ketik_teks = String(s["teks"])
            _ketik_tipe = String(s["tipe_baris"])
            _ketik_pos = 0
            _ketik_aktif = true
            _ketik_jeda = int(s["jeda"])
            _timer.start(0.01)
        "clear":
            _keluaran.clear()
            _timer.start(0.01)

func _akhiri() -> void:
    _busy = false
    _status.visible = false
    _perbarui_prompt()
    if not _antrean.is_empty():
        _mulai(String(_antrean.pop_front()))

# Menyelesaikan semua animasi sekarang juga (dipakai Ctrl+C dan oleh tes).
func _selesaikan_cepat() -> void:
    while _busy:
        if _ketik_aktif:
            _keluaran.append_text(_warna_baris(_ketik_tipe, _ketik_teks.substr(_ketik_pos)) + "\n")
            _ketik_aktif = false
        elif not _langkah.is_empty():
            var s: Dictionary = _langkah.pop_front()
            if String(s["tipe"]) == "baris":
                _keluaran.append_text(_warna_baris(String(s["tipe_baris"]), String(s["teks"])) + "\n")
            elif String(s["tipe"]) == "clear":
                _keluaran.clear()
        else:
            _akhiri()
    _timer.stop()

func _tampil_status(s: Dictionary) -> void:
    _status_teks = String(s["teks"])
    _status_gaya = String(s["gaya"])
    _status_bar = int(s["bar"])
    _status_mulai = Time.get_ticks_msec()
    _status.visible = true

# Animasi status: spinner, titik bergerak, atau bilah progres. Hanya tampilan, tidak mengubah data.
func _perbarui_status() -> void:
    if not _status.visible:
        return
    var frame := int((Time.get_ticks_msec() - _status_mulai) / 120.0)
    match _status_gaya:
        "spinner":
            _status.text = "%s %s" % ["|/-\\"[frame % 4], _status_teks]
        "titik":
            _status.text = "%s%s" % [_status_teks.rstrip("."), ".".repeat(frame % 4)]
        "bar":
            var n := clampi(_status_bar, 0, 10)
            _status.text = "[%s%s] %s" % ["•".repeat(n), " ".repeat(10 - n), _status_teks]

func _warna_baris(tipe: String, teks: String) -> String:
    var warna := WARNA_ERROR if tipe == "error" else WARNA_TEKS
    return "[color=%s]%s[/color]" % [warna, _aman(teks)]

func _riwayat(arah: int) -> void:
    if _sesi == null:
        return
    var r: Array = _sesi.riwayat
    if r.is_empty():
        return
    _riwayat_idx = clampi(_riwayat_idx + arah, 0, r.size())
    _set_teks(String(r[_riwayat_idx]) if _riwayat_idx < r.size() else "")

# Tab: melengkapi perintah atau nama berkas/direktori. Bila banyak kecocokan, daftarnya ditampilkan.
func _lengkapi() -> void:
    if _sesi == null:
        return
    var hasil := ShellComplete.lengkapi(_sesi, _masukan.text)
    _set_teks(String(hasil["teks"]))
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
