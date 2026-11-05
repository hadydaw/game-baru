class_name Penyimpanan
extends RefCounted

# Penyimpanan permanen filesystem virtual dalam JSON.
# - Penulisan atomik: data ditulis ke berkas .tmp, dibaca ulang untuk verifikasi, lalu dipindahkan.
# - Versi sebelumnya disimpan sebagai .bak. Berkas utama yang rusak dipindahkan ke .rusak-<waktu>, tidak dihapus.
# - Data dimuat dari penyimpanan, bukan dari filesystem awal, sehingga perubahan pemain tidak tertimpa.

const VERSI := 1
const BERKAS := "user://filesystem.json"

# Jalur berkas yang dipakai bila pemanggil tidak memberi jalur. Tes mengganti ini agar tidak menimpa save asli.
static var berkas_aktif: String = BERKAS

# Hasil muat: {status, data, pesan}. status: "baru", "ok", "pulih_cadangan", atau "rusak".
static func muat(path: String = "") -> Dictionary:
    if path == "":
        path = berkas_aktif
    var bak := path + ".bak"
    if not FileAccess.file_exists(path) and not FileAccess.file_exists(bak):
        return {"status": "baru", "data": {}, "pesan": ""}
    var utama := _baca(path)
    if not utama.is_empty():
        return {"status": "ok", "data": utama, "pesan": ""}
    var cadangan := _baca(bak)
    var simpan_rusak := ""
    if FileAccess.file_exists(path):
        simpan_rusak = path + ".rusak-" + str(Time.get_unix_time_from_system())
        _pindah(path, simpan_rusak)
    if not cadangan.is_empty():
        return {"status": "pulih_cadangan", "data": cadangan, "pesan": simpan_rusak}
    return {"status": "rusak", "data": {}, "pesan": simpan_rusak}

# Menyimpan isi sesi. Mengembalikan true bila penulisan dan verifikasi berhasil.
static func simpan_sesi(sesi: ShellSession, path: String = "") -> bool:
    return simpan(sesi.to_dict(), path)

static func simpan(data: Dictionary, path: String = "") -> bool:
    if path == "":
        path = berkas_aktif
    var isi := data.duplicate()
    isi["versi"] = VERSI
    var tmp := path + ".tmp"
    var bak := path + ".bak"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify(isi, "  "))
    f.close()
    if _baca(tmp).is_empty():
        _hapus(tmp)
        return false
    if FileAccess.file_exists(path):
        _hapus(bak)
        if not _pindah(path, bak):
            _hapus(tmp)
            return false
    if _pindah(tmp, path):
        return true
    # Gagal memindahkan: kembalikan versi sebelumnya agar data tidak hilang.
    if FileAccess.file_exists(bak) and not FileAccess.file_exists(path):
        _pindah(bak, path)
    return false

# Membaca JSON dan memastikan struktur serta versinya benar. Mengembalikan {} bila tidak valid.
static func _baca(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    # JSON.new().parse tidak mencetak error engine saat isi rusak, jadi pemulihan berjalan tanpa galat tersembunyi.
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK:
        return {}
    var j: Variant = parser.data
    if typeof(j) != TYPE_DICTIONARY:
        return {}
    var d: Dictionary = j
    if int(d.get("versi", 0)) != VERSI:
        return {}
    if typeof(d.get("fs")) != TYPE_DICTIONARY:
        return {}
    return d

static func _pindah(dari: String, ke: String) -> bool:
    var dir := DirAccess.open(dari.get_base_dir())
    if dir == null:
        return false
    return dir.rename(dari.get_file(), ke.get_file()) == OK

static func _hapus(path: String) -> void:
    if not FileAccess.file_exists(path):
        return
    var dir := DirAccess.open(path.get_base_dir())
    if dir != null:
        dir.remove(path.get_file())
