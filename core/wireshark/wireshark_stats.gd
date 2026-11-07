class_name WiresharkStats
extends RefCounted

# Statistik dari daftar paket yang tampil: ringkasan, hierarki protokol, dan percakapan (pasangan alamat).
# Semua angka dihitung dari data paket simulasi yang sama dengan daftar paket.

static func ringkasan(paket: Array) -> Dictionary:
	var bytes := 0
	var awal := INF
	var akhir := -INF
	for p in paket:
		bytes += int(p.get("panjang", 0))
		var w := float(p.get("waktu", 0.0))
		awal = min(awal, w)
		akhir = max(akhir, w)
	var n := paket.size()
	var durasi := 0.0 if n == 0 else akhir - awal
	return {"paket": n, "bytes": bytes, "durasi": durasi, "rata": 0.0 if n == 0 else float(bytes) / n,
		"rata_pps": 0.0 if durasi <= 0.0 else float(n) / durasi}

# Hierarki: setiap lapisan dihitung sebagai baris berindentasi. Baris "frame" selalu jumlah total.
static func hierarki(paket: Array) -> Array:
	var total := paket.size()
	var total_bytes := 0
	var urutan: Array = []
	var agregat := {}
	for p in paket:
		total_bytes += int(p.get("panjang", 0))
		var jalur: Array = []
		for lap in p.get("lapisan", []):
			jalur.append(String(lap))
			var kunci := ":".join(jalur)
			if not agregat.has(kunci):
				agregat[kunci] = {"nama": String(lap), "kedalaman": jalur.size(), "paket": 0, "bytes": 0}
				urutan.append(kunci)
			agregat[kunci]["paket"] += 1
			agregat[kunci]["bytes"] += int(p.get("panjang", 0))
	var hasil: Array = [{"nama": "frame", "kedalaman": 0, "paket": total, "bytes": total_bytes, "persen": 100.0}]
	for kunci in urutan:
		var a: Dictionary = agregat[kunci]
		hasil.append({"nama": a["nama"], "kedalaman": a["kedalaman"], "paket": a["paket"], "bytes": a["bytes"],
			"persen": 0.0 if total == 0 else 100.0 * int(a["paket"]) / total})
	return hasil

# Percakapan: pasangan sumber-tujuan yang tidak berurutan dihitung sebagai satu percakapan.
static func percakapan(paket: Array) -> Array:
	var agregat := {}
	for p in paket:
		var a := String(p.get("sumber", ""))
		var b := String(p.get("tujuan", ""))
		if a == "" or b == "":
			continue
		var kiri := a if a <= b else b
		var kanan := b if a <= b else a
		var kunci := kiri + " <-> " + kanan
		if not agregat.has(kunci):
			agregat[kunci] = {"a": kiri, "b": kanan, "paket": 0, "bytes": 0}
		agregat[kunci]["paket"] += 1
		agregat[kunci]["bytes"] += int(p.get("panjang", 0))
	var hasil := agregat.values()
	hasil.sort_custom(func(x, y): return int(x["paket"]) > int(y["paket"]) or (int(x["paket"]) == int(y["paket"]) and String(x["a"]) < String(y["a"])))
	return hasil
