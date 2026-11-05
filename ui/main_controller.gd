class_name MainController
extends Control

# Pengatur alur layar: Splash → Desktop → Aplikasi.
# Ukuran semua layar diset eksplisit ke ukuran viewport dan dihitung ulang saat layar berubah,
# supaya tidak bergantung pada urutan layout. Area aman (notch, status bar) dibaca dari perangkat.

const LATAR := Color("0d1117")
const LOGO := "res://assets/logo/logo_jtn.png"

var _desktop: DesktopView
var _jendela: ManajerJendela
var _konfirmasi: KonfirmasiPanel
var _aman := Vector4.ZERO  # kiri, atas, kanan, bawah dalam satuan viewport

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    get_viewport().size_changed.connect(_sesuaikan_ukuran)
    _sesuaikan_ukuran()
    _tampilkan_splash()

func _sesuaikan_ukuran() -> void:
    var vp := get_viewport_rect().size
    position = Vector2.ZERO
    size = vp
    _aman = _hitung_area_aman(vp)
    for anak in get_children():
        # Splash mengikuti anchor sendiri; menetapkan size di sini akan menggandakan layarnya.
        if anak is Control and not anak.has_meta("tanpa_ukuran"):
            anak.position = Vector2.ZERO
            anak.size = vp
    if is_instance_valid(_desktop):
        _desktop.atur_aman(_aman)
    _atur_area_jendela()
    if is_instance_valid(_konfirmasi):
        _konfirmasi.atur_aman(_aman)

# Mengubah area aman dari piksel layar ke satuan viewport. Dengan stretch canvas_items
# dan aspect expand, skala seragam di kedua sumbu, jadi cukup satu nilai skala.
func _hitung_area_aman(vp: Vector2) -> Vector4:
    var layar := Vector2(DisplayServer.screen_get_size())
    if layar.x <= 0.0 or layar.y <= 0.0:
        return Vector4.ZERO
    var aman := Rect2(DisplayServer.get_display_safe_area())
    var skala := minf(vp.x / layar.x, vp.y / layar.y)
    return Vector4(
        aman.position.x * skala,
        aman.position.y * skala,
        (layar.x - aman.end.x) * skala,
        (layar.y - aman.end.y) * skala
    )

# Splash: latar penuh layar, logo utuh di tengah area aman. Anchor diatur setelah node masuk pohon
# dan tanpa ukuran eksplisit. Menetapkan size pada node ber-anchor penuh menambah offset ke ukuran
# induk, sehingga layar menjadi dua kali lebih besar dan logo terdorong keluar layar.
const JARAK_SPLASH := 24
const SKALA_LOGO := 0.6

func _tampilkan_splash() -> void:
    var splash := _buat_splash(size, _aman)
    add_child(splash)
    await get_tree().create_timer(1.6).timeout
    if not is_instance_valid(splash):
        return
    var tween := create_tween()
    tween.tween_property(splash, "modulate:a", 0.0, 0.4)
    await tween.finished
    splash.queue_free()
    _tampilkan_menu()

# Membangun layar splash tanpa menambahkannya ke pohon. Pemanggil yang menaruhnya di induk.
func _buat_splash(ukuran: Vector2, aman: Vector4) -> Control:
    var splash := Control.new()
    splash.set_meta("tanpa_ukuran", true)
    splash.add_child(_isi_splash(ukuran, aman))
    splash.set_anchors_preset(Control.PRESET_FULL_RECT)
    return splash

func _isi_splash(ukuran: Vector2, aman: Vector4) -> Control:
    var isi := Control.new()
    var latar := ColorRect.new()
    latar.color = LATAR
    isi.add_child(latar)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", int(aman.x) + JARAK_SPLASH)
    margin.add_theme_constant_override("margin_top", int(aman.y) + JARAK_SPLASH)
    margin.add_theme_constant_override("margin_right", int(aman.z) + JARAK_SPLASH)
    margin.add_theme_constant_override("margin_bottom", int(aman.w) + JARAK_SPLASH)
    isi.add_child(margin)
    var tengah := CenterContainer.new()
    margin.add_child(tengah)
    var logo := TextureRect.new()
    logo.texture = load(LOGO) as Texture2D
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var sisi := minf(ukuran.x, ukuran.y) * SKALA_LOGO
    logo.custom_minimum_size = Vector2(sisi, sisi)
    tengah.add_child(logo)
    # Anchor diberikan setelah semua anak terpasang; offset dihitung ulang dari induk, bukan dari ukuran.
    isi.set_anchors_preset(Control.PRESET_FULL_RECT)
    latar.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
    return isi

# Menu utama adalah layar pertama setelah splash. Dari sini pemain masuk ke Desktop.
func _tampilkan_menu() -> void:
    var menu := MenuUtama.new()
    menu.size = size
    menu.atur_aman(_aman)
    menu.mulai.connect(_mulai_dari_menu.bind(menu))
    menu.keluar_diminta.connect(func(): get_tree().quit())
    add_child(menu)
    menu.position = Vector2.ZERO
    menu.size = size

func _mulai_dari_menu(_mode: String, menu: MenuUtama) -> void:
    menu.queue_free()
    _tampilkan_desktop()

func _tampilkan_desktop() -> void:
    _desktop = DesktopView.new()
    _desktop.aman = _aman
    _desktop.buka_aplikasi.connect(_buka_aplikasi)
    _desktop.menu_diminta.connect(_minta_kembali_menu)
    add_child(_desktop)
    _desktop.position = Vector2.ZERO
    _desktop.size = size
    _jendela = ManajerJendela.new()
    add_child(_jendela)
    _jendela.position = Vector2.ZERO
    _jendela.size = size
    _atur_area_jendela()

# Area kerja jendela: di antara panel atas dan taskbar, di dalam bingkai Desktop.
# Area penuh (maximize) menutupi panel dan taskbar, tetapi tetap di dalam area aman.
func _atur_area_jendela() -> void:
    if not is_instance_valid(_jendela):
        return
    var vp := size
    var tepi := DesktopView.JARAK_BINGKAI
    var kiri := _aman.x + tepi
    var kanan := vp.x - _aman.z - tepi
    var atas := _aman.y + tepi
    var bawah := vp.y - _aman.w - tepi
    var kerja := Rect2(Vector2(kiri, atas + DesktopView.TINGGI_PANEL), Vector2(kanan - kiri, bawah - atas - DesktopView.TINGGI_PANEL - DesktopView.TINGGI_TASKBAR))
    var penuh := Rect2(Vector2(kiri, atas), Vector2(kanan - kiri, bawah - atas))
    _jendela.atur_area(kerja, penuh)

# Kembali ke menu tidak menghapus apa pun: sesi disimpan dulu, lalu Desktop ditutup.
# Pemain bisa memilih Lanjutkan di menu untuk meneruskan dari posisi yang sama.
func _minta_kembali_menu() -> void:
    if not is_instance_valid(_konfirmasi):
        _konfirmasi = KonfirmasiPanel.new()
        _konfirmasi.diterima.connect(_kembali_ke_menu)
        _konfirmasi.dibatalkan.connect(_konfirmasi.sembunyikan)
        add_child(_konfirmasi)
    _konfirmasi.atur_aman(_aman)
    _konfirmasi.tampil("Kembali ke menu?", "Progres kamu disimpan. Pilih Lanjutkan di menu untuk meneruskan dari sini. Tidak ada data yang dihapus.", "Kembali ke Menu", "Batal")

func _kembali_ke_menu() -> void:
    _konfirmasi.sembunyikan()
    if not Penyimpanan.simpan_sesi(SesiUtama.ambil()):
        push_warning("Sesi gagal disimpan; tetap di Desktop agar data tidak hilang.")
        return
    if is_instance_valid(_jendela):
        _jendela.queue_free()
    _jendela = null
    if is_instance_valid(_desktop):
        _desktop.queue_free()
    _desktop = null
    _tampilkan_menu()

func _buka_aplikasi(id: String) -> void:
    _jendela.buka(id, DesktopView.nama_aplikasi(id), DesktopView.ikon_aplikasi(id), _buat_konten(id))

func _buat_konten(id: String) -> Control:
    match id:
        "terminal":
            return TerminalScreen.new()
        "peta":
            return NetworkMap.new()
        "pasar":
            return PasarScreen.new()
        "misi":
            return PusatMisi.new()
        _:
            return _konten_segera_hadir(DesktopView.nama_aplikasi(id))

func _konten_segera_hadir(nama: String) -> Control:
    var teks := Tema.label("%s akan tersedia pada tahap berikutnya." % nama, Tema.TEKS, 24)
    teks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return teks
