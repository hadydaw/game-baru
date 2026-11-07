class_name AlatCommands
extends RefCounted

# Nama perintah Alat. Tidak ditampilkan di help Terminal, karena dijalankan dari aplikasi Alat.
const NAMA := ["scan", "inspeksi", "trace", "decode", "analyze"]

# Alat Lapangan: scan, inspeksi, trace, decode, dan analyze. Dulu dipanggil lewat Terminal; sekarang
# lewat aplikasi Alat. Gerbang kepemilikan sama seperti dulu: perintah hanya dikenali setelah tool-nya
# dimiliki (lihat CommandRegistry), sehingga Alat tidak bisa dipakai tanpa tool yang dibutuhkan.

static func jalankan(s: ShellSession, nama: String, argumen: Array) -> Array:
	if not CommandRegistry.tersedia(s, nama):
		return [s.galat(nama, Teks.t("err.tidak_ditemukan"))]
	var p := {"kosong": argumen.is_empty(), "nama": nama, "opsi": [], "argumen": argumen, "mentah": (nama + " " + " ".join(PackedStringArray(argumen))).strip_edges()}
	match nama:
		"scan":
			return PerintahScan.scan(s, p)
		"inspeksi":
			return ToolCommands.inspeksi(s, p)
		"trace":
			return ToolCommands.trace(s, p)
		"decode":
			return AnalisisCommands.decode(s, p)
		"analyze":
			return AnalisisCommands.analyze(s, p)
	return [s.galat(nama, Teks.t("err.tidak_ditemukan"))]
