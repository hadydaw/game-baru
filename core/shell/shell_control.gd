class_name ShellControl
extends RefCounted

# Kombinasi Ctrl + huruf pada terminal. Hanya kombinasi yang didukung yang menghasilkan aksi:
#   Ctrl+C  batalkan baris (^C)
#   Ctrl+L  bersihkan layar (riwayat tetap)
#   Ctrl+U  hapus baris masukan
# Kombinasi lain tidak melakukan apa-apa.

static func aksi(huruf: String) -> String:
    match huruf.to_lower():
        "c": return "batal"
        "l": return "bersihkan"
        "u": return "hapus_baris"
    return ""

# Mencari karakter yang baru disisipkan dibanding teks sebelumnya.
# Mengembalikan {huruf, teks}: teks adalah masukan tanpa karakter sisipan tersebut.
# huruf kosong bila perubahan bukan penyisipan tepat satu karakter.
static func sisipan(lama: String, baru: String) -> Dictionary:
    if baru.length() != lama.length() + 1:
        return {"huruf": "", "teks": baru}
    var i := 0
    while i < lama.length() and lama[i] == baru[i]:
        i += 1
    return {"huruf": baru[i], "teks": baru.substr(0, i) + baru.substr(i + 1)}
