class_name ShellParser
extends RefCounted

# Mengubah satu baris masukan menjadi perintah, opsi, dan argumen.
# Mengikuti gaya bash: kutip tunggal dan ganda, spasi sebagai pemisah.
# Opsi dimulai dengan "-". Penanganan opsi per perintah ada di handler.

static func tokenkan(masukan: String) -> Array:
    var hasil: Array = []
    var sedang := ""
    var ada_token := false
    var kutip := ""
    for i in range(masukan.length()):
        var c := masukan[i]
        if kutip != "":
            if c == kutip:
                kutip = ""
            else:
                sedang += c
            continue
        if c == "'" or c == "\"":
            kutip = c
            ada_token = true
        elif c == " " or c == "\t":
            if ada_token:
                hasil.append(sedang)
                sedang = ""
                ada_token = false
        else:
            sedang += c
            ada_token = true
    if ada_token:
        hasil.append(sedang)
    return hasil

static func parse(masukan: String) -> Dictionary:
    var token := tokenkan(masukan)
    if token.is_empty():
        return {"kosong": true, "nama": "", "opsi": [], "argumen": [], "mentah": masukan}
    return dari_token(token, masukan)

# Membentuk hasil parse dari daftar token yang sudah dipisah (dipakai juga untuk perintah ber-redirect).
static func dari_token(token: Array, mentah: String) -> Dictionary:
    var opsi: Array = []
    var argumen: Array = []
    for i in range(1, token.size()):
        var t := String(token[i])
        if t.begins_with("-") and t.length() > 1:
            opsi.append(t)
        else:
            argumen.append(t)
    return {
        "kosong": false,
        "nama": String(token[0]),
        "opsi": opsi,
        "argumen": argumen,
        "mentah": mentah.strip_edges(),
    }

# Mengecek apakah opsi tertentu (misal "--scan") ada di daftar opsi.
static func punya_opsi(opsi: Array, nama: String) -> bool:
    return opsi.has(nama)

# Mengecek apakah opsi pendek gabungan (misal "-la") memuat huruf tertentu.
static func punya_huruf(opsi: Array, huruf: String) -> bool:
    for o in opsi:
        var s := String(o)
        if s.begins_with("--"):
            continue
        if s.substr(1).contains(huruf):
            return true
    return false
