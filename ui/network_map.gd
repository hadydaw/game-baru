class_name NetworkMap
extends Control

# Peta Jaringan interaktif. Membaca Jaringan dari SesiUtama, sumber yang sama dengan Terminal,
# sehingga perubahan dari Terminal (ping, nmap, ssh) langsung tampil di sini.
# Ketuk node untuk melihat detail. Ketuk area kosong untuk menutup detail.

const TINGGI_LEGENDA := 64.0
const TINGGI_PANEL := 300.0
const RADIUS_NODE := 38.0
const RADIUS_SENTUH := 52.0
const WARNA_LATAR := Color("#0d1117")
const WARNA_GELAP := Color(0.03, 0.05, 0.07)

var _sesi: ShellSession
var _j: Jaringan
var _sidik_terakhir := ""
var _pilih := ""
var _waktu := 0.0
var _panel: PanelContainer
var _lbl_hint: Label
var _kolom_detail: VBoxContainer
var _lbl_nama: Label
var _lbl_ip: Label
var _lbl_status: Label
var _lbl_akses: Label
var _lbl_port: Label
var _lbl_tetangga: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    _sesi = SesiUtama.ambil()
    _j = _sesi.jaringan
    _bangun_legenda()
    _bangun_panel()
    resized.connect(_susun)
    _susun()
    _segarkan_detail()

func _bangun_legenda() -> void:
    var baris := HBoxContainer.new()
    baris.position = Vector2(12, 14)
    baris.add_theme_constant_override("separation", 18)
    baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(baris)
    baris.add_child(_legenda("●", Tema.TEAL, "Aktif"))
    baris.add_child(_legenda("●", Tema.TEKS_REDUP, "Tidak aktif"))
    baris.add_child(_legenda("●", Tema.AMBER, "Terkunci"))

func _legenda(simbol: String, warna: Color, teks: String) -> HBoxContainer:
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 6)
    h.mouse_filter = Control.MOUSE_FILTER_IGNORE
    h.add_child(Tema.label(simbol, warna, 22))
    h.add_child(Tema.label(teks, Tema.TEKS_REDUP, 20))
    return h

func _bangun_panel() -> void:
    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", Tema.kotak(Tema.LATAR_PANEL, Tema.TEAL, 2, 14))
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_panel)
    var margin := MarginContainer.new()
    Tema.margin_seragam(margin, 14)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.add_child(margin)
    var tumpuk := VBoxContainer.new()
    tumpuk.add_theme_constant_override("separation", 6)
    tumpuk.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(tumpuk)
    _lbl_hint = Tema.label("Ketuk node untuk melihat detail.", Tema.TEKS_REDUP, 22)
    tumpuk.add_child(_lbl_hint)
    _kolom_detail = VBoxContainer.new()
    _kolom_detail.add_theme_constant_override("separation", 4)
    _kolom_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tumpuk.add_child(_kolom_detail)
    _lbl_nama = Tema.label("", Tema.TEAL, 30)
    _lbl_ip = Tema.label("", Tema.TEKS_REDUP, 20)
    _lbl_status = Tema.label("", Tema.TEKS, 22)
    _lbl_akses = Tema.label("", Tema.TEKS, 22)
    _lbl_port = Tema.label("", Tema.TEKS, 20)
    _lbl_port.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _lbl_tetangga = Tema.label("", Tema.TEKS_REDUP, 20)
    _lbl_tetangga.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    for l in [_lbl_nama, _lbl_ip, _lbl_status, _lbl_akses, _lbl_port, _lbl_tetangga]:
        _kolom_detail.add_child(l)

func _susun() -> void:
    _panel.position = Vector2(0, size.y - TINGGI_PANEL)
    _panel.size = Vector2(size.x, TINGGI_PANEL)
    queue_redraw()

func _area_gambar() -> Rect2:
    return Rect2(0, TINGGI_LEGENDA, size.x, size.y - TINGGI_LEGENDA - TINGGI_PANEL)

func _process(delta: float) -> void:
    _waktu += delta
    var sidik := TataLetakPeta.sidik(_j)
    if sidik != _sidik_terakhir:
        _sidik_terakhir = sidik
        if _pilih != "" and not _j.dikenal(_pilih):
            _pilih = ""
        _segarkan_detail()
        queue_redraw()
    elif _pilih != "":
        # Node yang dipilih berdenyut halus; digambar ulang tiap frame hanya saat ada pilihan.
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _tap(event.position)
        accept_event()

func _tap(titik: Vector2) -> void:
    var posisi := _posisi_node()
    for id in posisi:
        if titik.distance_to(posisi[id]) <= RADIUS_SENTUH:
            _pilih = "" if _pilih == id else String(id)
            _segarkan_detail()
            queue_redraw()
            return
    _pilih = ""
    _segarkan_detail()
    queue_redraw()

func _posisi_node() -> Dictionary:
    var ids: Array = []
    for n in _j.daftar_terlihat():
        ids.append(String(n["id"]))
    return TataLetakPeta.posisi(ids, _area_gambar())

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), WARNA_LATAR)
    var posisi := _posisi_node()
    for pasangan in TataLetakPeta.sambungan(_j):
        var a: String = pasangan[0]
        var b: String = pasangan[1]
        var hidup := _j.aktif(a) and _j.aktif(b) and not _j.terkunci(a) and not _j.terkunci(b)
        var warna := Color(Tema.TEAL, 0.65) if hidup else Color(Tema.TEKS_REDUP, 0.3)
        draw_line(posisi[a], posisi[b], warna, 3.0, true)
    var font := get_theme_default_font()
    for id in posisi:
        _gambar_node(String(id), posisi[id], font)

func _gambar_node(id: String, p: Vector2, font: Font) -> void:
    var keadaan := TataLetakPeta.keadaan(_j.ringkasan(id))
    var warna := Tema.TEAL
    if keadaan == "terkunci":
        warna = Tema.AMBER
    elif keadaan == "tidak_aktif":
        warna = Tema.TEKS_REDUP
    draw_circle(p, RADIUS_NODE, WARNA_GELAP)
    draw_arc(p, RADIUS_NODE, 0.0, TAU, 48, warna, 4.0, true)
    if id == _pilih:
        var denyut := 0.5 + 0.5 * sin(_waktu * 4.0)
        draw_arc(p, RADIUS_NODE + 12.0, 0.0, TAU, 48, Color(Tema.TEKS, 0.3 + 0.5 * denyut), 2.0, true)
    match keadaan:
        "aktif":
            draw_circle(p, 7.0, warna)
        "tidak_aktif":
            draw_line(p + Vector2(-12, -12), p + Vector2(12, 12), warna, 4.0, true)
            draw_line(p + Vector2(12, -12), p + Vector2(-12, 12), warna, 4.0, true)
        "terkunci":
            _gambar_gembok(p, warna)
    draw_string(font, p + Vector2(-70, RADIUS_NODE + 30), id, HORIZONTAL_ALIGNMENT_CENTER, 140, 22, Tema.TEKS)
    draw_string(font, p + Vector2(-70, RADIUS_NODE + 52), String(_j.data[id].get("ip", "")), HORIZONTAL_ALIGNMENT_CENTER, 140, 18, Tema.TEKS_REDUP)

func _gambar_gembok(p: Vector2, warna: Color) -> void:
    draw_rect(Rect2(p + Vector2(-10, -2), Vector2(20, 16)), warna)
    draw_arc(p + Vector2(0, -2), 7.0, PI, TAU, 16, warna, 3.0, true)

func _segarkan_detail() -> void:
    if _pilih == "" or not _j.dikenal(_pilih):
        _lbl_hint.visible = true
        _kolom_detail.visible = false
        return
    _lbl_hint.visible = false
    _kolom_detail.visible = true
    var r := _j.ringkasan(_pilih)
    var keadaan := TataLetakPeta.keadaan(r)
    _lbl_nama.text = _pilih
    _lbl_ip.text = "IP  %s" % String(r["ip"])
    _lbl_status.text = "Status  %s" % _teks_keadaan(keadaan)
    _lbl_akses.text = "Akses  %s" % ("terkunci, akses belum terbuka" if keadaan == "terkunci" else "terbuka")
    if keadaan == "terkunci":
        _lbl_port.text = "Detail port tidak tersedia."
        _lbl_tetangga.text = ""
        return
    _lbl_port.text = "Port  " + _teks_port(r["port"])
    var tetangga: Array = []
    for t in r["tetangga"]:
        tetangga.append(String(t))
    _lbl_tetangga.text = "Terhubung ke  " + (", ".join(PackedStringArray(tetangga)) if not tetangga.is_empty() else "-")

func _teks_keadaan(keadaan: String) -> String:
    match keadaan:
        "aktif":
            return "Aktif"
        "terkunci":
            return "Terkunci"
    return "Tidak aktif"

func _teks_port(port: Dictionary) -> String:
    var kunci := port.keys()
    kunci.sort()
    var bagian: Array = []
    for k in kunci:
        var pd: Dictionary = port[k]
        bagian.append("%s/tcp %s %s" % [String(k), String(pd.get("status", "")), String(pd.get("layanan", ""))])
    return "\n".join(PackedStringArray(bagian)) if not bagian.is_empty() else "-"

# Untuk tes: jumlah node yang tampak di peta saat ini.
func jumlah_node_terlihat() -> int:
    return _j.daftar_terlihat().size()

# Untuk tes: memilih node seperti ketukan pemain.
func pilih_node(id: String) -> void:
    _pilih = id if _j.dikenal(id) else ""
    _segarkan_detail()
    queue_redraw()

func teks_detail() -> String:
    return _lbl_ip.text if _pilih != "" else _lbl_hint.text
