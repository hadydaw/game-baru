class_name ShellSession
extends RefCounted

# Sesi shell pemain: direktori kerja, pengguna, riwayat, filesystem aktif, dan jaringan.
# Keluaran setiap perintah berupa Array of {tipe, teks}. Tipe: info, error, clear.
# Saat SSH aktif, perintah diteruskan ke sesi jarak jauh (ssh_aktif) sampai pemain mengetik exit.

const HOME := "/home/operator"
const USER := "operator"
const GRUP := ["operator"]
const LOKAL := "jtn"

var fs: Vfs
var cwd: String = HOME
var riwayat: Array = []
var host: String = LOKAL
var jaringan: Jaringan
var economy: Economy
var inventory: Inventory
var market: BlackMarket
var hadiah_diambil: Array = []  # flag misi yang hadiahnya sudah diberikan
var reputation: Reputation
var ssh_aktif: ShellSession = null

func _init(p_fs: Vfs, p_jaringan: Jaringan = null) -> void:
    fs = p_fs
    jaringan = p_jaringan if p_jaringan != null else Jaringan.muat()
    economy = Economy.baru()
    inventory = Inventory.baru()
    market = BlackMarket.baru()
    reputation = Reputation.baru()

# Seluruh keadaan sesi lokal yang perlu disimpan: filesystem, direktori aktif, riwayat, dan jaringan.
func to_dict() -> Dictionary:
    return {"fs": fs.akar, "cwd": cwd, "riwayat": riwayat, "jaringan": jaringan.to_dict(), "ekonomi": economy.to_dict(), "reputasi": reputation.to_dict(), "inventaris": inventory.to_dict(), "pasar": market.to_dict(), "hadiah": hadiah_diambil.duplicate()}

static func dari_dict(d: Dictionary) -> ShellSession:
    var j := Jaringan.muat()
    if typeof(d.get("jaringan")) == TYPE_DICTIONARY:
        j.terapkan(d["jaringan"])
    var s := ShellSession.new(Vfs.new(d.get("fs", {})), j)
    var cwd_tersimpan := String(d.get("cwd", HOME))
    s.cwd = cwd_tersimpan if s.fs.ada(cwd_tersimpan) else HOME
    s.riwayat = Array(d.get("riwayat", []))
    if typeof(d.get("ekonomi")) == TYPE_DICTIONARY:
        s.economy.terapkan(d["ekonomi"])
    if typeof(d.get("reputasi")) == TYPE_DICTIONARY:
        s.reputation.terapkan(d["reputasi"])
    if typeof(d.get("inventaris")) == TYPE_DICTIONARY:
        s.inventory.terapkan(d["inventaris"])
    if typeof(d.get("pasar")) == TYPE_DICTIONARY:
        s.market.terapkan(d["pasar"])
    s.hadiah_diambil = Array(d.get("hadiah", []))
    return s

func prompt() -> String:
    if ssh_aktif != null:
        return ssh_aktif.prompt()
    var tampil := cwd
    if cwd == HOME:
        tampil = "~"
    elif cwd.begins_with(HOME + "/"):
        tampil = "~" + cwd.substr(HOME.length())
    return "%s@%s:%s$" % [USER, host, tampil]

func jalankan(masukan: String) -> Array:
    if ssh_aktif != null:
        var t := masukan.strip_edges()
        if t == "exit":
            riwayat.append(t)
            var tutup := ssh_aktif.host
            ssh_aktif = null
            return [baris("info", "Koneksi ke %s ditutup." % tutup)]
        if t != "":
            riwayat.append(t)
        return ssh_aktif.jalankan(masukan)
    var p := ShellParser.parse(masukan)
    if bool(p["kosong"]):
        return []
    riwayat.append(String(p["mentah"]))
    var token := ShellParser.tokenkan(masukan)
    var idx := _cari_redirect(token)
    if idx == -1:
        return ShellCommands.jalankan(self, p)
    return _jalankan_redirect(token, idx, masukan)

func baris(tipe: String, teks: String) -> Dictionary:
    return {"tipe": tipe, "teks": teks}

func galat(perintah: String, pesan: String) -> Dictionary:
    return baris("error", "bash: %s: %s" % [perintah, pesan])

# Mengembalikan indeks token yang berisi operator > atau >>, atau -1.
func _cari_redirect(token: Array) -> int:
    for i in range(token.size()):
        var t := String(token[i])
        if t.begins_with(">"):
            return i
    return -1

# Menjalankan perintah lalu menulis keluarannya ke berkas (> menimpa, >> menambah).
# Hanya keluaran info yang ditulis. Galat tetap tampil di layar, seperti di shell sungguhan.
func _jalankan_redirect(token: Array, idx: int, masukan: String) -> Array:
    var op := String(token[idx])
    var tambah := op.begins_with(">>")
    var tujuan := op.substr(2 if tambah else 1)
    var sisa := idx + 1
    if tujuan.is_empty():
        if sisa >= token.size():
            return [galat("bash", "sintaks tidak lengkap dekat '>'")]
        tujuan = String(token[sisa])
        sisa += 1
    if sisa < token.size():
        return [galat("bash", "terlalu banyak tujuan redirect")]
    if idx == 0:
        return [galat("bash", "perintah kosong sebelum '>'")]
    var p := ShellParser.dari_token(token.slice(0, idx), masukan)
    var keluaran := ShellCommands.jalankan(self, p)
    var teks: Array = []
    for b in keluaran:
        if String(b["tipe"]) == "error":
            return keluaran
        teks.append(String(b["teks"]))
    return _tulis_berkas(tujuan, "\n".join(PackedStringArray(teks)), tambah)

func _tulis_berkas(tujuan: String, isi: String, tambah: bool) -> Array:
    var abs := Vfs.normalisasi(cwd, tujuan, HOME)
    var nama := fs.nama_terakhir(abs)
    var induk_path := fs.induk(abs)
    var induk_node := fs.ambil(induk_path)
    if induk_node.is_empty() or String(induk_node.get("tipe", "")) != "dir":
        return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.tidak_ada_induk")])]
    if not Permissions.boleh(induk_node, USER, GRUP, "w"):
        return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.izin")])]
    var ada := fs.ambil(abs)
    if not ada.is_empty():
        if String(ada.get("tipe", "")) == "dir":
            return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.direktori")])]
        if not Permissions.boleh(ada, USER, GRUP, "w"):
            return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.izin")])]
        var lama := ShellCommands.isi_berkas(ada) if tambah else ""
        var gabung := isi
        if tambah and not lama.is_empty():
            gabung = lama + "\n" + isi
        ada["isi"] = gabung
        ada["ukuran"] = gabung.length()
        return []
    var baru := {"tipe": "file", "pemilik": USER, "grup": "operator", "izin": "rw-r-----", "isi": isi, "ukuran": isi.length()}
    fs.tambah(induk_path, nama, baru)
    return []
