extends GutTest

# Unit test tahap 1. Butuh addon GUT di addons/gut (belum dipasang).

func _sesi() -> ShellSession:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    # File JSON membungkus root di bawah kunci "/", sama seperti yang dibaca TerminalScreen.
    var data: Dictionary = JSON.parse_string(isi)
    return ShellSession.new(Vfs.new(data["/"]))

func test_tokenisasi_kutip() -> void:
    var t := ShellParser.tokenkan("echo \"halo dunia\" 'a b'")
    assert_eq(t, ["echo", "halo dunia", "a b"])

func test_opsi_gabungan() -> void:
    var p := ShellParser.parse("ls -la /tmp")
    assert_true(ShellParser.punya_huruf(p["opsi"], "a"))
    assert_true(ShellParser.punya_huruf(p["opsi"], "l"))

func test_normalisasi_cd_dotdot_dari_akar() -> void:
    assert_eq(Vfs.normalisasi("/", ".."), "/")
    assert_eq(Vfs.normalisasi("/home/operator/dokumen", ".."), "/home/operator")

func test_cd_dotdot_berfungsi() -> void:
    var s := _sesi()
    s.jalankan("cd dokumen")
    s.jalankan("cd ..")
    assert_eq(s.cwd, "/home/operator")

func test_ls_sembunyikan_titik() -> void:
    var s := _sesi()
    var baris := s.jalankan("ls")
    for b in baris:
        assert_false(Bahasa.pilih(String(b["teks"])).begins_with("."))

func test_ls_a_tampilkan_titik() -> void:
    var s := _sesi()
    var teks := ""
    for b in s.jalankan("ls -a"):
        teks += Bahasa.pilih(String(b["teks"])) + "\n"
    assert_true(teks.contains(".catatan"))

func test_cat_ditolak_tanpa_izin() -> void:
    var s := _sesi()
    var hasil := s.jalankan("cat /etc/rahasia")
    assert_eq(String(hasil[0]["tipe"]), "error")
    assert_true(String(hasil[0]["teks"]).contains("Izin ditolak"))

func test_mkdir_hanya_di_home() -> void:
    var s := _sesi()
    var hasil := s.jalankan("mkdir /var/coba")
    assert_eq(String(hasil[0]["tipe"]), "error")

func test_mkdir_p_di_home() -> void:
    var s := _sesi()
    s.jalankan("mkdir -p ~/arsip/2026")
    assert_true(s.fs.ada("/home/operator/arsip/2026"))

func test_grep_cari_baris() -> void:
    var s := _sesi()
    var hasil := s.jalankan("grep Senin dokumen/jadwal.txt")
    assert_eq(hasil.size(), 1)
    assert_true(String(hasil[0]["teks"]).contains("Senin"))

func test_perintah_tidak_ditemukan() -> void:
    var s := _sesi()
    var hasil := s.jalankan("xyz")
    assert_true(String(hasil[0]["teks"]).begins_with("bash: xyz:"))
