extends GutTest

# Uji perintah ping, nmap, ssh, dan exit terhadap jaringan virtual dan filesystem nyata.

const DIR := "user://test_jaringan"
const BERKAS := "user://test_jaringan/fs.json"

func before_each():
    DirAccess.make_dir_recursive_absolute(DIR)
    var dir := DirAccess.open(DIR)
    for f in dir.get_files():
        dir.remove(f)

func _sesi() -> ShellSession:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    var data: Dictionary = JSON.parse_string(isi)
    return ShellSession.new(Vfs.new(data["/"]))

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

# --- ping ---

func test_ping_node_aktif_berhasil_dengan_latensi():
    var s := _sesi()
    var hasil := s.jalankan("ping gerbang")
    assert_false(_ada_galat(hasil))
    var teks := _teks(hasil)
    assert_true(teks.contains("64 bytes from 10.7.0.1"), "balasan dari IP node")
    assert_true(teks.contains("time=12 ms"), "latensi diambil dari data")
    assert_true(teks.contains("0% packet loss"))

func test_ping_jumlah_paket_dengan_opsi_c():
    var teks := _teks(_sesi().jalankan("ping -c 2 gerbang"))
    assert_eq(teks.count("icmp_seq="), 2, "dua paket terkirim")
    assert_true(teks.contains("2 packets transmitted, 2 received"))

func test_ping_jumlah_paket_di_luar_batas_galat():
    assert_true(_ada_galat(_sesi().jalankan("ping -c 0 gerbang")))
    assert_true(_ada_galat(_sesi().jalankan("ping -c 11 gerbang")))

func test_ping_node_tidak_dikenal():
    var hasil := _sesi().jalankan("ping arsip")
    assert_true(_ada_galat(hasil), "arsip belum ditemukan, harus galat")
    assert_true(_teks(hasil).contains("Nama atau layanan tidak diketahui"))

func test_ping_tanpa_argumen_galat():
    assert_true(_ada_galat(_sesi().jalankan("ping")))

func test_ping_node_terkunci_tidak_terjangkau():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    var hasil := s.jalankan("ping relay")
    assert_true(_ada_galat(hasil))
    assert_true(_teks(hasil).contains("Destination Host Unreachable"))

func test_ping_node_tidak_aktif_kehilangan_paket():
    var s := _sesi()
    s.jaringan.jelajahi("gerbang")
    s.jaringan.tandai_ditemukan("arsip")  # diketahui lewat scan, bukan tetangga
    s.jaringan.data["arsip"]["status"] = "tidak_aktif"
    var teks := _teks(s.jalankan("ping -c 3 arsip"))
    assert_eq(teks.count("Request timeout"), 3, "tiga timeout")
    assert_true(teks.contains("100% packet loss"))

func test_ping_menemukan_tetangga_biasa_bukan_node_scan():
    var s := _sesi()
    assert_false(s.jaringan.dikenal("arsip"))
    s.jalankan("ping gerbang")
    assert_true(s.jaringan.dikenal("relay"), "ping membuka tetangga biasa")
    assert_false(s.jaringan.dikenal("arsip"), "ping tidak membuka node khusus scan")

# --- nmap ---

func test_nmap_menampilkan_port_terbuka_dan_tertutup():
    var teks := _teks(_sesi().jalankan("nmap gerbang"))
    assert_true(teks.contains("22/tcp") and teks.contains("tertutup"), "port 22 tertutup")
    assert_true(teks.contains("80/tcp") and teks.contains("terbuka"), "port 80 terbuka")
    assert_true(teks.contains("http"), "nama layanan ditampilkan")

func test_nmap_filter_port():
    var teks := _teks(_sesi().jalankan("nmap -p 80 gerbang"))
    assert_true(teks.contains("80/tcp"))
    assert_false(teks.contains("22/tcp"), "port lain disembunyikan")

func test_nmap_menemukan_tetangga_biasa_bukan_node_scan():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    assert_true(s.jaringan.dikenal("relay"))
    assert_false(s.jaringan.dikenal("arsip"), "nmap tidak membuka node khusus scan")

func test_nmap_node_tidak_dikenal_galat():
    assert_true(_ada_galat(_sesi().jalankan("nmap arsip")))

func test_nmap_node_terkunci_galat():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    assert_true(_ada_galat(s.jalankan("nmap relay")))

func test_nmap_node_tidak_aktif_melaporkan_tidak_aktif():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.jaringan.data["arsip"]["status"] = "tidak_aktif"
    assert_true(_teks(s.jalankan("nmap arsip")).contains("tampaknya tidak aktif"))

# --- ssh ---

func test_ssh_berhasil_dengan_kunci_yang_benar():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    var hasil := s.jalankan("ssh operator@arsip")
    assert_false(_ada_galat(hasil), _teks(hasil))
    assert_true(_teks(hasil).contains("Terhubung ke arsip"))
    assert_true(s.prompt().begins_with("operator@arsip:"), "prompt menunjukkan node jarak jauh")

func test_ssh_di_dalam_sesi_jarak_jauh_perintah_berjalan_di_node():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.jalankan("ssh arsip")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator", "pwd di node")
    assert_true(_teks(s.jalankan("ls")).contains("catatan.txt"), "isi node, bukan isi lokal")
    assert_eq(_teks(s.jalankan("cat catatan.txt")), "Arsip Nusantara. Berkas dipindahkan ke server kota.")

func test_exit_keluar_dari_ssh_ke_terminal_lokal():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.jalankan("ssh arsip")
    var hasil := s.jalankan("exit")
    assert_false(_ada_galat(hasil))
    assert_eq(s.ssh_aktif, null, "sesi jarak jauh ditutup")
    assert_true(s.prompt().begins_with("operator@jtn:"), "kembali ke prompt lokal")
    assert_eq(_teks(s.jalankan("pwd")), "/home/operator", "pwd lokal lagi")

func test_ssh_ditolak_user_salah():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    var hasil := s.jalankan("ssh admin@arsip")
    assert_true(_ada_galat(hasil))
    assert_true(_teks(hasil).contains("Permission denied"))
    assert_eq(s.ssh_aktif, null)

func test_ssh_ditolak_tanpa_kunci():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.fs.ambil("/home/operator/dokumen")["isi"].erase("kunci_arsip.txt")
    var hasil := s.jalankan("ssh operator@arsip")
    assert_true(_teks(hasil).contains("Permission denied"), "kunci hilang berarti ditolak")

func test_ssh_ditolak_kunci_salah():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.fs.ambil("/home/operator/dokumen/kunci_arsip.txt")["isi"] = "salah"
    assert_true(_teks(s.jalankan("ssh operator@arsip")).contains("Permission denied"))

func test_ssh_node_terkunci_timeout():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    assert_true(_teks(s.jalankan("ssh operator@relay")).contains("Connection timed out"))

func test_ssh_node_tidak_dikenal():
    assert_true(_teks(_sesi().jalankan("ssh arsip")).contains("Could not resolve hostname"))

func test_ssh_port_22_tertutup_ditolak():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    assert_true(_teks(s.jalankan("ssh operator@gerbang")).contains("Connection refused"), "gerbang tidak punya ssh")

func test_ssh_di_dalam_sesi_jarak_jauh_ditolak():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.jalankan("ssh arsip")
    var hasil := s.ssh_aktif.jalankan("ssh gerbang")
    assert_true(_ada_galat(hasil), "tidak boleh bersarang")

func test_exit_tanpa_ssh_galat():
    assert_true(_ada_galat(_sesi().jalankan("exit")))

# --- Isolasi dan persistensi ---

func test_perubahan_di_node_tidak_mengubah_filesystem_lokal():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.jalankan("ssh arsip")
    s.jalankan("touch dari_node.txt")
    s.jalankan("exit")
    assert_false(s.fs.ada("/home/operator/dari_node.txt"), "file node tidak muncul di lokal")
    assert_true(s.jaringan.fs_node["arsip"]["isi"]["home"]["isi"]["operator"]["isi"].has("dari_node.txt"), "file tersimpan di node")

func test_status_jaringan_tersimpan_dan_dipulihkan():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jalankan("scan 10.7.0.8")
    s.jaringan.buka("misi_relay")
    s.jalankan("ssh arsip")
    s.jalankan("touch hasil.txt")  # dijalankan di node, bukan di lokal
    s.jalankan("exit")
    assert_true(Penyimpanan.simpan_sesi(s, BERKAS))
    var s2 := ShellSession.dari_dict(Penyimpanan.muat(BERKAS)["data"])
    assert_true(s2.jaringan.dikenal("arsip"), "penemuan tersimpan")
    assert_false(s2.jaringan.terkunci("relay"), "progres tersimpan")
    assert_true(s2.jaringan.fs_node["arsip"]["isi"]["home"]["isi"]["operator"]["isi"].has("hasil.txt"), "perubahan node tersimpan")
    assert_eq(_teks(s2.jalankan("ping -c 1 arsip")).contains("64 bytes"), true, "node tetap bisa dijangkau setelah dimuat")
