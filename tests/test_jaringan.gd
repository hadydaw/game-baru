extends GutTest

# Uji model jaringan virtual: penemuan, kunci/buka node, dan sinkronisasi data untuk Peta Jaringan.

func test_gerbang_ditemukan_sejak_awal_dan_arsip_belum():
    var j := Jaringan.muat()
    assert_true(j.dikenal("gerbang"), "gerbang ditemukan sejak awal")
    assert_false(j.dikenal("arsip"), "arsip belum ditemukan")

func test_cari_berdasarkan_nama_dan_ip():
    var j := Jaringan.muat()
    assert_eq(j.cari("arsip"), "arsip")
    assert_eq(j.cari("10.7.0.8"), "arsip", "pencarian lewat IP")
    assert_eq(j.cari("tidakada"), "", "node tidak dikenal")

func test_node_terkunci_sampai_flag_dibuka():
    var j := Jaringan.muat()
    assert_true(j.terkunci("relay"), "relay terkunci di awal")
    j.buka("misi_relay")
    assert_false(j.terkunci("relay"), "relay terbuka setelah flag misi_relay")

func test_jelajahi_menampilkan_tetangga_biasa_tanpa_node_scan():
    var j := Jaringan.muat()
    j.jelajahi("gerbang")
    assert_true(j.dikenal("relay"), "tetangga biasa terlihat meski terkunci")
    assert_false(j.dikenal("arsip"), "node bertanda scan tidak terbuka lewat tetangga")
    assert_false(j.dikenal("server_kota"), "node yang bukan tetangga belum terlihat")

func test_node_scan_terbuka_hanya_lewat_tandai_ditemukan():
    var j := Jaringan.muat()
    assert_true(j.butuh_scan("arsip"))
    assert_false(j.butuh_scan("relay"))
    j.jelajahi("gerbang")
    assert_false(j.dikenal("arsip"))
    j.tandai_ditemukan("arsip")
    assert_true(j.dikenal("arsip"), "setelah scan node terbuka")

func test_bukan_dua_kali_tidak_menduplikasi_penemuan():
    var j := Jaringan.muat()
    j.tandai_ditemukan("arsip")
    j.jelajahi("gerbang")
    j.jelajahi("gerbang")
    var jumlah := 0
    for id in j.ditemukan:
        if id == "arsip":
            jumlah += 1
    assert_eq(jumlah, 1)

# --- Sinkronisasi dengan Peta Jaringan ---

func test_peta_membaca_status_yang_sama_dengan_terminal():
    var j := Jaringan.muat()
    j.jelajahi("gerbang")
    j.tandai_ditemukan("arsip")
    var peta := j.daftar_terlihat()
    var ids: Array = []
    for n in peta:
        ids.append(String(n["id"]))
    assert_true(ids.has("arsip") and ids.has("relay") and ids.has("gerbang"), "peta memuat node yang ditemukan")
    assert_false(ids.has("server_kota"), "peta tidak memuat node yang belum ditemukan")

func test_peta_menandai_node_terkunci():
    var j := Jaringan.muat()
    j.jelajahi("gerbang")
    j.tandai_ditemukan("arsip")
    for n in j.daftar_terlihat():
        if n["id"] == "relay":
            assert_true(bool(n["terkunci"]), "relay tampil terkunci di peta")
        if n["id"] == "arsip":
            assert_false(bool(n["terkunci"]), "arsip tampil terbuka di peta")

# --- Simpan dan pulihkan ---

func test_keadaan_jaringan_dipulihkan_dari_dict():
    var j := Jaringan.muat()
    j.jelajahi("gerbang")
    j.buka("misi_relay")
    j.tandai_ditemukan("arsip")
    j.fs_node["arsip"]["isi"]["home"]["isi"]["operator"]["isi"]["baru.txt"] = {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "x", "ukuran": 1}
    var salinan := j.to_dict()
    var k := Jaringan.muat()
    k.terapkan(salinan)
    assert_true(k.dikenal("arsip"), "penemuan dipulihkan")
    assert_false(k.terkunci("relay"), "progres dipulihkan")
    assert_true(k.fs_node["arsip"]["isi"]["home"]["isi"]["operator"]["isi"].has("baru.txt"), "perubahan filesystem node dipulihkan")
