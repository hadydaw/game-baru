class_name ShellComplete
extends RefCounted

# Tab: melengkapi nama perintah (kata pertama) atau nama berkas/direktori (kata berikutnya).
# Mengembalikan {teks: teks baru, pilihan: daftar kecocokan bila lebih dari satu}.

static func lengkapi(s: ShellSession, teks: String) -> Dictionary:
    var awal := ""
    var dir_teks := ""
    var prefix := teks
    var kandidat: Array = []
    if not teks.contains(" "):
        for nama in Teks.MAN.keys():
            if String(nama).begins_with(teks):
                kandidat.append(String(nama))
        kandidat.sort()
    else:
        var sp := teks.rfind(" ")
        awal = teks.substr(0, sp + 1)
        var token := teks.substr(sp + 1)
        var garis := token.rfind("/")
        dir_teks = token.substr(0, garis + 1) if garis >= 0 else ""
        prefix = token.substr(garis + 1)
        var abs := Vfs.normalisasi(s.cwd, dir_teks if dir_teks != "" else ".", s.home)
        var node := s.fs.ambil(abs)
        if node.is_empty() or String(node.get("tipe", "")) != "dir":
            return {"teks": teks, "pilihan": []}
        var isi: Dictionary = node.get("isi", {})
        var nama_list := isi.keys()
        nama_list.sort()
        for nama in nama_list:
            var n := String(nama)
            if n.begins_with(".") and not prefix.begins_with("."):
                continue
            if n.begins_with(prefix):
                var anak: Dictionary = isi[nama]
                kandidat.append(n + ("/" if String(anak.get("tipe", "")) == "dir" else ""))
    if kandidat.is_empty():
        return {"teks": teks, "pilihan": []}
    if kandidat.size() == 1:
        var hasil := awal + dir_teks + String(kandidat[0])
        if not hasil.ends_with("/"):
            hasil += " "
        return {"teks": hasil, "pilihan": []}
    var bersama := _awalan_bersama(kandidat)
    var baru := teks
    if bersama.length() > prefix.length():
        baru = awal + dir_teks + bersama
    return {"teks": baru, "pilihan": kandidat}

static func _awalan_bersama(daftar: Array) -> String:
    var pertama := String(daftar[0])
    var panjang := pertama.length()
    for d in daftar:
        var s := String(d)
        while panjang > 0 and not s.begins_with(pertama.substr(0, panjang)):
            panjang -= 1
    return pertama.substr(0, panjang)
