extends GutTest

# Skenario pengujian berurutan terhadap filesystem virtual nyata (data/fs/pemain.json).
# Setiap langkah memeriksa state VFS, bukan hanya teks output.

func _sesi() -> ShellSession:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    var data: Dictionary = JSON.parse_string(isi)
    return ShellSession.new(Vfs.new(data["/"]))

func _teks(hasil: Array) -> String:
    var baris: Array = []
    for b in hasil:
        baris.append(Bahasa.pilih(String(b["teks"])))
    return "\n".join(PackedStringArray(baris))

func _ada_galat(hasil: Array) -> bool:
    for b in hasil:
        if String(b["tipe"]) == "error":
            return true
    return false

# --- 1. Filesystem ---

func test_skenario_filesystem_berurutan():
    var s := _sesi()
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator", "pwd awal")
    assert_eq(_teks(s.jalankan("whoami")), "operator", "whoami")
    var la := _teks(s.jalankan("ls -la"))
    assert_true(la.contains(".catatan") and la.contains("dokumen"), "ls -la menampilkan berkas tersembunyi")
    assert_false(_ada_galat(s.jalankan("mkdir projects")), "mkdir projects")
    assert_true(s.fs.ada("/home/operator/projects"), "projects dibuat di VFS")
    assert_false(_ada_galat(s.jalankan("cd projects")), "cd projects")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator/projects", "pwd setelah cd projects")
    assert_false(_ada_galat(s.jalankan("touch test.txt")), "touch test.txt")
    assert_true(s.fs.ada("/home/operator/projects/test.txt"), "test.txt dibuat di VFS")
    assert_true(_teks(s.jalankan("ls -la")).contains("test.txt"), "ls -la memuat test.txt")
    s.jalankan("echo \"Hello JTN\" > test.txt")
    assert_eq(String(s.fs.ambil("/home/operator/projects/test.txt")["isi"]), "Hello JTN", "echo > menulis ke VFS")
    assert_eq(_teks(s.jalankan("cat test.txt")), "Hello JTN", "cat membaca isi yang ditulis")
    s.jalankan("cd ..")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator", "cd .. kembali ke home")

# --- 2. Navigasi ---

func test_skenario_navigasi():
    var s := _sesi()
    s.jalankan("cd dokumen")
    s.jalankan("cd ..")
    assert_eq(s.cwd, "/home/operator", "cd .. dari dokumen")
    s.jalankan("cd /")
    assert_eq(s.cwd, "/", "cd / menuju root")
    s.jalankan("cd ~")
    assert_eq(s.cwd, "/home/operator", "cd ~ menuju home")
    s.jalankan("cd /")
    s.jalankan("cd /home/operator")
    assert_eq(s.cwd, "/home/operator", "cd /home/operator")
    assert_true(_ada_galat(s.jalankan("cd tidakada")), "cd direktori tidak ada harus galat")
    assert_true(_ada_galat(s.jalankan("cd /tidak/ada")), "cd jalur absolut tidak ada harus galat")
    assert_eq(s.cwd, "/home/operator", "cwd tidak berubah setelah galat")

# --- 3. Fitur terminal ---

func test_skenario_history_dan_riwayat():
    var s := _sesi()
    s.jalankan("pwd")
    s.jalankan("whoami")
    s.jalankan("ls")
    var h := _teks(s.jalankan("history"))
    assert_true(h.contains("pwd") and h.contains("whoami") and h.contains("ls"), "history memuat semua perintah")
    assert_eq(s.riwayat.size(), 4, "riwayat mencatat 4 perintah termasuk history itu sendiri")

func test_skenario_grep_dan_find():
    var s := _sesi()
    assert_true(_teks(s.jalankan("grep Senin dokumen/jadwal.txt")).begins_with("Senin"), "grep menemukan baris")
    var f := _teks(s.jalankan("find . -name \"*.txt\""))
    assert_true(f.contains("/home/operator/dokumen/jadwal.txt"), "find menemukan berkas")
    var d := _teks(s.jalankan("find . -type d"))
    assert_true(d.contains("/home/operator/dokumen"), "find -type d menemukan direktori")

func test_skenario_man():
    var s := _sesi()
    assert_true(_teks(s.jalankan("man ls")).contains("ls [-a] [-l] [path]"), "man ls")
    assert_true(_ada_galat(s.jalankan("man tidakada")), "man perintah tidak ada harus galat")

func test_skenario_clear_tidak_mengubah_riwayat():
    var s := _sesi()
    s.jalankan("pwd")
    var hasil := s.jalankan("clear")
    assert_eq(String(hasil[0]["tipe"]), "clear", "clear mengirim sinyal bersihkan layar")
    assert_eq(s.riwayat.size(), 2, "clear tetap masuk riwayat")

# --- 4. Standar: error tidak tertukar dengan info ---

func test_error_bertipe_error_dan_output_bertipe_info():
    var s := _sesi()
    for b in s.jalankan("ls"):
        assert_eq(String(b["tipe"]), "info", "output ls bertipe info")
    for b in s.jalankan("xyz"):
        assert_eq(String(b["tipe"]), "error", "perintah tidak dikenal bertipe error")

# --- 5. Redirect ---

func test_redirect_tambah_dengan_dobel_panah():
    var s := _sesi()
    s.jalankan("echo satu > catatan.txt")
    s.jalankan("echo dua >> catatan.txt")
    assert_eq(String(s.fs.ambil("/home/operator/catatan.txt")["isi"]), "satu\ndua", ">> menambah di akhir berkas")

func test_redirect_menimpa_berkas_lama():
    var s := _sesi()
    s.jalankan("echo satu > a.txt")
    s.jalankan("echo dua > a.txt")
    assert_eq(String(s.fs.ambil("/home/operator/a.txt")["isi"]), "dua", "> menimpa isi lama")

func test_redirect_ke_direktori_galat():
    var hasil := _sesi().jalankan("echo x > dokumen")
    assert_true(_ada_galat(hasil), "menulis ke direktori harus galat")

func test_redirect_tanpa_izin_ditolak():
    var s := _sesi()
    s.jalankan("cd /")
    var sebelum := ShellCommands.isi_berkas(s.fs.ambil("/etc/rahasia"))
    var hasil := s.jalankan("echo x > etc/rahasia")
    assert_true(_teks(hasil).contains("Izin ditolak"), "tulis ke berkas root harus ditolak")
    assert_eq(ShellCommands.isi_berkas(s.fs.ambil("/etc/rahasia")), sebelum, "isi berkas root tidak berubah")

func test_redirect_tanpa_tujuan_galat():
    assert_true(_ada_galat(_sesi().jalankan("echo x >")), "> tanpa tujuan harus galat")

func test_redirect_riwayat_tetap_tercatat():
    var s := _sesi()
    s.jalankan("echo x > b.txt")
    assert_eq(s.riwayat.size(), 1, "perintah ber-redirect tetap masuk riwayat")
