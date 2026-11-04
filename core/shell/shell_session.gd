class_name ShellSession
extends RefCounted

# Sesi shell pemain: direktori kerja, pengguna, riwayat, dan filesystem aktif.
# Keluaran setiap perintah berupa Array of {tipe, teks}. Tipe: info, error, clear.

const HOME := "/home/operator"
const USER := "operator"
const GRUP := ["operator"]

var fs: Vfs
var cwd: String = HOME
var riwayat: Array = []

func _init(p_fs: Vfs) -> void:
    fs = p_fs

func prompt() -> String:
    var tampil := cwd
    if cwd == HOME:
        tampil = "~"
    elif cwd.begins_with(HOME + "/"):
        tampil = "~" + cwd.substr(HOME.length())
    return "%s@jtn:%s$" % [USER, tampil]

func jalankan(masukan: String) -> Array:
    var p := ShellParser.parse(masukan)
    if bool(p["kosong"]):
        return []
    riwayat.append(String(p["mentah"]))
    return ShellCommands.jalankan(self, p)

func baris(tipe: String, teks: String) -> Dictionary:
    return {"tipe": tipe, "teks": teks}

func galat(perintah: String, pesan: String) -> Dictionary:
    return baris("error", "bash: %s: %s" % [perintah, pesan])
