class_name PerintahJaringan
extends RefCounted

# Perintah ping, nmap, dan ssh di atas jaringan virtual. Semua output berasal dari data Jaringan.

static func ping(s: ShellSession, p: Dictionary) -> Array:
    var args: Array = p["argumen"].duplicate()
    var jumlah := 4
    if ShellParser.punya_huruf(p["opsi"], "c"):
        if args.size() < 2:
            return [s.galat("ping", Teks.t("err.butuh_argumen"))]
        jumlah = int(String(args[0]))
        args.remove_at(0)
        if jumlah < 1 or jumlah > 10:
            return [s.galat("ping", Bahasa.dua("jumlah paket harus antara 1 dan 10", "packet count must be between 1 and 10"))]
    if args.is_empty():
        return [s.galat("ping", Teks.t("err.butuh_argumen"))]
    var target := String(args[0])
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("ping", Bahasa.dua("%s: Nama atau layanan tidak diketahui", "%s: Name or service not known", [target]))]
    if j.terkunci(id):
        return [s.galat("ping", "%s: Destination Host Unreachable" % target)]
    var ip := j.ip(id)
    var hasil: Array = [s.baris("info", "PING %s (%s): 56 data bytes" % [target, ip])]
    var diterima := 0
    if j.aktif(id):
        var latensi := int(j.data[id].get("latensi", 0))
        for n in range(1, jumlah + 1):
            hasil.append(s.baris("info", "64 bytes from %s: icmp_seq=%d ttl=64 time=%d ms" % [ip, n, latensi]))
        diterima = jumlah
        j.jelajahi(id)
    else:
        for n in range(1, jumlah + 1):
            hasil.append(s.baris("info", "Request timeout for icmp_seq %d" % n))
    var persen := int(round(100.0 * (jumlah - diterima) / jumlah))
    hasil.append(s.baris("info", "--- %s ping statistics ---" % target))
    hasil.append(s.baris("info", "%d packets transmitted, %d received, %d%% packet loss" % [jumlah, diterima, persen]))
    return hasil

static func nmap(s: ShellSession, p: Dictionary) -> Array:
    # Mode subnet: -sn memeriksa host yang aktif pada /24 tanpa memindai port. -oN menulis hasilnya ke berkas.
    if ShellParser.punya_opsi(p["opsi"], "-sn"):
        return _nmap_sn(s, p)
    # -sV (versi layanan) dan deteksi firewall hanya tersedia dengan Network Scanner tingkat tertentu.
    var sv := ShellParser.punya_huruf(p["opsi"], "V")
    if sv and s.inventory.tingkat("network_scanner") < 2:
        return [s.galat("nmap", Teks.t("err.opsi"))]
    var tampil_firewall := s.inventory.tingkat("network_scanner") >= 3
    var args: Array = p["argumen"].duplicate()
    var filter: Array = []
    if ShellParser.punya_huruf(p["opsi"], "p"):
        if args.size() < 2:
            return [s.galat("nmap", Teks.t("err.butuh_argumen"))]
        filter = Array(String(args[0]).split(",", false))
        args.remove_at(0)
    if args.is_empty():
        return [s.galat("nmap", Teks.t("err.butuh_argumen"))]
    var target := String(args[0])
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("nmap", Bahasa.dua("%s: Nama atau layanan tidak diketahui", "%s: Name or service not known", [target]))]
    if j.terkunci(id):
        return [s.galat("nmap", Bahasa.dua("%s: Host tidak dapat dijangkau", "%s: Host unreachable", [target]))]
    var ip := j.ip(id)
    var hasil: Array = [s.baris("info", Bahasa.dua("Memindai %s (%s)...", "Scanning %s (%s)...", [target, ip]))]
    if not j.aktif(id):
        hasil.append(s.baris("info", Bahasa.dua("Host tampaknya tidak aktif (tidak ada respons).", "Host appears to be down (no response).")))
        return hasil
    hasil.append(s.baris("info", "PORT       STATE    SERVICE" + ("      VERSI" if sv else "")))
    if tampil_firewall:
        hasil.append(s.baris("info", Bahasa.dua("Firewall: tingkat %d", "Firewall: level %d", [int(j.data[id].get("firewall", 0))])))
    var port_dict: Dictionary = j.data[id].get("port", {})
    var nomor_list := port_dict.keys()
    nomor_list.sort()
    var tampil := 0
    for nomor in nomor_list:
        var n := String(nomor)
        if not filter.is_empty() and not filter.has(n):
            continue
        var pd: Dictionary = port_dict[nomor]
        var baris_port := "%-10s %-8s %s" % ["%s/tcp" % n, String(pd.get("status", "")), String(pd.get("layanan", ""))]
        if sv:
            baris_port = "%-10s %-8s %-10s %s" % ["%s/tcp" % n, String(pd.get("status", "")), String(pd.get("layanan", "")), String(pd.get("versi", "-"))]
        hasil.append(s.baris("info", baris_port))
        tampil += 1
    j.jelajahi(id)
    j.tandai_dipindai(id)
    hasil.append(s.baris("info", Bahasa.dua("Pemindaian selesai: 1 host, %d port ditampilkan.", "Scan complete: 1 host, %d ports shown.", [tampil])))
    # Pemindaian port terarah pada host laboratorium menjadi bukti tahap misi (Tutorial 2).
    if not filter.is_empty():
        j.buka("nmap:port:" + id)
    return hasil

static func ssh(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("ssh", Teks.t("err.butuh_argumen"))]
    if s.host != ShellSession.LOKAL:
        return [s.galat("ssh", Bahasa.dua("sudah berada di sesi jarak jauh. Ketik exit untuk keluar.", "already in a remote session. Type exit to leave."))]
    var target := String(p["argumen"][0])
    var user := s.user
    if target.contains("@"):
        var bagian := target.split("@")
        user = bagian[0]
        target = bagian[1]
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("ssh", Bahasa.dua("Could not resolve hostname %s: Nama atau layanan tidak diketahui", "Could not resolve hostname %s: Name or service not known", [target]))]
    if j.terkunci(id):
        return [s.galat("ssh", "connect to host %s port 22: Connection timed out" % target)]
    if not j.aktif(id):
        return [s.galat("ssh", "connect to host %s port 22: No route to host" % target)]
    var cfg: Dictionary = j.data[id].get("ssh", {})
    var port22: Dictionary = j.data[id].get("port", {}).get("22", {})
    if cfg.is_empty() or String(port22.get("status", "")) != "terbuka":
        return [s.galat("ssh", "connect to host %s port 22: Connection refused" % target)]
    if user != String(cfg.get("user", "")) or not _kunci_cocok(s, cfg):
        return [s.galat("ssh", "Permission denied (publickey).")]
    var jauh := ShellSession.new(Vfs.new({}), j)
    jauh.host = id
    # Saldo dan reputasi milik pemain, bukan milik node, jadi sesi jarak jauh memakai objek yang sama.
    jauh.economy = s.economy
    jauh.reputation = s.reputation
    jauh.inventory = s.inventory
    jauh.market = s.market
    jauh.cwd = jauh.home
    jauh.fs.akar = j.fs_node[id]
    s.ssh_aktif = jauh
    # Tanda bahwa login ke node ini berhasil; dipakai tujuan misi.
    s.jaringan.buka("ssh:" + id)
    return [s.baris("info", Bahasa.dua("Terhubung ke %s (%s).", "Connected to %s (%s).", [id, j.ip(id)]))]

# Kunci SSH adalah berkas di filesystem lokal yang isinya memuat token node.
static func _kunci_cocok(s: ShellSession, cfg: Dictionary) -> bool:
    var token := String(cfg.get("token", ""))
    if token == "":
        return false
    var jalur := String(cfg.get("kunci_lokal", ""))
    jalur = ShellSession.pindah_home(jalur, "operator", s.user)
    var berkas := s.fs.ambil(jalur)
    if berkas.is_empty() or String(berkas.get("tipe", "")) != "file":
        return false
    return ShellCommands.isi_berkas(berkas).contains(token)

# nmap -sn <subnet/24> [-oN berkas]: host discovery. Hanya host aktif di subnet yang ditampilkan.
static func _nmap_sn(s: ShellSession, p: Dictionary) -> Array:
    var args: Array = p["argumen"].duplicate()
    var berkas := ""
    if ShellParser.punya_opsi(p["opsi"], "-oN"):
        if args.size() < 2:
            return [s.galat("nmap", Teks.t("err.butuh_argumen"))]
        berkas = String(args[0])
        args.remove_at(0)
    if args.is_empty():
        return [s.galat("nmap", Teks.t("err.butuh_argumen"))]
    var target := String(args[0])
    var re := RegEx.new()
    re.compile("^(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})\\.0/24$")
    var m := re.search(target)
    if m == null:
        return [s.galat("nmap", "Failed to resolve \"%s\"." % target)]
    var j := s.jaringan
    var ids := j.host_di_subnet(m.get_string(1) + ".")
    var teks: Array = ["Starting Nmap 7.94 ( https://nmap.org )"]
    for id in ids:
        j.tandai_ditemukan(id)
        teks.append("Nmap scan report for %s" % j.ip(id))
        teks.append("Host is up (%.4fs latency)." % (float(int(j.data[id].get("latensi", 10))) / 1000.0))
    teks.append("Nmap done: 256 IP addresses (%d hosts up) scanned in 2.04 seconds" % ids.size())
    var hasil: Array = []
    for t in teks:
        hasil.append(s.baris("info", t))
    j.buka("nmap:sn")
    if berkas != "":
        var gagal := s.tulis_keluaran(berkas, "\n".join(PackedStringArray(teks)))
        if not gagal.is_empty():
            return gagal
        j.buka("nmap:laporan")
    return hasil
