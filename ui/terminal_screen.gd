class_name TerminalScreen
extends Control

# Aplikasi Terminal: output monospace, prompt berwarna, baris tombol khusus Linux, dan riwayat.
# Logika perintah tetap di core/shell. Layar ini hanya menampilkan dan meneruskan masukan.

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const FS_PATH := "res://data/fs/pemain.json"
const UKURAN_TOMBOL := 22
const TINGGI_TOMBOL := 64
# Tombol keyboard di layar: tinggi dan lebar minimum 48 dp agar nyaman disentuh.
const TINGGI_KUNCI := 56
const LEBAR_KUNCI := 48
const WARNA_USER := "#3fb950"
const WARNA_JALUR := "#2dd4bf"
const WARNA_TEKS := "#e6f7f5"
const WARNA_ERROR := "#ff7b72"
const LATAR := Color("#0d1117")
const BATAS_BUFFER := 60000
# Tiga baris tombol: simbol, navigasi, lalu kontrol.
const BARIS_TOMBOL := [["/", "-", "_", "|"], [".", "~", "↑", "↓"], ["Tab", "Ctrl", "Enter", "Backspace"]]

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
# Mode live airodump-ng: bingkai diperbarui tiap interval -u sampai Ctrl+C.
var _live_timer: Timer
var _live := false
var _live_buffer_awal := ""
var _live_entri_awal := 0
var _live_terakhir: Array = []
var _status: Label
var _busy: bool = false
var _antrean: Array = []
var _langkah: Array = []
var _ketik_teks: String = ""
# Teks yang benar-benar diketik: hanya bahasa aktif. _ketik_teks tetap dua bahasa agar tersimpan dan ikut ganti bahasa.
var _ketik_tampil: String = ""
var _ketik_kunci: String = ""
var _ketik_args: Array = []
var _ketik_perintah: String = ""
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
    _keluaran.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # teks di layar HP membungkus, tidak terpotong
    _keluaran.selection_enabled = true
    _keluaran.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _keluaran.add_theme_font_override("normal_font", _font)
    _keluaran.add_theme_font_size_override("normal_font_size", _ukuran_font())
    _keluaran.add_theme_color_override("default_color", Color(WARNA_TEKS))
    _keluaran.add_theme_stylebox_override("normal", _gaya_latar())
    kolom.add_child(_keluaran)

    var baris := HBoxContainer.new()
    baris.add_theme_constant_override("separation", 8)
    _label_prompt = Label.new()
    _label_prompt.add_theme_font_override("font", _font)
    _label_prompt.add_theme_font_size_override("font_size", _ukuran_font())
    _label_prompt.add_theme_color_override("font_color", Color(WARNA_USER))
    baris.add_child(_label_prompt)
    _masukan = LineEdit.new()
    _masukan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _masukan.custom_minimum_size = Vector2(0, TINGGI_TOMBOL)
    _masukan.caret_blink = true
    _masukan.clear_button_enabled = false
    _masukan.add_theme_font_override("font", _font)
    _masukan.add_theme_font_size_override("font_size", _ukuran_font())
    _masukan.add_theme_color_override("font_color", Color(WARNA_TEKS))
    _masukan.add_theme_stylebox_override("normal", Tema.kotak(Color(0.05, 0.08, 0.1), Tema.TEAL, 1, 10))
    _masukan.add_theme_stylebox_override("focus", Tema.kotak(Color(0.05, 0.08, 0.1), Tema.TEAL, 2, 10))
    _masukan.text_submitted.connect(_kirim)
    _masukan.text_changed.connect(_teks_berubah)
    baris.add_child(_masukan)
    _status = Label.new()
    _status.add_theme_font_override("font", _font)
    _status.add_theme_font_size_override("font_size", _ukuran_font() - 4)
    _status.add_theme_color_override("font_color", Color(WARNA_JALUR))
    _status.visible = false
    kolom.add_child(_status)
    kolom.add_child(baris)

    _timer = Timer.new()
    _timer.one_shot = true
    _timer.timeout.connect(_lanjut)
    add_child(_timer)
    _live_timer = Timer.new()
    _live_timer.one_shot = false
    _live_timer.timeout.connect(_live_segarkan)
    add_child(_live_timer)

    kolom.add_child(_buat_baris_tombol())

    tree_exiting.connect(_saat_keluar)
    _sesi = _buat_sesi()
    _perbarui_prompt()
    # Terminal ikut diperbarui saat bahasa diganti: seluruh riwayat dirender ulang dari catatan entri.
    set_meta("bsegar", Callable(self, "_segarkan_bahasa"))
    if _sesi == null:
        return
    _riwayat_idx = _sesi.riwayat.size()
    if _buffer_bersama.is_empty():
        _tampil([{"tipe": "info", "kunci": "term.siap"}])
        _tampil(_sesi.jalankan("pwd"))
    else:
        # Layar dibuka lagi: tampilkan kembali seluruh riwayat, tanpa banner dan tanpa pwd baru.
        _keluaran.append_text(_buffer_bersama)
        _pulihkan_scroll()

# Menulis ke tampilan sekaligus ke buffer bersama. Buffer dipangkas per baris agar tag BBCode tetap utuh.
func _tulis(bb: String) -> void:
    _keluaran.append_text(bb)
    _buffer_bersama += bb
    if _buffer_bersama.length() > BATAS_BUFFER:
        var potong := _buffer_bersama.find("\n", _buffer_bersama.length() - BATAS_BUFFER)
        if potong >= 0:
            _buffer_bersama = _buffer_bersama.substr(potong + 1)

func _kosongkan() -> void:
    _keluaran.clear()
    _buffer_bersama = ""
    _entri_bersama.clear()

# Catatan setiap baris yang sudah selesai. Baris berkunci dirender ulang dengan bahasa aktif.
static var _entri_bersama: Array = []
const BATAS_ENTRI := 800

func _simpan_entri(e: Dictionary) -> void:
    _entri_bersama.append(e)
    if _entri_bersama.size() > BATAS_ENTRI:
        _entri_bersama = _entri_bersama.slice(_entri_bersama.size() - BATAS_ENTRI)

func _teks_entri(e: Dictionary) -> String:
    var kunci := String(e.get("kunci", ""))
    if kunci == "":
        return Bahasa.pilih(String(e.get("teks", "")))
    var args: Array = e.get("args", [])
    var teks := Bahasa.t(kunci) % args if not args.is_empty() else Bahasa.t(kunci)
    if String(e.get("perintah", "")) != "":
        teks = "bash: %s: %s" % [String(e["perintah"]), teks]
    return teks

func _bb_entri(e: Dictionary) -> String:
    if String(e.get("tipe", "")) == "prompt":
        return _bb_perintah(String(e["teks"]), String(e["prompt"]))
    return "[color=%s]%s[/color]\n" % [_warna_tipe(String(e.get("tipe", "info"))), _aman(_teks_entri(e))]

func _warna_tipe(tipe: String) -> String:
    return WARNA_ERROR if tipe == "error" else WARNA_TEKS

# Dipanggil saat bahasa diganti: animasi dihentikan dulu, lalu seluruh riwayat ditulis ulang.
func _segarkan_bahasa() -> void:
    if not is_instance_valid(_keluaran):
        return
    if _busy:
        _selesaikan_cepat()
    _keluaran.clear()
    _buffer_bersama = ""
    for e in _entri_bersama:
        _tulis(_bb_entri(e))
    _perbarui_prompt()

# Dipanggil saat layar dilepas (berpindah ke Desktop atau aplikasi lain).
# Animasi yang belum selesai diselesaikan dulu agar buffer utuh, lalu posisi scroll dicatat.
func _saat_keluar() -> void:
    if _live:
        _hentikan_live()
    if _busy:
        _selesaikan_cepat()
    _simpan_posisi()
    _simpan()

func _simpan_posisi() -> void:
    if not is_instance_valid(_keluaran):
        return
    var bar := _keluaran.get_v_scroll_bar()
    _ikut_bawah_bersama = _keluaran.scroll_following or bar.value >= bar.max_value - bar.page - 4.0
    _scroll_bersama = bar.value

func _pulihkan_scroll() -> void:
    await get_tree().process_frame
    if not is_instance_valid(_keluaran):
        return
    _keluaran.scroll_following = _ikut_bawah_bersama
    if not _ikut_bawah_bersama:
        _keluaran.get_v_scroll_bar().value = _scroll_bersama

# Membuat sesi shell. Bila gagal, galat ditampilkan di layar agar tidak diam-diam.
# Sesi disimpan di luar layar agar filesystem dan direktori kerja tetap ada saat pindah aplikasi.
static var _sesi_bersama: ShellSession

# Ukuran teks mengikuti pengaturan pemain. Dibaca saat layar dibuat, jadi berlaku saat Terminal dibuka.
func _ukuran_font() -> int:
    return Pengaturan.ukuran_font()

# Dipanggil saat Sesi Baru: buffer dan sesi bersama dilepas agar Terminal mulai dari awal.
static func reset_sesi() -> void:
    _sesi_bersama = null
    _buffer_bersama = ""
    _entri_bersama = []
    _scroll_bersama = 0.0
    _ikut_bawah_bersama = true
# Buffer tampilan dan posisi scroll ikut bertahan saat layar Terminal ditutup lalu dibuka lagi.
static var _buffer_bersama: String = ""
static var _scroll_bersama: float = 0.0
static var _ikut_bawah_bersama: bool = true

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
        _simpan_posisi()
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

# Bobot lebar tombol: tombol berlabel panjang mendapat lebih banyak ruang dalam baris kontrol.
const BOBOT_TOMBOL := {"Backspace": 1.8, "Enter": 1.2}

func _buat_baris_tombol() -> Control:
    var kolom := VBoxContainer.new()
    kolom.add_theme_constant_override("separation", 6)
    for baris_kunci in BARIS_TOMBOL:
        var baris := HBoxContainer.new()
        baris.add_theme_constant_override("separation", 4)
        kolom.add_child(baris)
        for t in baris_kunci:
            baris.add_child(_buat_tombol(String(t)))
    return kolom

func _buat_tombol(t: String) -> Button:
    var b := Button.new()
    b.text = t
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size = Vector2(LEBAR_KUNCI, TINGGI_KUNCI)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.size_flags_stretch_ratio = float(BOBOT_TOMBOL.get(t, 1.0))
    b.add_theme_font_override("font", _font)
    var kata := t.length() > 1 and t != "↑" and t != "↓"
    var ukuran := UKURAN_TOMBOL
    if kata:
        ukuran = 14 if t == "Backspace" else 16
    b.add_theme_font_size_override("font_size", ukuran)
    b.add_theme_color_override("font_color", Color(WARNA_TEKS))
    b.add_theme_stylebox_override("normal", _gaya_tombol(Color(0.06, 0.09, 0.12)))
    b.add_theme_stylebox_override("hover", _gaya_tombol(Color(0.08, 0.13, 0.15)))
    b.add_theme_stylebox_override("pressed", _gaya_tombol(Color(0.1, 0.22, 0.22)))
    if t == "Ctrl":
        _tombol_ctrl = b
    b.pressed.connect(_tekan_tombol.bind(t))
    return b

func _gaya_tombol(bg: Color) -> StyleBoxFlat:
    var s := Tema.kotak(bg, Tema.TEAL, 1, 10)
    s.content_margin_left = 2.0
    s.content_margin_right = 2.0
    return s

func _process(_delta: float) -> void:
    _perbarui_status()
    # Saat keyboard HP muncul, area terminal dinaikkan agar output dan baris input tidak tertutup.
    # Hanya di platform yang punya keyboard layar (HP). Di PC tidak perlu dicek setiap frame.
    if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
        return
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
    if _live and a == "batal":
        _hentikan_live()
        return
    if _busy and a == "batal" and _sesi != null and _sesi.live_aktif():
        # Ctrl+C saat animasi pembuka airodump-ng: batalkan mode live sebelum dimulai.
        _sesi.live_hentikan()
        _tulis("^C\n")
        _selesaikan_cepat()
        return
    if _busy and a == "batal":
        # Ctrl+C saat animasi berjalan: tampilkan sisa output sekarang juga.
        _selesaikan_cepat()
        return
    match a:
        "batal":
            _tampil_perintah(_masukan.text + "^C")
            _set_teks("")
        "bersihkan":
            _kosongkan()
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
    if _live:
        # Saat airodump-ng berjalan, input shell tidak diproses dan tidak diantrikan.
        _tampil([{"tipe": "info", "kunci": "term.live_sibuk"}])
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

signal minta_aplikasi(id: String)

func _mulai(t: String) -> void:
    _tampil_perintah(t)
    _live_buffer_awal = _buffer_bersama
    _live_entri_awal = _entri_bersama.size()
    _sesi.lebar_kolom = _lebar_kolom_terminal()
    _sesi.live_diizinkan = true
    var hasil := _sesi.jalankan(t)
    _sesi.live_diizinkan = false
    _riwayat_idx = _sesi.riwayat.size()
    _simpan()
    _langkah = Animasi.rencana(t, hasil)
    _busy = true
    _timer.start(0.02)
    # Perintah yang meminta aplikasi dibuka (misalnya scan Wi-Fi) membuka jendelanya setelah keluaran tampil.
    if _sesi.permintaan_aplikasi != "":
        var id := _sesi.permintaan_aplikasi
        _sesi.permintaan_aplikasi = ""
        minta_aplikasi.emit(id)

# Dipanggil Timer: menjalankan satu langkah animasi (status, pengetikan baris, atau jeda).
func _lanjut() -> void:
    if _ketik_aktif:
        var sisa := _ketik_tampil.length() - _ketik_pos
        var n := clampi(ceili(sisa / 10.0), 2, 8)
        _tulis(_warna_baris(_ketik_tipe, _ketik_tampil.substr(_ketik_pos, n)))
        _ketik_pos += n
        if _ketik_pos >= _ketik_tampil.length():
            _tulis("\n")
            _ketik_aktif = false
            _simpan_entri({"tipe": _ketik_tipe, "teks": _ketik_teks, "kunci": _ketik_kunci, "args": _ketik_args, "perintah": _ketik_perintah})
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
            _ketik_tampil = Bahasa.pilih(_ketik_teks)
            _ketik_tipe = String(s["tipe_baris"])
            _ketik_kunci = String(s.get("kunci", ""))
            _ketik_args = Array(s.get("args", []))
            _ketik_perintah = String(s.get("perintah", ""))
            _ketik_pos = 0
            _ketik_aktif = true
            _ketik_jeda = int(s["jeda"])
            _timer.start(0.01)
        "clear":
            _kosongkan()
            _timer.start(0.01)

func _akhiri() -> void:
    _busy = false
    _status.visible = false
    _perbarui_prompt()
    if _sesi != null and _sesi.live_aktif():
        _mulai_live()
        return
    if not _antrean.is_empty():
        _mulai(String(_antrean.pop_front()))

# Lebar layar dalam karakter, dihitung dari lebar area keluaran dan lebar satu karakter monospace (0,6 em).
func _lebar_kolom_terminal() -> int:
    var lebar := _keluaran.size.x - 16.0
    return maxi(int(lebar / (0.6 * float(_ukuran_font()))), 20)

# Mulai mode live: animasi bingkai pertama diganti oleh bingkai live di tempat yang sama.
func _mulai_live() -> void:
    _live = true
    # Perintah yang sempat diantrikan sebelum live dimulai tidak dijalankan setelah Ctrl+C.
    _antrean.clear()
    _buffer_bersama = _live_buffer_awal
    _entri_bersama = _entri_bersama.slice(0, _live_entri_awal)
    _live_segarkan()
    _live_timer.start(maxf(_sesi.live_interval(), 1.0))

# Satu bingkai live: menggantikan bingkai sebelumnya. Bingkai ini tidak disimpan ke riwayat sampai berhenti.
func _live_segarkan() -> void:
    if not _live or _sesi == null:
        return
    _sesi.lebar_kolom = _lebar_kolom_terminal()
    _live_terakhir = _sesi.live_langkah()
    var bb := ""
    for b in _live_terakhir:
        bb += _bb_entri({"tipe": String(b["tipe"]), "teks": String(b.get("teks", ""))})
    _keluaran.clear()
    _keluaran.append_text(_buffer_bersama + bb)

# Ctrl+C: hentikan mode live, tampilkan ^C, lalu simpan bingkai terakhir sebagai riwayat biasa.
func _hentikan_live() -> void:
    _live_timer.stop()
    _live = false
    _sesi.live_hentikan()
    _buffer_bersama = _live_buffer_awal
    _entri_bersama = _entri_bersama.slice(0, _live_entri_awal)
    _keluaran.clear()
    _keluaran.append_text(_buffer_bersama)
    _tulis("^C\n")
    _tampil(_live_terakhir)
    _live_terakhir = []
    _perbarui_prompt()
    if not _antrean.is_empty():
        _mulai(String(_antrean.pop_front()))

# Menyelesaikan semua animasi sekarang juga (dipakai Ctrl+C dan oleh tes).
func _selesaikan_cepat() -> void:
    while _busy:
        if _ketik_aktif:
            _tulis(_warna_baris(_ketik_tipe, _ketik_tampil.substr(_ketik_pos)) + "\n")
            _ketik_aktif = false
            _simpan_entri({"tipe": _ketik_tipe, "teks": _ketik_teks, "kunci": _ketik_kunci, "args": _ketik_args, "perintah": _ketik_perintah})
        elif not _langkah.is_empty():
            var s: Dictionary = _langkah.pop_front()
            if String(s["tipe"]) == "baris":
                _tulis(_warna_baris(String(s["tipe_baris"]), _teks_entri(s)) + "\n")
                _simpan_entri({"tipe": String(s["tipe_baris"]), "teks": String(s["teks"]), "kunci": String(s.get("kunci", "")), "args": Array(s.get("args", [])), "perintah": String(s.get("perintah", ""))})
            elif String(s["tipe"]) == "clear":
                _kosongkan()
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
            _status.text = "%s %s" % ["|/-\\"[frame % 4], Bahasa.pilih(_status_teks)]
        "titik":
            _status.text = "%s%s" % [Bahasa.pilih(_status_teks).rstrip("."), ".".repeat(frame % 4)]
        "bar":
            var n := clampi(_status_bar, 0, 10)
            _status.text = "[%s%s] %s" % ["•".repeat(n), " ".repeat(10 - n), Bahasa.pilih(_status_teks)]

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
    var p := _sesi.prompt() if _sesi != null else "%s@jtn:~$" % ShellSession.nama_pengguna_aktif()
    _simpan_entri({"tipe": "prompt", "teks": teks, "prompt": p})
    _tulis(_bb_perintah(teks, p))

func _bb_perintah(teks: String, p: String) -> String:
    var i := p.find(":")
    var user := p.substr(0, i)
    var jalur := p.substr(i + 1, p.length() - i - 2)
    return "[color=%s]%s[/color]:[color=%s]%s[/color]$ %s\n" % [WARNA_USER, user, WARNA_JALUR, jalur, _aman(teks)]

func _tampil(baris: Array) -> void:
    for b in baris:
        if String(b["tipe"]) == "clear":
            _kosongkan()
            continue
        var e := {"tipe": String(b["tipe"]), "teks": String(b.get("teks", ""))}
        for k in ["kunci", "args", "perintah"]:
            if b.has(k):
                e[k] = b[k]
        _simpan_entri(e)
        _tulis(_bb_entri(e))

func _aman(s: String) -> String:
    return Bahasa.pilih(s).replace("[", "[lb]")
