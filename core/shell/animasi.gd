class_name Animasi
extends RefCounted

# Rencana animasi pemrosesan perintah. Hanya visualisasi: setiap baris output berasal dari hasil
# perintah yang sudah dihitung, jadi teks yang tampil selalu sama dengan hasil asli dan tidak ada koneksi nyata.
# Langkah yang dihasilkan:
#   {tipe: "status", teks, durasi (ms), gaya: "spinner"|"titik"|"bar", bar: 0-10}
#   {tipe: "baris", tipe_baris: "info"|"error", teks, jeda (ms)}
#   {tipe: "clear"}

const JEDA_BARIS := 40

static func rencana(perintah: String, hasil: Array) -> Array:
    var nama := String(ShellParser.parse(perintah)["nama"])
    if nama == "clear":
        return [{"tipe": "clear"}]
    if hasil.is_empty():
        return []
    match nama:
        "nmap":
            return _nmap(hasil)
        "ping":
            return _ping(hasil)
        "ssh":
            return _ssh(hasil)
        "exit":
            return [_status("Menutup sesi SSH...", 300, "spinner")] + _semua_baris(hasil)
    var pembuka := "Memproses %s..." % nama if nama in Teks.MAN.keys() else "Mencari perintah..."
    return [_status(pembuka, 200, "titik")] + _semua_baris(hasil)

# Tahapan pemindaian: inisialisasi, penemuan host, pemindaian port, deteksi layanan, selesai.
static func _nmap(hasil: Array) -> Array:
    var tahap := [
        ["Initializing scanner...", 1],
        ["Host discovery...", 3],
        ["Port scanning...", 6],
        ["Service detection...", 8],
        ["Scan completed.", 10],
    ]
    var jumlah := tahap.size() if not _ada_galat(hasil) else 2
    var langkah: Array = []
    for i in range(jumlah):
        langkah.append(_status(String(tahap[i][0]), 350, "bar", int(tahap[i][1])))
    return langkah + _semua_baris(hasil)

# Setiap paket dikirim satu per satu, lalu balasannya muncul setelah jeda.
static func _ping(hasil: Array) -> Array:
    var total := 0
    for b in hasil:
        if _paket(String(b["teks"])):
            total += 1
    var langkah: Array = []
    if total == 0:
        langkah.append(_status("Mengirim ICMP echo...", 250, "spinner"))
    var k := 0
    for b in hasil:
        var t := String(b["teks"])
        if _paket(t):
            k += 1
            langkah.append(_status("Mengirim paket %d dari %d" % [k, total], 300, "spinner"))
            langkah.append(_baris_dari(b, 200))
        else:
            langkah.append(_baris_dari(b))
    return langkah

# Tahapan SSH tergantung hasilnya: gagal di resolusi nama, di koneksi, atau di autentikasi.
static func _ssh(hasil: Array) -> Array:
    var gabung := ""
    for b in hasil:
        gabung += String(b["teks"]) + "\n"
    var tahap := ["Resolving hostname...", "Connecting to remote host...", "Establishing connection...", "Authenticating public key..."]
    var jumlah := 4
    if _ada_galat(hasil):
        if gabung.contains("sudah berada"):
            jumlah = 0
        elif gabung.contains("Could not resolve"):
            jumlah = 1
        elif gabung.contains("timed out") or gabung.contains("No route") or gabung.contains("refused"):
            jumlah = 2
        else:
            jumlah = 4
    var langkah: Array = []
    for i in range(jumlah):
        langkah.append(_status(String(tahap[i]), 400, "titik"))
    if not _ada_galat(hasil):
        langkah.append(_status("Authentication successful.", 300, "spinner"))
        langkah.append(_status("Membuka sesi terminal remote...", 300, "spinner"))
    return langkah + _semua_baris(hasil)

static func _paket(teks: String) -> bool:
    return teks.begins_with("64 bytes") or teks.begins_with("Request timeout")

static func _ada_galat(hasil: Array) -> bool:
    for b in hasil:
        if String(b["tipe"]) == "error":
            return true
    return false

static func _status(teks: String, durasi: int, gaya: String, bar: int = 0) -> Dictionary:
    return {"tipe": "status", "teks": teks, "durasi": durasi, "gaya": gaya, "bar": bar}

static func _baris_dari(b: Dictionary, jeda: int = JEDA_BARIS) -> Dictionary:
    return {"tipe": "baris", "tipe_baris": String(b["tipe"]), "teks": String(b["teks"]), "jeda": jeda}

static func _semua_baris(hasil: Array) -> Array:
    var hasil_langkah: Array = []
    for b in hasil:
        if String(b["tipe"]) == "clear":
            hasil_langkah.append({"tipe": "clear"})
        else:
            hasil_langkah.append(_baris_dari(b))
    return hasil_langkah
