extends GutTest

# Uji kombinasi Ctrl + huruf dan deteksi karakter yang disisipkan.

func test_aksi_ctrl_c_batalkan():
    assert_eq(ShellControl.aksi("c"), "batal")
    assert_eq(ShellControl.aksi("C"), "batal", "huruf besar juga diterima")

func test_aksi_ctrl_l_bersihkan():
    assert_eq(ShellControl.aksi("l"), "bersihkan")

func test_aksi_ctrl_u_hapus_baris():
    assert_eq(ShellControl.aksi("u"), "hapus_baris")

func test_aksi_kombinasi_lain_tidak_melakukan_apa_apa():
    assert_eq(ShellControl.aksi("x"), "")
    assert_eq(ShellControl.aksi("/"), "")

func test_sisipan_di_tengah():
    var h := ShellControl.sisipan("abc", "abXc")
    assert_eq(h["huruf"], "X")
    assert_eq(h["teks"], "abc")

func test_sisipan_di_awal_dan_akhir():
    assert_eq(ShellControl.sisipan("", "c")["huruf"], "c")
    assert_eq(ShellControl.sisipan("ab", "abc")["huruf"], "c")
    assert_eq(ShellControl.sisipan("ab", "abc")["teks"], "ab")

func test_bukan_sisipan_satu_karakter():
    var h := ShellControl.sisipan("ab", "ab")
    assert_eq(h["huruf"], "")
    assert_eq(h["teks"], "ab")
