class_name SesiUtama
extends RefCounted

# Satu sesi shell untuk seluruh aplikasi. Terminal dan Peta Jaringan memakai objek yang sama,
# sehingga perubahan jaringan dari Terminal langsung terlihat di Peta. Sesi dibuat sekali per proses.

const FS_AWAL := "res://data/fs/pemain.json"

static var sesi: ShellSession = null
static var status_muat := ""
static var pesan_muat := ""

static func ambil() -> ShellSession:
    if sesi != null:
        return sesi
    var muat := Penyimpanan.muat()
    status_muat = String(muat["status"])
    pesan_muat = String(muat["pesan"])
    match status_muat:
        "ok", "pulih_cadangan":
            sesi = ShellSession.dari_dict(muat["data"])
        _:
            sesi = ShellSession.new(Vfs.new(_fs_awal()))
    Penyimpanan.simpan_sesi(sesi)
    return sesi

# Pesan untuk ditampilkan di terminal bila penyimpanan dipulihkan atau rusak. Kosong bila normal.
static func pesan_status() -> String:
    match status_muat:
        "pulih_cadangan":
            return "Penyimpanan utama rusak. Data dipulihkan dari cadangan. Berkas rusak disimpan di: %s" % pesan_muat
        "rusak":
            return "Penyimpanan rusak dan tidak ada cadangan. Mulai dari filesystem awal. Berkas rusak disimpan di: %s" % pesan_muat
    return ""

static func _fs_awal() -> Dictionary:
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(FS_AWAL)) == OK and typeof(parser.data) == TYPE_DICTIONARY and parser.data.has("/"):
        return parser.data["/"]
    return {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}
