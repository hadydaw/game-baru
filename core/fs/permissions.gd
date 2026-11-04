class_name Permissions
extends RefCounted

# Mengecek izin rwx sederhana (pemilik, grup, lainnya).
# mode: "r", "w", atau "x". user "root" selalu lolos.

const _INDEKS := {"r": 0, "w": 1, "x": 2}

static func boleh(node: Dictionary, user: String, grup: Array, mode: String) -> bool:
    if user == "root":
        return true
    if not _INDEKS.has(mode):
        return false
    var izin := String(node.get("izin", "---------"))
    if izin.length() != 9:
        return false
    var offset := 6
    if user == String(node.get("pemilik", "")):
        offset = 0
    elif grup.has(String(node.get("grup", ""))):
        offset = 3
    return izin.substr(offset + _INDEKS[mode], 1) == mode
