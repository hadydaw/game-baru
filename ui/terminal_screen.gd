class_name TerminalScreen
extends Control

# Layar terminal tahap 1. Hanya menampilkan keluaran dan menerima masukan.
# Logika shell ada di core/shell.

const WARNA := {"info": "#c9d1d9", "error": "#ff7b72", "clear": "#c9d1d9"}

var _sesi: ShellSession
var _keluaran: RichTextLabel
var _masukan: LineEdit
var _label_prompt: Label

func _ready() -> void:
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
    baris.add_child(_label_prompt)
    _masukan = LineEdit.new()
    _masukan.size_flags_horizontal = SIZE_EXPAND_FILL
    _masukan.custom_minimum_size = Vector2(0, 88)
    _masukan.text_submitted.connect(_kirim)
    baris.add_child(_masukan)
    kolom.add_child(baris)
    var fs := Vfs.new(_baca_fs())
    _sesi = ShellSession.new(fs)
    _perbarui_prompt()
    _tampil(_sesi.jalankan("pwd"))
    _tampil([{"tipe": "info", "teks": "Ketik \"help\" untuk daftar perintah."}])

func _baca_fs() -> Dictionary:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    var data = JSON.parse_string(isi)
    return data if typeof(data) == TYPE_DICTIONARY else {}

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
