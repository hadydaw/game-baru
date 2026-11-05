class_name PerangkatCommands
extends RefCounted

# Perintah perangkat keras di terminal: device (list, detect, rakit, hubungkan, putuskan, upgrade antena)
# dan toko (daftar komponen, toko beli <id>). Semua perubahan dilakukan oleh Perangkat dan Economy.

static func device(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	var sub := "list" if args.is_empty() else String(args[0])
	match sub:
		"list":
			return _daftar(s)
		"detect":
			return _deteksi(s)
		"rakit":
			var pilih := String(args[1]) if args.size() > 1 else ""
			var h := s.perangkat.rakit(pilih)
			if bool(h["ok"]):
				s.jaringan.buka("rakit:wifi_kit")
			return [s.hasil_ke_baris("device", h)]
		"hubungkan":
			return _hubungkan(s)
		"putuskan":
			return [s.hasil_ke_baris("device", s.perangkat.putuskan())]
		"upgrade":
			if args.size() < 2 or String(args[1]) != "antena":
				return [s.galat_kunci("device", "dev.usage")]
			var h := s.perangkat.upgrade_antena()
			if bool(h["ok"]):
				s.jaringan.buka("upgrade:antena")
			return [s.hasil_ke_baris("device", h)]
	return [s.galat_kunci("device", "dev.usage")]

static func toko(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.is_empty():
		return _katalog(s)
	if String(args[0]) == "beli":
		if args.size() < 2:
			return [s.galat_kunci("toko", "err.butuh_argumen")]
		var id := String(args[1])
		var h := s.perangkat.beli(id, s.economy)
		if bool(h["ok"]):
			s.jaringan.buka("beli:" + id)
		return [s.hasil_ke_baris("toko", h)]
	return [s.galat_kunci("toko", "toko.usage")]

static func _daftar(s: ShellSession) -> Array:
	var hasil: Array = [s.baris_kunci("info", "dev.judul_komponen")]
	var ids := s.perangkat.komponen.keys()
	ids.sort()
	if ids.is_empty():
		hasil.append(s.baris_kunci("info", "dev.kosong"))
	for id in ids:
		hasil.append(s.baris("info", "  %-28s x%d" % [String(Perangkat.info(String(id))["nama"]), s.perangkat.jumlah(String(id))]))
	hasil.append(s.baris_kunci("info", "dev.judul_perangkat"))
	if not s.perangkat.sudah_dirakit():
		hasil.append(s.baris_kunci("info", "dev.belum_rakit"))
		return hasil
	var p := s.perangkat
	var nama := String(Perangkat.info(p.adapter())["nama"])
	var status := Bahasa.kunci_dua("dev.terhubung") if p.terhubung() else Bahasa.kunci_dua("dev.tidak_terhubung")
	var driver := p.driver_aktif() if p.driver_aktif() != "" else Bahasa.kunci_dua("dev.belum_driver")
	hasil.append(s.baris("info", "  %s" % nama))
	hasil.append(s.baris_kunci("info", "dev.rincian", [p.antena(), status, driver]))
	return hasil

static func _deteksi(s: ShellSession) -> Array:
	var p := s.perangkat
	if p.sudah_dirakit():
		var adp := p.adapter()
		var info := Perangkat.info(adp)
		var driver := p.driver_aktif() if p.driver_aktif() != "" else Bahasa.kunci_dua("dev.belum_driver")
		var status := Bahasa.kunci_dua("dev.terhubung") if p.terhubung() else Bahasa.kunci_dua("dev.tidak_terhubung")
		s.jaringan.buka("device:detect")
		return [
			s.baris_kunci("info", "dev.detect_perangkat", [String(info["nama"]), String(info["chipset"])]),
			s.baris_kunci("info", "dev.detect_driver", [driver]),
			s.baris_kunci("info", "dev.detect_status", [status]),
		]
	var adapter := p.adapter_dimiliki()
	if not adapter.is_empty():
		var nama: Array = []
		for id in adapter:
			nama.append(String(Perangkat.info(String(id))["nama"]))
		return [s.baris_kunci("info", "dev.detect_komponen", [", ".join(PackedStringArray(nama))])]
	return [s.baris_kunci("info", "dev.detect_tidak_ada")]

static func _hubungkan(s: ShellSession) -> Array:
	return [s.hasil_ke_baris("device", hubungkan(s))]

# Menghubungkan perangkat dengan driver yang terpasang. Dipakai terminal dan Device Manager.
static func hubungkan(s: ShellSession) -> Dictionary:
	var p := s.perangkat
	var chipset := ""
	var didukung: Array = []
	var driver := ""
	if p.sudah_dirakit():
		chipset = Perangkat.chipset_adapter(p.adapter())
		driver = s.repositori.driver_untuk(chipset)
		if driver != "":
			didukung = Array(Repositori.item(driver).get("chipset", []))
	var h := p.hubungkan(driver, didukung)
	if bool(h["ok"]):
		s.jaringan.buka("device:terhubung")
	return h

static func _katalog(s: ShellSession) -> Array:
	var hasil: Array = [s.baris_kunci("info", "toko.judul")]
	for id in Perangkat.semua_id():
		var it := Perangkat.info(String(id))
		if bool(it.get("tidak_dijual", false)):
			continue
		hasil.append(s.baris("info", "  %-24s %-26s %4d Kr  %s" % [String(id), String(it["nama"]), int(it["harga"]), Bahasa.kunci_dua("toko.dimiliki", [s.perangkat.jumlah(String(id))])]))
	return hasil
