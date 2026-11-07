extends RefCounted

# Pemanggil aplikasi untuk tes. Perintah game sudah dipindah dari Terminal ke aplikasinya
# (Alat Lapangan, Toko Perangkat, Device Manager, Pasar). Fungsi di sini memanggil handler yang
# sama dengan layar aplikasi, sehingga efek, flag misi, dan galatnya sama seperti saat dimainkan.

static func alat(s: ShellSession, nama: String, argumen: Array = []) -> Array:
	return AlatCommands.jalankan(s, nama, argumen)

# Tombol Beli di Toko Perangkat.
static func beli(s: ShellSession, id: String) -> Dictionary:
	var h: Dictionary = s.perangkat.beli(id, s.economy)
	if bool(h["ok"]):
		s.jaringan.buka("beli:" + id)
	return h

# Tombol Rakit di Device Manager.
static func rakit(s: ShellSession) -> Dictionary:
	var h: Dictionary = s.perangkat.rakit()
	if bool(h["ok"]):
		s.jaringan.buka("rakit:wifi_kit")
	return h

# Tombol Hubungkan di Device Manager.
static func hubungkan(s: ShellSession) -> Dictionary:
	return PerangkatCommands.hubungkan(s)

# Teks galat atau info dari hasil aksi aplikasi (kunci + args).
static func teks_h(h: Dictionary) -> String:
	if not h.has("kunci"):
		return ""
	return Bahasa.t(String(h["kunci"])) % h.get("args", [])

# Menjalankan satu langkah tutorial. Token "__beli__<id>", "__rakit__", dan "__hubungkan__" mewakili
# tombol di aplikasi; perintah lain diteruskan ke Terminal. Hasilnya berupa blok teks seperti Terminal.
static func jalan(s: ShellSession, c: String) -> Array:
	if c.begins_with("__beli__"):
		var id := c.substr("__beli__".length())
		var h := beli(s, id)
		return [_blok(h, Bahasa.dua("Dibeli: %s", "Bought: %s", [id]))]
	if c == "__rakit__":
		return [_blok(rakit(s), Bahasa.dua("Dirakit", "Assembled"))]
	if c == "__hubungkan__":
		return [_blok(hubungkan(s), Bahasa.dua("Terhubung", "Connected"))]
	return s.jalankan(c)

static func _blok(h: Dictionary, sukses: String) -> Dictionary:
	var ok := bool(h.get("ok", false))
	return {"tipe": "info" if ok else "error", "teks": sukses if ok else teks_h(h)}
