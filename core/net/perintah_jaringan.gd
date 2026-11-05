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
            return [s.galat("ping", "jumlah paket harus antara 1 dan 10")]
    if args.is_empty():
        return [s.galat("ping", Teks.t("err.butuh_argumen"))]
    var target := String(args[0])
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("ping", "%s: Nama atau layanan tidak diketahui" % target)]
    if j.terkunci(id):
        return [s.galat("ping", "%s: Destination Host Unreachable" % target)]
    var ip := String(j.data[id].get("ip", ""))
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
        return [s.galat("nmap", "%s: Nama atau layanan tidak diketahui" % target)]
    if j.terkunci(id):
        return [s.galat("nmap", "%s: Host tidak dapat dijangkau" % target)]
    var ip := String(j.data[id].get("ip", ""))
    var hasil: Array = [s.baris("info", "Memindai %s (%s)..." % [target, ip])]
    if not j.aktif(id):
        hasil.append(s.baris("info", "Host tampaknya tidak aktif (tidak ada respons)."))
        return hasil
    hasil.append(s.baris("info", "PORT       STATE    SERVICE"))
    var port_dict: Dictionary = j.data[id].get("port", {})
    var nomor_list := port_dict.keys()
    nomor_list.sort()
    var tampil := 0
    for nomor in nomor_list:
        var n := String(nomor)
        if not filter.is_empty() and not filter.has(n):
            continue
        var pd: Dictionary = port_dict[nomor]
        hasil.append(s.baris("info", "%-10s %-8s %s" % ["%s/tcp" % n, String(pd.get("status", "")), String(pd.get("layanan", ""))]))
        tampil += 1
    j.jelajahi(id)
    hasil.append(s.baris("info", "Pemindaian selesai: 1 host, %d port ditampilkan." % tampil))
    return hasil

static func ssh(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("ssh", Teks.t("err.butuh_argumen"))]
    if s.host != ShellSession.LOKAL:
        return [s.galat("ssh", "sudah berada di sesi jarak jauh. Ketik exit untuk keluar.")]
    var target := String(p["argumen"][0])
    var user := ShellSession.USER
    if target.contains("@"):
        var bagian := target.split("@")
        user = bagian[0]
        target = bagian[1]
    var j := s.jaringan
    var id := j.cari(target)
    if id == "" or not j.dikenal(id):
        return [s.galat("ssh", "Could not resolve hostname %s: Nama atau layanan tidak diketahui" % target)]
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
    jauh.cwd = ShellSession.HOME
    jauh.fs.akar = j.fs_node[id]
    s.ssh_aktif = jauh
    return [s.baris("info", "Terhubung ke %s (%s)." % [id, String(j.data[id].get("ip", ""))])]

# Kunci SSH adalah berkas di filesystem lokal yang isinya memuat token node.
static func _kunci_cocok(s: ShellSession, cfg: Dictionary) -> bool:
    var token := String(cfg.get("token", ""))
    if token == "":
        return false
    var berkas := s.fs.ambil(String(cfg.get("kunci_lokal", "")))
    if berkas.is_empty() or String(berkas.get("tipe", "")) != "file":
        return false
    return ShellCommands.isi_berkas(berkas).contains(token)
