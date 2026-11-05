extends GutTest

# Uji penyimpanan permanen filesystem. Memakai folder user:// khusus tes, tidak menyentuh data pemain.

const DIR := "user://test_penyimpanan"
const BERKAS := "user://test_penyimpanan/fs.json"

func before_each():
    _bersihkan()

func after_each():
    _bersihkan()

func _bersihkan() -> void:
    DirAccess.make_dir_recursive_absolute(DIR)
    var dir := DirAccess.open(DIR)
    if dir == null:
        return
    for f in dir.get_files():
        dir.remove(f)

func _fixture() -> ShellSession:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    var data: Dictionary = JSON.parse_string(isi)
    return ShellSession.new(Vfs.new(data["/"]))

func _ada_berkas_berawalan(awalan: String) -> bool:
    var dir := DirAccess.open(DIR)
    for f in dir.get_files():
        if f.begins_with(awalan):
            return true
    return false

# --- Simpan dan muat ---

func test_muat_tanpa_berkas_berstatus_baru():
    assert_eq(Penyimpanan.muat(BERKAS)["status"], "baru")

func test_simpan_lalu_muat_mempertahankan_perubahan():
    var s := _fixture()
    s.jalankan("mkdir projects")
    s.jalankan("cd projects")
    s.jalankan("touch test.txt")
    s.jalankan("echo \"Hello JTN\" > test.txt")
    assert_true(Penyimpanan.simpan_sesi(s, BERKAS), "simpan berhasil")

    var m := Penyimpanan.muat(BERKAS)
    assert_eq(m["status"], "ok")
    var s2 := ShellSession.dari_dict(m["data"])
    assert_eq(s2.cwd, "/home/operator/projects", "direktori aktif tersimpan")
    assert_eq(ShellCommands.isi_berkas(s2.fs.ambil("/home/operator/projects/test.txt")), "Hello JTN", "isi berkas tersimpan")
    assert_true(s2.fs.ada("/home/operator/dokumen/jadwal.txt"), "struktur folder awal tetap ada")

func test_restart_simulasi_membaca_dari_penyimpanan_bukan_fs_awal():
    var s := _fixture()
    s.jalankan("cd dokumen")
    s.jalankan("echo \"catatan baru\" > catatan.txt")
    Penyimpanan.simpan_sesi(s, BERKAS)

    # Simulasi aplikasi dibuka kembali: sesi lama dibuang, lalu dimuat dari berkas.
    s = null
    var s2 := ShellSession.dari_dict(Penyimpanan.muat(BERKAS)["data"])
    assert_eq(s2.cwd, "/home/operator/dokumen", "direktori aktif setelah restart")
    assert_eq(ShellCommands.isi_berkas(s2.fs.ambil("/home/operator/dokumen/catatan.txt")), "catatan baru", "berkas setelah restart")

func test_riwayat_ikut_tersimpan():
    var s := _fixture()
    s.jalankan("pwd")
    s.jalankan("whoami")
    Penyimpanan.simpan_sesi(s, BERKAS)
    var s2 := ShellSession.dari_dict(Penyimpanan.muat(BERKAS)["data"])
    assert_eq(s2.riwayat.size(), 2, "riwayat dipulihkan")

func test_penulisan_atomik_tidak_meninggalkan_tmp():
    Penyimpanan.simpan_sesi(_fixture(), BERKAS)
    assert_false(FileAccess.file_exists(BERKAS + ".tmp"), "tidak ada berkas .tmp tersisa")
    assert_true(FileAccess.file_exists(BERKAS), "berkas utama ada")

func test_simpan_kedua_membuat_cadangan():
    var s := _fixture()
    Penyimpanan.simpan_sesi(s, BERKAS)
    s.jalankan("touch baru.txt")
    Penyimpanan.simpan_sesi(s, BERKAS)
    assert_true(FileAccess.file_exists(BERKAS + ".bak"), "cadangan dibuat")
    assert_eq(Penyimpanan.muat(BERKAS)["status"], "ok", "berkas utama tetap valid")

# --- Pemulihan saat rusak ---

func test_berkas_rusak_dipulihkan_dari_cadangan_dan_tidak_dihapus():
    var s := _fixture()
    s.jalankan("touch pertama.txt")
    Penyimpanan.simpan_sesi(s, BERKAS)
    s.jalankan("touch kedua.txt")
    Penyimpanan.simpan_sesi(s, BERKAS)

    var f := FileAccess.open(BERKAS, FileAccess.WRITE)
    f.store_string("{ ini bukan json")
    f.close()

    var m := Penyimpanan.muat(BERKAS)
    assert_eq(m["status"], "pulih_cadangan", "dipulihkan dari cadangan")
    assert_true(_ada_berkas_berawalan("fs.json.rusak-"), "berkas rusak disimpan, tidak dihapus")
    var s2 := ShellSession.dari_dict(m["data"])
    assert_true(s2.fs.ada("/home/operator/pertama.txt"), "isi cadangan benar")

func test_berkas_rusak_tanpa_cadangan_tidak_dihapus():
    var f := FileAccess.open(BERKAS, FileAccess.WRITE)
    f.store_string("rusak total")
    f.close()
    var m := Penyimpanan.muat(BERKAS)
    assert_eq(m["status"], "rusak", "tanda rusak tanpa cadangan")
    assert_true(_ada_berkas_berawalan("fs.json.rusak-"), "data rusak tetap ada untuk diperiksa")
    assert_false(FileAccess.file_exists(BERKAS), "berkas utama dipindahkan, bukan ditimpa diam-diam")

func test_versi_tidak_cocok_dianggap_rusak():
    var f := FileAccess.open(BERKAS, FileAccess.WRITE)
    f.store_string("{\"versi\": 99, \"fs\": {}}")
    f.close()
    assert_eq(Penyimpanan.muat(BERKAS)["status"], "rusak")
