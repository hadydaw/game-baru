class_name RepositoriCommands
extends RefCounted

# Perintah Tools Repository di terminal: tools (tanpa argumen menampilkan tool dan aplikasi),
# tools search <kata>, tools info <id>, tools install <id>, tools update <id>, dan tools list.
# Pemasangan dan pembaruan dilakukan oleh Repositori; perintah ini hanya menyusun keluaran.

static func tools(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.is_empty():
		var hasil := ToolCommands.tools(s)
		hasil.append_array(_terpasang(s))
		return hasil
	var sub := String(args[0])
	match sub:
		"search":
			return _cari(s, args.slice(1))
		"info":
			if args.size() < 2:
				return [s.galat_kunci("tools", "err.butuh_argumen")]
			return _info(s, String(args[1]))
		"install":
			if args.size() < 2:
				return [s.galat_kunci("tools", "err.butuh_argumen")]
			var h := s.repositori.pasang(String(args[1]), s.economy, s.perangkat)
			if bool(h["ok"]):
				s.jaringan.buka("pasang:" + String(args[1]))
			return [s.hasil_ke_baris("tools", h)]
		"update":
			if args.size() < 2:
				return [s.galat_kunci("tools", "err.butuh_argumen")]
			return [s.hasil_ke_baris("tools", s.repositori.perbarui(String(args[1])))]
		"list":
			return _terpasang(s)
	return [s.galat_kunci("tools", "repo.usage")]

static func _cari(s: ShellSession, kata: Array) -> Array:
	var k := " ".join(PackedStringArray(kata))
	var ids := Repositori.cari(k)
	if ids.is_empty():
		return [s.baris_kunci("info", "repo.tidak_cocok", [k])]
	var hasil: Array = []
	for id in ids:
		hasil.append(s.baris("info", _baris_ringkas(s, String(id))))
	return hasil

static func _baris_ringkas(s: ShellSession, id: String) -> String:
	var it := Repositori.item(id)
	return "  %-18s %-7s %-22s %s" % [id, String(it["versi"]), _status(s, id), String(it["nama"])]

static func _info(s: ShellSession, id: String) -> Array:
	var it := Repositori.item(id)
	if it.is_empty():
		return [s.galat_kunci("tools", "sw.tidak_ada", [id])]
	var deps: Array = it.get("deps", [])
	var hw := Bahasa.kunci_dua("repo.hw_adapter") if bool(it.get("butuh_adapter", false)) else Bahasa.kunci_dua("repo.hw_tidak")
	var riwayat := s.repositori.riwayat(id)
	var riwayat_teks := ", ".join(PackedStringArray(riwayat)) if not riwayat.is_empty() else Bahasa.kunci_dua("repo.belum_dipasang")
	var tipe := Bahasa.kunci_dua("repo.tipe." + String(it["tipe"]))
	var dep_teks := ", ".join(PackedStringArray(deps)) if not deps.is_empty() else Bahasa.kunci_dua("repo.tidak_ada")
	var hasil: Array = [
		s.baris_kunci("info", "repo.info_nama", [String(it["nama"]), id]),
		s.baris_kunci("info", "repo.info_tipe", [tipe, String(it["kategori"])]),
		s.baris_kunci("info", "repo.info_versi", [String(it["versi"]), String(it["ukuran"])]),
		s.baris_kunci("info", "repo.info_terpasang", [s.repositori.versi(id) if s.repositori.punya(id) else Bahasa.kunci_dua("repo.belum_dipasang")]),
		s.baris_kunci("info", "repo.info_harga", [int(it["harga"])]),
		s.baris_kunci("info", "repo.info_deps", [dep_teks]),
		s.baris_kunci("info", "repo.info_hw", [hw]),
		s.baris_kunci("info", "repo.info_status", [_status(s, id)]),
		s.baris_kunci("info", "repo.info_riwayat", [riwayat_teks]),
		s.baris_kunci("info", String(it["deskripsi_kunci"])),
	]
	return hasil

static func _terpasang(s: ShellSession) -> Array:
	var ids := s.repositori.terpasang.keys()
	ids.sort()
	var hasil: Array = [s.baris_kunci("info", "repo.judul_terpasang")]
	if ids.is_empty():
		hasil.append(s.baris_kunci("info", "repo.list_kosong"))
		return hasil
	for id in ids:
		hasil.append(s.baris("info", "  %-18s v%s  %s" % [String(id), s.repositori.versi(String(id)), String(Repositori.item(String(id))["nama"])]))
	return hasil

# Status untuk tampilan: terpasang, terpasang dengan pembaruan, atau tersedia.
static func _status(s: ShellSession, id: String) -> String:
	if not s.repositori.punya(id):
		return Bahasa.kunci_dua("repo.st_tersedia")
	if s.repositori.versi(id) != String(Repositori.item(id)["versi"]):
		return Bahasa.kunci_dua("repo.st_perlu_update")
	return Bahasa.kunci_dua("repo.st_terpasang")
