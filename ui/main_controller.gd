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
var _menu_app: MenuAplikasi
var _aman := Vector4.ZERO  # kiri, atas, kanan, bawah dalam satuan viewport

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Bahasa.muat_dari_pengaturan()
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
    _buat_menu()

func _buat_menu() -> MenuUtama:
    var menu := MenuUtama.new()
    menu.size = size
    menu.atur_aman(_aman)
    menu.mulai.connect(_mulai_dari_menu.bind(menu))
    menu.keluar_diminta.connect(func(): get_tree().quit())
    menu.bahasa_diganti.connect(_ulang_menu.bind(menu))
    add_child(menu)
    menu.position = Vector2.ZERO
    menu.size = size
    return menu

# Bahasa berganti di Pengaturan: menu dibangun ulang dengan bahasa baru, Pengaturan tetap terbuka.
func _ulang_menu(lama: MenuUtama) -> void:
    lama.queue_free()
    var baru := _buat_menu()
    baru.buka_pengaturan_setelah_ganti_bahasa()

# Sesi baru membuka cerita pembuka dan pemilihan lokasi. Lanjutkan langsung ke Desktop.
func _mulai_dari_menu(mode: String, menu: MenuUtama) -> void:
    menu.queue_free()
    if mode == "baru":
        _tampilkan_cerita()
    else:
        _tampilkan_desktop()

func _tampilkan_cerita() -> void:
    var cerita := LayarCerita.new()
    cerita.name = "LayarCerita"
    cerita.size = size
    cerita.atur_aman(_aman)
    cerita.selesai.connect(_tampilkan_pilih_lokasi.bind(cerita))
    add_child(cerita)
    cerita.position = Vector2.ZERO
    cerita.size = size
    _transisi_masuk(cerita)

func _tampilkan_pilih_lokasi(sebelumnya: Control) -> void:
    sebelumnya.queue_free()
    var pilih := PilihLokasi.new()
    pilih.name = "PilihLokasi"
    pilih.size = size
    pilih.atur_aman(_aman)
    pilih.selesai.connect(_simpan_lokasi_awal)
    pilih.kembali.connect(_kembali_ke_cerita.bind(pilih))
    add_child(pilih)
    pilih.position = Vector2.ZERO
    pilih.size = size
    _transisi_masuk(pilih)

func _kembali_ke_cerita(sekarang: Control) -> void:
    sekarang.queue_free()
    _tampilkan_cerita()

func _simpan_lokasi_awal(kode_negara: String, kode_kota: String) -> void:
    var sesi := SesiUtama.ambil()
    sesi.lokasi = {"negara": kode_negara, "kota": kode_kota}
    Penyimpanan.simpan_sesi(sesi)
    for anak in get_children():
        if anak.name == "PilihLokasi":
            anak.queue_free()
    _tampilkan_desktop()
    _tawarkan_sambutan_email()

# Sesi baru: di Desktop muncul pemberitahuan email baru sekali. Tombol OK membuka aplikasi E-Mail.
func _tawarkan_sambutan_email() -> void:
    var sesi := SesiUtama.ambil()
    if Email.sambutan_sudah_tampil(sesi):
        return
    var popup := PopupSambutanEmail.new()
    popup.name = "PopupSambutan"
    popup.diterima.connect(func():
        Email.tandai_sambutan(sesi)
        Penyimpanan.simpan_sesi(sesi)
        popup.queue_free()
        _buka_aplikasi("email"))
    add_child(popup)
    popup.position = Vector2.ZERO
    popup.size = size
    popup.atur_aman(_aman)  # setelah masuk pohon, agar margin area aman terpasang

func _transisi_masuk(node: Control) -> void:
    node.modulate.a = 0.0
    var t := create_tween()
    t.tween_property(node, "modulate:a", 1.0, LayarCerita.DURASI_TRANSISI)

func _tampilkan_desktop() -> void:
    _desktop = DesktopView.new()
    _desktop.aman = _aman
    _desktop.buka_aplikasi.connect(_buka_aplikasi)
    _desktop.menu_diminta.connect(_minta_kembali_menu)
    _desktop.menu_aplikasi_diminta.connect(_buka_menu_aplikasi)
    add_child(_desktop)
    _desktop.position = Vector2.ZERO
    _desktop.size = size
    _jendela = ManajerJendela.new()
    add_child(_jendela)
    _jendela.position = Vector2.ZERO
    _jendela.size = size
    _desktop.hubungkan_jendela(_jendela)
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
    _konfirmasi.tampil(Bahasa.t("dialog.kembali_menu_judul"), Bahasa.t("dialog.kembali_menu_isi"), Bahasa.t("dialog.kembali_menu_ok"), Bahasa.t("umum.batal"))

func _kembali_ke_menu() -> void:
    _konfirmasi.sembunyikan()
    _tutup_menu_aplikasi()
    if not Penyimpanan.simpan_sesi(SesiUtama.ambil()):
        push_warning(Bahasa.t("dialog.gagal_simpan"))
        return
    if is_instance_valid(_jendela):
        _jendela.queue_free()
    _jendela = null
    if is_instance_valid(_desktop):
        _desktop.queue_free()
    _desktop = null
    _tampilkan_menu()

# Tombol home dan logo panel atas membuka Menu Aplikasi; ketuk lagi untuk menutup.
func _buka_menu_aplikasi() -> void:
    if is_instance_valid(_menu_app):
        _tutup_menu_aplikasi()
        return
    _menu_app = MenuAplikasi.new()
    add_child(_menu_app)
    var bawah := int(_aman.w) + DesktopView.JARAK_BINGKAI + HotBar.TINGGI + 10
    var atas := int(_aman.y) + DesktopView.JARAK_BINGKAI + PanelAtas.TINGGI + 10
    _menu_app.atur_area(atas, bawah)
    _menu_app.buka_aplikasi.connect(_pilih_dari_menu_aplikasi)
    _menu_app.keluar_diminta.connect(_keluar_dari_menu_aplikasi)
    _menu_app.tutup_diminta.connect(_tutup_menu_aplikasi)

func _pilih_dari_menu_aplikasi(id: String) -> void:
    _tutup_menu_aplikasi()
    _buka_aplikasi(id)

func _keluar_dari_menu_aplikasi() -> void:
    _tutup_menu_aplikasi()
    _minta_kembali_menu()

func _tutup_menu_aplikasi() -> void:
    if is_instance_valid(_menu_app):
        _menu_app.queue_free()
    _menu_app = null

func _buka_aplikasi(id: String) -> void:
    _jendela.buka(id, DesktopView.nama_aplikasi(id), DesktopView.ikon_aplikasi(id), _buat_konten(id))

func _buat_konten(id: String) -> Control:
    match id:
        "terminal":
            var terminal := TerminalScreen.new()
            terminal.minta_aplikasi.connect(_buka_aplikasi)
            return terminal
        "peta":
            return NetworkMap.new()
        "pasar":
            return PasarScreen.new()
        "misi":
            return PusatMisi.new()
        "email":
            return EmailApp.new()
        "perangkat":
            return DeviceManager.new()
        "toko":
            return TokoScreen.new()
        "dompet":
            return DompetScreen.new()
        "alat":
            return AlatScreen.new()
        "netmgr":
            return NetworkManager.new()
        "wireshark":
            return WiresharkApp.new()
        "inventaris":
            return InventarisApp.new()
        "tools":
            return ToolsRepository.new()
        _:
            return _konten_segera_hadir(DesktopView.nama_aplikasi(id))

func _konten_segera_hadir(nama: String) -> Control:
    var teks := Tema.label(Bahasa.t("desktop.segera") % nama, Tema.TEKS, 24)
    teks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return teks
