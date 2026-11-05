extends GutTest

# Uji tombol Tab: melengkapi nama perintah dan nama berkas terhadap filesystem virtual.

func _sesi() -> ShellSession:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    var data: Dictionary = JSON.parse_string(isi)
    return ShellSession.new(Vfs.new(data["/"]))

func test_tab_nama_perintah_tunggal():
    assert_eq(ShellComplete.lengkapi(_sesi(), "ca")["teks"], "cat ")

func test_tab_nama_perintah_banyak_melengkapi_awalan_bersama():
    # cat, cd, clear: awalan bersama hanya "c", jadi teks tidak berubah dan daftar ditampilkan.
    var hasil := ShellComplete.lengkapi(_sesi(), "c")
    assert_eq(hasil["teks"], "c")
    assert_eq(hasil["pilihan"].size(), 3)

func test_tab_berkas_di_direktori_kerja():
    var s := _sesi()
    s.jalankan("cd dokumen")
    assert_eq(ShellComplete.lengkapi(s, "cat jad")["teks"], "cat jadwal.txt ")

func test_tab_direktori_menambah_garis_miring():
    assert_eq(ShellComplete.lengkapi(_sesi(), "cd dok")["teks"], "cd dokumen/")

func test_tab_jalur_bertingkat():
    assert_eq(ShellComplete.lengkapi(_sesi(), "cat dokumen/ja")["teks"], "cat dokumen/jadwal.txt ")

func test_tab_sembunyikan_titik_kecuali_diminta():
    assert_eq(ShellComplete.lengkapi(_sesi(), "cat .ca")["teks"], "cat .catatan ")
    assert_eq(ShellComplete.lengkapi(_sesi(), "ls ca")["teks"], "ls ca")

func test_tab_tanpa_kecocokan_tidak_berubah():
    assert_eq(ShellComplete.lengkapi(_sesi(), "cat zzz")["teks"], "cat zzz")

func test_tab_direktori_tidak_ada_tidak_berubah():
    assert_eq(ShellComplete.lengkapi(_sesi(), "cat tidakada/x")["teks"], "cat tidakada/x")
