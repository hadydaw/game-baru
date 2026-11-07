class_name ManajerJendela
extends Control

# Mengatur jendela aplikasi di Android portrait. Satu jendela per aplikasi.
# Jendela terbuka mengisi area kerja (di antara panel atas dan taskbar). Maximize menutupi
# seluruh layar. Jendela yang diminimize tetap terdaftar dan bisa dipulihkan lewat taskbar.

signal daftar_berubah

# Urutan dari bawah ke atas. Jendela terakhir adalah yang aktif dan tampil di atas.
var _jendela: Array = []
var _area_kerja := Rect2()
var _area_penuh := Rect2()

func _ready() -> void:
    # Area kosong tidak menangkap sentuhan: sentuhan diteruskan ke Desktop di bawahnya.
    mouse_filter = Control.MOUSE_FILTER_IGNORE

# Area diberikan oleh MainController setiap ukuran layar berubah.
func atur_area(kerja: Rect2, penuh: Rect2) -> void:
    _area_kerja = kerja
    _area_penuh = penuh
    for j in _jendela:
        _terapkan_rect(j)

# Membuka jendela. Jika aplikasi sudah terbuka, jendela itu dipulihkan dan difokuskan, tidak diduplikasi.
func buka(id: String, judul: String, ikon: String, konten: Control) -> JendelaAplikasi:
    var ada := _cari(id)
    if ada != null:
        # Jendela yang sudah ada dibuka lagi: isinya disegarkan agar perubahan sesi (mis. email misi baru) ikut tampil.
        if ada.isi != null and ada.isi.has_method("segarkan_data"):
            ada.isi.call("segarkan_data")
        fokus(id)
        return ada
    var j := JendelaAplikasi.new()
    j.setup(id, judul, ikon, konten)
    j.fokus_diminta.connect(fokus)
    j.minimize_diminta.connect(minimize)
    j.maximize_diminta.connect(toggle_maksimal)
    j.tutup_diminta.connect(tutup)
    add_child(j)
    _jendela.append(j)
    _terapkan_rect(j)
    fokus(id)
    return j

# Memfokuskan jendela: memulihkan jika diminimize, lalu menaikkan ke urutan teratas.
func fokus(id: String) -> void:
    var j := _cari(id)
    if j == null:
        return
    if j.diminimize:
        j.diminimize = false
        j.visible = true
    _jendela.erase(j)
    _jendela.append(j)
    move_child(j, get_child_count() - 1)
    daftar_berubah.emit()

func minimize(id: String) -> void:
    var j := _cari(id)
    if j == null:
        return
    j.diminimize = true
    j.visible = false
    daftar_berubah.emit()

func toggle_maksimal(id: String) -> void:
    var j := _cari(id)
    if j == null:
        return
    j.maksimal = not j.maksimal
    _terapkan_rect(j)
    daftar_berubah.emit()

# Menutup jendela dan membebaskan kontennya. Progres permainan tetap tersimpan di sesi.
func tutup(id: String) -> void:
    var j := _cari(id)
    if j == null:
        return
    _jendela.erase(j)
    j.queue_free()
    daftar_berubah.emit()

func ada(id: String) -> bool:
    return _cari(id) != null

func jumlah() -> int:
    return _jendela.size()

# Id jendela yang sedang aktif (paling atas dan tidak diminimize). Kosong jika tidak ada.
func aktif() -> String:
    for i in range(_jendela.size() - 1, -1, -1):
        var j: JendelaAplikasi = _jendela[i]
        if not j.diminimize:
            return j.id
    return ""

# Daftar untuk taskbar, dari jendela pertama dibuka sampai terakhir.
func daftar() -> Array:
    var hasil: Array = []
    var aktif_id := aktif()
    for j in _jendela:
        hasil.append({
            "id": j.id,
            "judul": j.judul,
            "aktif": j.id == aktif_id,
            "diminimize": j.diminimize,
        })
    return hasil

func _cari(id: String) -> JendelaAplikasi:
    for j in _jendela:
        if j.id == id:
            return j
    return null

func _terapkan_rect(j: JendelaAplikasi) -> void:
    var r := _area_penuh if j.maksimal else _area_kerja
    j.position = r.position
    j.size = r.size
