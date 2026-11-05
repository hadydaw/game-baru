class_name AnalisisCommands
extends RefCounted

# Perintah Crypt Decoder (decode) dan Password Analyzer (analyze).
# Berkas terenkripsi punya field "enkripsi": "A" | "B" | "C" (tingkat decoder yang dibutuhkan),
# "isi_asli" (isi setelah didekripsi), dan "isi" (teks terenkripsi yang ditampilkan cat).

const TINGKAT_ENKRIPSI := {"A": 1, "B": 2, "C": 3}

# Pesan penolakan cat untuk berkas terenkripsi, atau "" bila berkas boleh dibaca.
static func tolak_cat(s: ShellSession, node: Dictionary) -> String:
    if not node.has("enkripsi"):
        return ""
    var butuh := int(TINGKAT_ENKRIPSI.get(String(node["enkripsi"]), 1))
    var punya := s.inventory.tingkat("crypt_decoder")
    if punya >= butuh:
        return ""
    if punya == 0:
        return Teks.t("err.butuh_decoder")
    return Teks.t("err.butuh_decoder_tingkat", {"tingkat": butuh})

static func decode(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("decode", Teks.t("err.butuh_argumen"))]
    if p["argumen"].size() > 1:
        return [s.galat("decode", Teks.t("err.satu_berkas"))]
    var target := String(p["argumen"][0])
    var abs := Vfs.normalisasi(s.cwd, target, s.home)
    var node := s.fs.ambil(abs)
    if node.is_empty():
        return [s.galat("decode", "%s: %s" % [target, Teks.t("err.tidak_ada")])]
    if String(node.get("tipe", "")) != "file":
        return [s.galat("decode", "%s: %s" % [target, Teks.t("err.direktori")])]
    if not node.has("enkripsi"):
        return [s.galat("decode", "%s: %s" % [target, Teks.t("err.tidak_terenkripsi")])]
    if not Permissions.boleh(node, s.user, s.grup, "r"):
        return [s.galat("decode", "%s: %s" % [target, Teks.t("err.izin")])]
    var pesan := tolak_cat(s, node)
    if pesan != "":
        return [s.galat("decode", pesan)]
    var hasil: Array = []
    for b in String(node.get("isi_asli", "")).split("\n"):
        hasil.append(s.baris("info", b))
    return hasil

# analyze <berkas>: memeriksa jenis hash dan ada tidaknya salt. Tingkat 1.
# Petunjuk puzzle (tingkat 2 dan 3) mengikuti sistem puzzle pada tahap berikutnya.
static func analyze(s: ShellSession, p: Dictionary) -> Array:
    if p["argumen"].is_empty():
        return [s.galat("analyze", Teks.t("err.butuh_argumen"))]
    var target := String(p["argumen"][0])
    var abs := Vfs.normalisasi(s.cwd, target, s.home)
    var node := s.fs.ambil(abs)
    if node.is_empty():
        return [s.galat("analyze", "%s: %s" % [target, Teks.t("err.tidak_ada")])]
    if String(node.get("tipe", "")) != "file":
        return [s.galat("analyze", "%s: %s" % [target, Teks.t("err.direktori")])]
    if not node.has("hash"):
        return [s.baris("info", Teks.t("analyze.tanpa_hash"))]
    var hash: Dictionary = node["hash"]
    var hasil: Array = [s.baris("info", Bahasa.dua("Jenis hash: %s", "Hash type: %s", [String(hash.get("algo", "tidak dikenal"))]))]
    if bool(hash.get("salt", false)):
        hasil.append(s.baris("info", Bahasa.dua("Salt: terdeteksi. Hash ini tidak dapat dianalisis lebih lanjut.", "Salt: detected. This hash cannot be analyzed further.")))
    else:
        hasil.append(s.baris("info", Bahasa.dua("Salt: tidak ada.", "Salt: none.")))
    return hasil
