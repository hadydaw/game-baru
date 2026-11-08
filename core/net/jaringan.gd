class_name Jaringan
extends RefCounted

# Jaringan virtual JTN: konfigurasi node, koneksi antar node, dan keadaan penemuan pemain.
# Ini satu-satunya sumber data jaringan. Terminal dan Peta Jaringan sama-sama membaca dari sini.
# Tidak ada koneksi atau pemindaian ke jaringan sungguhan.

const DATA := "res://data/jaringan/jaringan.json"

var data: Dictionary = {}      # konfigurasi node dari JSON, tidak berubah saat bermain
var ditemukan: Array = []      # id node yang sudah diketahui pemain
var progres: Array = []        # flag misi yang sudah terbuka (mengunci/membuka node)
var fs_node: Dictionary = {}   # filesystem tiap node; bisa berubah lewat SSH
var dipindai: Array = []       # id node yang sudah pernah dipindai nmap
var ip_node: Dictionary = {}   # id node -> IP yang dibuat saat Sesi Baru; kosong = pakai IP dari JSON

# Rentang IP privat yang dipakai saat membuat IP acak. Setiap node memilih salah satu rentang.
const RENTANG_IP := [["10", 0, 255], ["172", 16, 31], ["192.168", 0, 255]]
# Laboratorium internal Tutorial 2: subnet tetap agar data Wireshark dan IP tetap konsisten.
const SUBNET_LAB2 := "10.8.1."
const PEMAIN_IP := "10.8.1.42"
const PEMAIN_MAC := "02:4a:1c:10:00:42"

static func muat(path: String = DATA) -> Jaringan:
    var j := Jaringan.new()
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
        push_error("Jaringan: konfigurasi tidak bisa dibaca: %s" % path)
        return j
    j.data = parser.data
    for id in j.data:
        var cfg: Dictionary = j.data[id]
        j.fs_node[id] = Dictionary(cfg.get("fs", {})).duplicate(true)
        if bool(cfg.get("ditemukan_awal", false)):
            j.ditemukan.append(String(id))
    return j

# IP sebuah node: hasil acak per sesi bila ada, jika tidak memakai IP dari konfigurasi.
func ip(id: String) -> String:
    if ip_node.has(id):
        return String(ip_node[id])
    return String(data.get(id, {}).get("ip", ""))

# Jenis perangkat dari identitas node (mis. gateway, printer). Tidak di-hardcode per IP.
func jenis(id: String) -> String:
    return String(data.get(id, {}).get("jenis", "perangkat"))

# Membuat IP privat acak yang unik untuk setiap node. Dipanggil sekali saat Sesi Baru.
func acak_ip(rng: RandomNumberGenerator = null) -> void:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    ip_node.clear()
    var terpakai := {}
    # Node dengan IP tetap (laboratorium Tutorial 2) tidak diacak, dan subnetnya tidak dipakai node lain.
    for id in data:
        if bool(data[id].get("ip_tetap", false)):
            terpakai[String(data[id]["ip"])] = true
    for id in data:
        if bool(data[id].get("ip_tetap", false)):
            continue
        var alamat := ""
        while alamat == "" or terpakai.has(alamat) or alamat.begins_with(SUBNET_LAB2):
            var r: Array = RENTANG_IP[rng.randi() % RENTANG_IP.size()]
            var awal := String(r[0])
            if awal == "10":
                alamat = "10.%d.%d.%d" % [rng.randi_range(0, 255), rng.randi_range(0, 255), rng.randi_range(2, 254)]
            elif awal == "172":
                alamat = "172.%d.%d.%d" % [rng.randi_range(16, 31), rng.randi_range(0, 255), rng.randi_range(2, 254)]
            else:
                alamat = "192.168.%d.%d" % [rng.randi_range(0, 255), rng.randi_range(2, 254)]
        terpakai[alamat] = true
        ip_node[id] = alamat

# Mencari node berdasarkan nama atau IP. Mengembalikan id, atau "" bila tidak ada di konfigurasi.
# Tidak memeriksa apakah pemain sudah menemukannya; itu tugas pemanggil.
func cari(nama: String) -> String:
    if data.has(nama):
        return nama
    for id in data:
        if ip(String(id)) == nama:
            return String(id)
    return ""

func dikenal(id: String) -> bool:
    return ditemukan.has(id)

func terkunci(id: String) -> bool:
    for f in data[id].get("syarat", []):
        if not progres.has(String(f)):
            return true
    return false

func aktif(id: String) -> bool:
    return String(data[id].get("status", "")) == "aktif"

# Node yang berhasil dijangkau memperlihatkan tetangganya ke pemain.
# Node bertanda "penemuan": "scan" tidak ikut terbuka; hanya perintah scan yang bisa menemukannya.
func jelajahi(id: String) -> void:
    for t in data[id].get("tetangga", []):
        var tid := String(t)
        if not ditemukan.has(tid) and not butuh_scan(tid):
            ditemukan.append(tid)

# Node yang hanya bisa ditemukan lewat perintah scan.
func butuh_scan(id: String) -> bool:
    return data.has(id) and String(data[id].get("penemuan", "")) == "scan"

# Menandai node sebagai diketahui. Dipakai oleh perintah scan.
func tandai_ditemukan(id: String) -> void:
    if not ditemukan.has(id):
        ditemukan.append(id)

# Mencari node berdasarkan alamat IP saja. Mengembalikan id, atau "" bila tidak ada.
func cari_ip(ip: String) -> String:
    for id in data:
        if ip(String(id)) == ip:
            return String(id)
    return ""

func tandai_dipindai(id: String) -> void:
    if not dipindai.has(id):
        dipindai.append(id)

func sudah_dipindai(id: String) -> bool:
    return dipindai.has(id)

func buka(flag: String) -> void:
    if not progres.has(flag):
        progres.append(flag)

# Ringkasan satu node untuk Peta Jaringan. Sumber sama dengan yang dipakai Terminal.
func ringkasan(id: String) -> Dictionary:
    return {
        "id": id,
        "ip": ip(id),
        "status": String(data[id].get("status", "")),
        "terkunci": terkunci(id),
        "tetangga": data[id].get("tetangga", []),
        "port": data[id].get("port", {}),
        "ssh_tersedia": data[id].has("ssh"),
    }

# Semua node yang sudah ditemukan pemain, diurutkan berdasarkan id.
func daftar_terlihat() -> Array:
    var urut := ditemukan.duplicate()
    urut.sort()
    var hasil: Array = []
    for id in urut:
        if data.has(id):
            hasil.append(ringkasan(String(id)))
    return hasil

func to_dict() -> Dictionary:
    return {"ditemukan": ditemukan, "progres": progres, "fs": fs_node, "dipindai": dipindai, "ip_node": ip_node}

func terapkan(d: Dictionary) -> void:
    ditemukan = Array(d.get("ditemukan", ditemukan))
    progres = Array(d.get("progres", []))
    dipindai = Array(d.get("dipindai", []))
    ip_node = Dictionary(d.get("ip_node", ip_node)).duplicate()
    var fs_tersimpan: Dictionary = d.get("fs", {})
    for id in fs_tersimpan:
        if fs_node.has(id):
            fs_node[id] = fs_tersimpan[id]

# Host yang bisa dijangkau di subnet /24 (prefiks seperti "10.8.1."), diurutkan menurut IP.
# Node yang masih terkunci atau tidak aktif tidak ikut.
func host_di_subnet(prefiks: String) -> Array:
    var hasil: Array = []
    for id in data:
        var sid := String(id)
        if not ip(sid).begins_with(prefiks) or not aktif(sid) or terkunci(sid):
            continue
        hasil.append(sid)
    hasil.sort_custom(func(a, b): return ip(a) < ip(b))
    return hasil
