class_name TerminalScreen
extends Control

# Layar terminal. Hanya menampilkan keluaran dan menerima masukan.
# Logika shell ada di core/shell.

const WARNA := {"info": "#c9d1d9", "error": "#ff7b72", "clear": "#c9d1d9"}
const FS_PATH := "res://data/fs/pemain.json"

var _sesi: ShellSession
var _keluaran: RichTextLabel
var _masukan: LineEdit
var _label_prompt: Label

func _ready() -> void:
    _bangun_ui()
    _muat_sesi()

func _bangun_ui() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var latar := ColorRect.new()
    latar.color = Color("0d1117")
    latar.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(latar)
    var kolom := VBoxContainer.new()
    kolom.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(kolom)
    _keluaran = RichTextLabel.new()
    _keluaran.bbcode_enabled = true
    _keluaran.scroll_following = true
    _keluaran.size_flags_vertical = SIZE_EXPAND_FILL
    kolom.add_child(_keluaran)
    var baris := HBoxContainer.new()
    _label_prompt = Label.new()
    _label_prompt.add_theme_color_override("font_color", Color("#7ee787"))
    baris.add_child(_label_prompt)
    _masukan = LineEdit.new()
    _masukan.size_flags_horizontal = SIZE_EXPAND_FILL
    _masukan.custom_minimum_size = Vector2(0, 88)
    _masukan.text_submitted.connect(_kirim)
    baris.add_child(_masukan)
    kolom.add_child(baris)

func _muat_sesi() -> void:
    var data := _baca_fs()
    _sesi = ShellSession.new(Vfs.new(data))
    _perbarui_prompt()
    _tampil([{"tipe": "info", "teks": "Terminal siap."}])
    _tampil(_sesi.jalankan("pwd"))
    _tampil([{"tipe": "info", "teks": "Ketik \"help\" untuk daftar perintah."}])

# File JSON membungkus root di bawah kunci "/". Vfs membutuhkan node root langsung.
func _baca_fs() -> Dictionary:
    if not FileAccess.file_exists(FS_PATH):
        _tampil([{"tipe": "error", "teks": "Berkas filesystem tidak ditemukan: %s" % FS_PATH}])
        return _fs_cadangan()
    var data = JSON.parse_string(FileAccess.get_file_as_string(FS_PATH))
    if typeof(data) != TYPE_DICTIONARY or not data.has("/"):
        _tampil([{"tipe": "error", "teks": "Format filesystem tidak valid."}])
        return _fs_cadangan()
    return data["/"]

func _fs_cadangan() -> Dictionary:
    return {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}

func _kirim(teks: String) -> void:
    var t := teks.strip_edges()
    _masukan.clear()
    if t.is_empty():
        _tampil([{"tipe": "info", "teks": _sesi.prompt()}])
        return
    _tampil([{"tipe": "info", "teks": "%s %s" % [_sesi.prompt(), t]}])
    _tampil(_sesi.jalankan(t))
    _perbarui_prompt()

func _perbarui_prompt() -> void:
    _label_prompt.text = _sesi.prompt()

func _tampil(baris: Array) -> void:
    for b in baris:
        if String(b["tipe"]) == "clear":
            _keluaran.clear()
            continue
        var warna := String(WARNA.get(String(b["tipe"]), "#c9d1d9"))
        var aman := String(b["teks"]).replace("[", "[lb]")
        _keluaran.append_text("[color=%s]%s[/color]\n" % [warna, aman])
