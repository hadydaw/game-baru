extends GutTest

# Uji perintah terminal terhadap filesystem virtual nyata (state diubah dan dibaca ulang).
# Tidak menyentuh sistem operasi. Fixture dibangun di kode agar hasilnya pasti.

func _dir(isi: Dictionary = {}, izin: String = "rwxr-x---", pemilik: String = "operator") -> Dictionary:
    return {"tipe": "dir", "pemilik": pemilik, "grup": pemilik, "izin": izin, "isi": isi}

func _berkas(teks: String, izin: String = "rw-r-----", pemilik: String = "operator") -> Dictionary:
    return {"tipe": "file", "pemilik": pemilik, "grup": pemilik, "izin": izin, "isi": teks, "ukuran": teks.length()}

func _sesi() -> ShellSession:
    var rumah := _dir({
        "Desktop": _dir(),
        "Documents": _dir({"jadwal.txt": _berkas("Senin: briefing\nRabu: uji node")}),
        "Downloads": _dir(),
        ".catatan": _berkas("catatan pribadi"),
    })
    var root := {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
        "home": _dir({"operator": rumah}, "rwxr-xr-x", "root"),
        "etc": _dir({"rahasia": _berkas("kunci", "rw-------", "root")}, "rwxr-xr-x", "root"),
    }}
    return ShellSession.new(Vfs.new(root))

func _teks(hasil: Array) -> String:
    var baris: Array = []
    for b in hasil:
        baris.append(String(b["teks"]))
    return "\n".join(PackedStringArray(baris))

func _ada_galat(hasil: Array) -> bool:
    for b in hasil:
        if String(b["tipe"]) == "error":
            return true
    return false

# --- Parser ---

func test_parser_kutip_ganda_menjadi_satu_argumen():
    assert_eq(ShellParser.tokenkan("echo \"Hello JTN\""), ["echo", "Hello JTN"])

func test_parser_kutip_tunggal():
    assert_eq(ShellParser.tokenkan("echo 'a b' c"), ["echo", "a b", "c"])

func test_parser_pisahkan_nama_opsi_argumen():
    var p := ShellParser.parse("ls -la /tmp")
    assert_eq(p["nama"], "ls")
    assert_eq(p["opsi"], ["-la"])
    assert_eq(p["argumen"], ["/tmp"])

func test_parser_baris_kosong():
    assert_true(bool(ShellParser.parse("   ")["kosong"]))

# --- Perintah dasar ---

func test_pwd_awal_di_home():
    assert_eq(_teks(_sesi().jalankan("pwd")), "/home/operator")

func test_whoami():
    assert_eq(_teks(_sesi().jalankan("whoami")), "operator")

func test_echo_dengan_kutip_ganda():
    assert_eq(_teks(_sesi().jalankan("echo \"Hello JTN\"")), "Hello JTN")

func test_echo_tanpa_kutip():
    assert_eq(_teks(_sesi().jalankan("echo a b")), "a b")

func test_perintah_tidak_dikenal():
    var hasil := _sesi().jalankan("xyz")
    assert_true(_ada_galat(hasil))
    assert_eq(_teks(hasil), "bash: xyz: perintah tidak ditemukan")

func test_clear_mengirim_tipe_clear():
    var hasil := _sesi().jalankan("clear")
    assert_eq(String(hasil[0]["tipe"]), "clear")

func test_help_menampilkan_daftar():
    assert_true(_teks(_sesi().jalankan("help")).contains("ls"))

# --- ls ---

func test_ls_default_satu_baris_tanpa_berkas_tersembunyi():
    assert_eq(_teks(_sesi().jalankan("ls")), "Desktop  Documents  Downloads")

func test_ls_la_menampilkan_berkas_tersembunyi():
    var teks := _teks(_sesi().jalankan("ls -la"))
    assert_true(teks.contains(".catatan"))
    assert_true(teks.contains("Desktop"))

func test_ls_path_ke_direktori_lain():
    assert_eq(_teks(_sesi().jalankan("ls Documents")), "jadwal.txt")

func test_ls_path_ke_berkas():
    assert_true(_teks(_sesi().jalankan("ls Documents/jadwal.txt")).contains("jadwal.txt"))

func test_ls_path_tidak_ada_galat():
    assert_true(_ada_galat(_sesi().jalankan("ls tidakada")))

# --- cd dan pwd ---

func test_cd_titik_dua_naik_satu_tingkat():
    var s := _sesi()
    assert_false(_ada_galat(s.jalankan("cd ..")))
    assert_eq(_teks(s.jalankan("pwd")), "/home")

func test_cd_garis_miring_ke_root():
    var s := _sesi()
    s.jalankan("cd /")
    assert_eq(_teks(s.jalankan("pwd")), "/")

func test_cd_tilde_ke_home():
    var s := _sesi()
    s.jalankan("cd /")
    s.jalankan("cd ~")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator")

func test_cd_tanpa_argumen_ke_home():
    var s := _sesi()
    s.jalankan("cd /")
    s.jalankan("cd")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator")

func test_cd_ke_subdirektori_lalu_pwd():
    var s := _sesi()
    s.jalankan("cd Documents")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator/Documents")

func test_cd_ke_direktori_tidak_ada():
    var hasil := _sesi().jalankan("cd tidakada")
    assert_true(_teks(hasil).begins_with("bash: cd: tidakada:"))

func test_cd_ke_berkas_ditolak():
    assert_true(_teks(_sesi().jalankan("cd Documents/jadwal.txt")).contains("Bukan direktori"))

func test_cd_ke_direktori_tanpa_izin_ditolak():
    var s := _sesi()
    s.jalankan("cd /")
    s.jalankan("cd etc")
    assert_true(_ada_galat(s.jalankan("cat rahasia")))

# --- mkdir dan touch ---

func test_mkdir_membuat_direktori_yang_terlihat_di_ls():
    var s := _sesi()
    assert_false(_ada_galat(s.jalankan("mkdir test")))
    assert_true(_teks(s.jalankan("ls")).contains("test"))

func test_mkdir_duplikat_galat():
    assert_true(_teks(_sesi().jalankan("mkdir Desktop")).contains("Berkas sudah ada"))

func test_mkdir_p_membuat_induk_sekaligus():
    var s := _sesi()
    assert_false(_ada_galat(s.jalankan("mkdir -p a/b/c")))
    s.jalankan("cd a/b/c")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator/a/b/c")

func test_mkdir_di_luar_home_ditolak():
    var s := _sesi()
    s.jalankan("cd /")
    assert_true(_teks(s.jalankan("mkdir x")).contains("hanya bisa membuat"))

func test_touch_membuat_berkas_kosong():
    var s := _sesi()
    assert_false(_ada_galat(s.jalankan("touch file.txt")))
    assert_true(_teks(s.jalankan("ls")).contains("file.txt"))
    assert_eq(s.jalankan("cat file.txt").size(), 0)

# --- cat ---

func test_cat_membaca_isi_berkas():
    var s := _sesi()
    s.jalankan("cd Documents")
    assert_eq(_teks(s.jalankan("cat jadwal.txt")), "Senin: briefing\nRabu: uji node")

func test_cat_tanpa_argumen_galat():
    assert_true(_teks(_sesi().jalankan("cat")).contains("argumen diperlukan"))

func test_cat_direktori_galat():
    assert_true(_teks(_sesi().jalankan("cat Documents")).contains("Itu adalah direktori"))

func test_cat_berkas_tanpa_izin_ditolak():
    var s := _sesi()
    s.jalankan("cd /")
    s.jalankan("cd etc")
    assert_true(_teks(s.jalankan("cat rahasia")).contains("Izin ditolak"))

# --- history ---

func test_history_mencatat_perintah():
    var s := _sesi()
    s.jalankan("pwd")
    s.jalankan("whoami")
    var teks := _teks(s.jalankan("history"))
    assert_true(teks.contains("pwd"))
    assert_true(teks.contains("whoami"))

func test_riwayat_tidak_mencatat_baris_kosong():
    var s := _sesi()
    s.jalankan("pwd")
    s.jalankan("   ")
    assert_eq(s.riwayat.size(), 1)

# --- man ---

func test_man_ls():
    assert_true(_teks(_sesi().jalankan("man ls")).contains("ls [-a] [-l] [path]"))

func test_man_perintah_tidak_ada_galat():
    assert_true(_ada_galat(_sesi().jalankan("man xyz")))

# --- grep dan find ---

func test_grep_menemukan_baris_cocok():
    var s := _sesi()
    s.jalankan("cd Documents")
    assert_eq(_teks(s.jalankan("grep Rabu jadwal.txt")), "Rabu: uji node")

func test_grep_tanpa_kecocokan_kosong():
    var s := _sesi()
    s.jalankan("cd Documents")
    assert_eq(s.jalankan("grep Jumat jadwal.txt").size(), 0)

func test_grep_tanpa_argumen_galat():
    assert_true(_ada_galat(_sesi().jalankan("grep")))

func test_find_berdasarkan_nama():
    assert_eq(_teks(_sesi().jalankan("find Documents -name \"*.txt\"")), "/home/operator/Documents/jadwal.txt")

func test_find_tipe_direktori():
    assert_true(_teks(_sesi().jalankan("find . -type d")).contains("/home/operator/Desktop"))
