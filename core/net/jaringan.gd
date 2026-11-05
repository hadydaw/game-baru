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

# Mencari node berdasarkan nama atau IP. Mengembalikan id, atau "" bila tidak ada di konfigurasi.
# Tidak memeriksa apakah pemain sudah menemukannya; itu tugas pemanggil.
func cari(nama: String) -> String:
    if data.has(nama):
        return nama
    for id in data:
        if String(data[id].get("ip", "")) == nama:
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
        if String(data[id].get("ip", "")) == ip:
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
        "ip": String(data[id].get("ip", "")),
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
    return {"ditemukan": ditemukan, "progres": progres, "fs": fs_node, "dipindai": dipindai}

func terapkan(d: Dictionary) -> void:
    ditemukan = Array(d.get("ditemukan", ditemukan))
    progres = Array(d.get("progres", []))
    dipindai = Array(d.get("dipindai", []))
    var fs_tersimpan: Dictionary = d.get("fs", {})
    for id in fs_tersimpan:
        if fs_node.has(id):
            fs_node[id] = fs_tersimpan[id]
