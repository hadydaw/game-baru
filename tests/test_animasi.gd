extends GutTest

# Uji rencana animasi pemrosesan perintah. Setiap baris output harus sama dengan hasil asli, berurutan.

func _sesi() -> ShellSession:
    var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
    var data: Dictionary = JSON.parse_string(isi)
    return ShellSession.new(Vfs.new(data["/"]))

func _status(rencana: Array) -> Array:
    var hasil: Array = []
    for s in rencana:
        if String(s["tipe"]) == "status":
            hasil.append(String(s["teks"]))
    return hasil

func _baris(rencana: Array) -> Array:
    var hasil: Array = []
    for s in rencana:
        if String(s["tipe"]) == "baris":
            hasil.append(String(s["teks"]))
    return hasil

func _kirim(s: ShellSession, perintah: String) -> Array:
    return Animasi.rencana(perintah, s.jalankan(perintah))

func _teks_hasil(hasil: Array) -> Array:
    var t: Array = []
    for b in hasil:
        t.append(String(b["teks"]))
    return t

# --- Keaslian output ---

func test_baris_animasi_sama_dengan_hasil_asli_berurutan():
    var s := _sesi()
    var perintah := "ls -la"
    var hasil := s.jalankan(perintah)
    var rencana := Animasi.rencana(perintah, hasil)
    assert_eq(_baris(rencana), _teks_hasil(hasil), "setiap baris hasil tampil persis sekali dan berurutan")

func test_ls_dan_perintah_biasa_tidak_punya_status_berlebihan():
    var s := _sesi()
    var rencana := _kirim(s, "pwd")
    assert_eq(_status(rencana).size(), 1, "satu status pembuka untuk perintah biasa")

# --- nmap ---

func test_nmap_berhasil_lima_tahap_dan_selesai():
    var s := _sesi()
    s.jalankan("nmap gerbang") # menemukan tetangga, tidak mengubah tahap
    var rencana := _kirim(s, "nmap gerbang")
    assert_eq(_status(rencana), ["Initializing scanner...", "Host discovery...", "Port scanning...", "Service detection...", "Scan completed."], "tahap nmap lengkap")
    var bar: Array = []
    for x in rencana:
        if String(x["tipe"]) == "status":
            bar.append(int(x["bar"]))
    assert_eq(bar, [1, 3, 6, 8, 10], "bilah progres naik bertahap")

func test_nmap_gagal_tidak_sampai_selesai():
    var rencana := _kirim(_sesi(), "nmap arsip")
    assert_eq(_status(rencana).size(), 2, "node tidak dikenal berhenti di dua tahap awal")
    assert_false(_status(rencana).has("Scan completed."))

# --- ping ---

func test_ping_empat_paket_satu_status_per_paket():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    var rencana := _kirim(s, "ping gerbang")
    var paket := 0
    for t in _status(rencana):
        if t.begins_with("Mengirim paket"):
            paket += 1
    assert_eq(paket, 4, "empat paket, masing-masing punya status")
    assert_true(_status(rencana).has("Mengirim paket 4 dari 4"))

func test_ping_node_tidak_aktif_tampilkan_timeout_per_paket():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    s.jaringan.data["arsip"]["status"] = "tidak_aktif"
    var rencana := _kirim(s, "ping -c 3 arsip")
    assert_eq(_baris(rencana).filter(func(t): return t.begins_with("Request timeout")).size(), 3, "tiga timeout")
    assert_true(_baris(rencana).has("3 packets transmitted, 0 received, 100% packet loss"))

func test_ping_node_terkunci_galat_tanpa_status_paket():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    var rencana := _kirim(s, "ping relay")
    assert_false(_status(rencana).has("Mengirim paket 1 dari 0"), "tidak ada status paket palsu")
    assert_true(_baris(rencana).filter(func(t): return t.contains("Destination Host Unreachable")).size() == 1)

# --- ssh ---

func test_ssh_berhasil_lalu_membuka_sesi():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    var rencana := _kirim(s, "ssh operator@arsip")
    assert_eq(_status(rencana), ["Resolving hostname...", "Connecting to remote host...", "Establishing connection...", "Authenticating public key...", "Authentication successful.", "Membuka sesi terminal remote..."])
    assert_true(_baris(rencana).has("Terhubung ke arsip (10.7.0.8)."))

func test_ssh_ditolak_menampilkan_autentikasi_lalu_galat():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    var rencana := _kirim(s, "ssh admin@arsip")
    assert_eq(_status(rencana).size(), 4, "empat tahap sampai autentikasi")
    assert_false(_status(rencana).has("Authentication successful."), "tidak boleh sukses saat ditolak")
    assert_true(_baris(rencana).has("bash: ssh: Permission denied (publickey)."))

func test_ssh_node_tidak_dikenal_berhenti_di_resolusi():
    var rencana := _kirim(_sesi(), "ssh arsip")
    assert_eq(_status(rencana), ["Resolving hostname..."])

func test_ssh_node_terkunci_berhenti_di_koneksi():
    var s := _sesi()
    s.jalankan("nmap gerbang")
    var rencana := _kirim(s, "ssh operator@relay")
    assert_eq(_status(rencana).size(), 2, "resolusi lalu koneksi")

# --- perintah tidak dikenal, clear, exit ---

func test_perintah_tidak_dikenal_status_mencari():
    var rencana := _kirim(_sesi(), "xyz")
    assert_eq(_status(rencana), ["Mencari perintah..."])
    assert_eq(_baris(rencana), ["bash: xyz: perintah tidak ditemukan"])

func test_clear_langsung_membersihkan_tanpa_status():
    var rencana := Animasi.rencana("clear", [{"tipe": "clear", "teks": ""}])
    assert_eq(rencana.size(), 1)
    assert_eq(String(rencana[0]["tipe"]), "clear")

func test_perintah_tanpa_keluaran_tidak_dianimasikan():
    var s := _sesi()
    assert_eq(Animasi.rencana("touch a.txt", s.jalankan("touch a.txt")).size(), 0, "touch tidak mencetak apa pun")

func test_exit_lokal_galat_tanpa_animasi_ssh():
    var rencana := _kirim(_sesi(), "exit")
    assert_eq(_status(rencana), ["Menutup sesi SSH..."])
