class_name AptCommands
extends RefCounted

# Simulasi APT (Advanced Package Tool) di Kali Linux: install, remove, purge, autoremove, upgrade,
# update, list, search, dan show. Keadaan paket dan saldo dikelola lewat Repositori, sehingga
# dependensi, penandaan paket otomatis, dan biaya benar-benar memengaruhi permainan.
# Keluaran memakai bahasa Inggris seperti apt asli dan tidak mencampur bahasa.

const SUMBER := "http://http.kali.org/kali"
const RILIS := "kali-rolling"
const ARSITEKTUR := "amd64"

static func jalankan(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	var opsi: Array = p["opsi"]
	if args.is_empty():
		return _pakai()
	for o in opsi:
		if not ["-y", "--yes", "--assume-yes", "--installed", "--upgradable"].has(String(o)):
			return [_err("E: Command line option '%s' is not understood" % String(o).trim_prefix("--").trim_prefix("-"))]
	var yes := opsi.has("-y") or opsi.has("--yes") or opsi.has("--assume-yes")
	var sub := String(args[0])
	var paket: Array = args.slice(1)
	match sub:
		"update":
			return _update(s)
		"upgrade":
			return _upgrade(s, yes)
		"install":
			return _install(s, paket, yes)
		"remove":
			return _hapus(s, paket, yes, false)
		"purge":
			return _hapus(s, paket, yes, true)
		"autoremove":
			return _autoremove(s, yes)
		"list":
			return _list(s, opsi)
		"search":
			return _search(s, paket)
		"show":
			return _show(s, paket)
	return [_err("E: Invalid operation %s" % sub)]

static func _pakai() -> Array:
	return [
		_info("Usage: apt [options] command"),
		_info(""),
		_info("Most used commands:"),
		_info("  update - Update list of available packages"),
		_info("  upgrade - Upgrade the system by installing/upgrading packages"),
		_info("  install - Install packages"),
		_info("  remove - Remove packages"),
		_info("  purge - Remove packages and config files"),
		_info("  autoremove - Remove automatically installed packages no longer needed"),
		_info("  search - Search for packages"),
		_info("  show - Show package details"),
		_info("  list - List packages based on package names"),
	]

# update: membaca daftar paket dari repositori. Tidak mengubah paket yang terpasang.
static func _update(s: ShellSession) -> Array:
	var hasil: Array = [_info("Hit:1 %s %s InRelease" % [SUMBER, RILIS])]
	hasil.append_array(_header())
	var n := _upgradable(s).size()
	if n > 0:
		hasil.append(_info("%d packages can be upgraded. Run 'apt list --upgradable' to see them." % n))
	else:
		hasil.append(_info("All packages are up to date."))
	return hasil

static func _upgrade(s: ShellSession, yes: bool) -> Array:
	var lines := _header()
	var daftar := _upgradable(s)
	if daftar.is_empty():
		lines.append(_info("Calculating upgrade... Done"))
		lines.append(_info("0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."))
		return lines
	var nama: Array = []
	var kb := 0.0
	for id in daftar:
		nama.append(String(id))
		kb += _kb(String(Repositori.item(String(id))["ukuran"]))
	lines.append(_info("Calculating upgrade... Done"))
	lines.append(_info("The following packages will be upgraded:"))
	lines.append(_info("  " + " ".join(PackedStringArray(nama))))
	lines.append(_info("%d upgraded, 0 newly installed, 0 to remove and 0 not upgraded." % daftar.size()))
	lines.append(_info("Need to get %s of archives." % _ukuran_tampil(kb)))
	return _konfirmasi(s, lines, Callable(AptCommands, "_jalankan_upgrade").bind(s, daftar), yes)

static func _jalankan_upgrade(s: ShellSession, daftar: Array) -> Array:
	var hasil: Array = []
	for id in daftar:
		var lama := s.repositori.versi(String(id))
		var h := s.repositori.perbarui(String(id))
		if not bool(h["ok"]):
			continue
		var baru := s.repositori.versi(String(id))
		hasil.append(_info("Preparing to unpack .../%s_%s_%s.deb ..." % [id, baru, ARSITEKTUR]))
		hasil.append(_info("Unpacking %s (%s) over (%s) ..." % [id, baru, lama]))
		hasil.append(_info("Setting up %s (%s) ..." % [id, baru]))
	return hasil

# install: menyelesaikan dependensi dulu, menampilkan rencana, lalu memasang setelah konfirmasi.
static func _install(s: ShellSession, paket: Array, yes: bool) -> Array:
	if paket.is_empty():
		return [_info("0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.")]
	var lines := _header()
	var rencana: Array = []
	var diminta: Array = []
	for nama in paket:
		var id := String(nama)
		if Repositori.item(id).is_empty():
			return [_err("E: Unable to locate package %s" % id)]
		if s.repositori.punya(id):
			lines.append(_info("%s is already the newest version (%s)." % [id, s.repositori.versi(id)]))
		else:
			diminta.append(id)
			s.repositori.rencana_pasang(id, rencana)
	if rencana.is_empty():
		lines.append(_info("0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."))
		return lines
	var tambahan: Array = []
	for id in rencana:
		if not diminta.has(id):
			tambahan.append(String(id))
	var harga := 0
	var kb := 0.0
	for id in rencana:
		var it := Repositori.item(String(id))
		harga += int(it["harga"])
		kb += _kb(String(it["ukuran"]))
		if bool(it.get("butuh_adapter", false)) and not s.perangkat.sudah_dirakit() and s.perangkat.adapter_dimiliki().is_empty():
			return [_err("E: Package %s requires a Wi-Fi adapter, which is not installed" % String(it["nama"]))]
	if not s.economy.bisa_bayar(harga):
		return [_err("E: Not enough credits: need %d Kr, have %d Kr" % [harga, s.economy.saldo])]
	if not tambahan.is_empty():
		lines.append(_info("The following additional packages will be installed:"))
		lines.append(_info("  " + " ".join(PackedStringArray(tambahan))))
	lines.append(_info("The following NEW packages will be installed:"))
	lines.append(_info("  " + " ".join(PackedStringArray(rencana))))
	lines.append(_info("0 upgraded, %d newly installed, 0 to remove and 0 not upgraded." % rencana.size()))
	lines.append(_info("Need to get %s of archives." % _ukuran_tampil(kb)))
	lines.append(_info("After this operation, %s of additional disk space will be used." % _ukuran_tampil(kb)))
	lines.append(_info("Credits required: %d Kr (balance: %d Kr)" % [harga, s.economy.saldo]))
	return _konfirmasi(s, lines, Callable(AptCommands, "_jalankan_install").bind(s, rencana, diminta), yes)

static func _jalankan_install(s: ShellSession, rencana: Array, diminta: Array) -> Array:
	var hasil: Array = []
	for id in rencana:
		var nama := String(id)
		var h := s.repositori.pasang(nama, s.economy, s.perangkat, not diminta.has(nama))
		if not bool(h["ok"]):
			hasil.append(_err("E: Failed to install %s" % nama))
			break
		var v := s.repositori.versi(nama)
		hasil.append(_info("Selecting previously unselected package %s." % nama))
		hasil.append(_info("Unpacking %s (%s) ..." % [nama, v]))
		hasil.append(_info("Setting up %s (%s) ..." % [nama, v]))
		s.jaringan.buka("pasang:" + nama)
	return hasil

# remove dan purge: paket yang bergantung pada target ikut dihapus, seperti di apt asli.
static func _hapus(s: ShellSession, paket: Array, yes: bool, purge: bool) -> Array:
	if paket.is_empty():
		return [_info("0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.")]
	var target: Array = []
	for nama in paket:
		var id := String(nama)
		if Repositori.item(id).is_empty() and not (purge and s.repositori.punya_konfig(id)):
			return [_err("E: Unable to locate package %s" % id)]
		if not s.repositori.punya(id) and not (purge and s.repositori.punya_konfig(id)):
			return [_err("E: Package '%s' is not installed, so not removed" % id)]
		if not target.has(id):
			target.append(id)
		for d in s.repositori.dependen(id):
			if not target.has(d):
				target.append(d)
	var lines := _header()
	lines.append(_info("The following packages will be REMOVED:"))
	lines.append(_info("  " + " ".join(PackedStringArray(target))))
	lines.append(_info("0 upgraded, 0 newly installed, %d to remove and 0 not upgraded." % target.size()))
	return _konfirmasi(s, lines, Callable(AptCommands, "_jalankan_hapus").bind(s, target, purge), yes)

static func _jalankan_hapus(s: ShellSession, target: Array, purge: bool) -> Array:
	var hasil: Array = []
	for id in target:
		var nama := String(id)
		if s.repositori.punya(nama):
			var v := s.repositori.versi(nama)
			s.repositori.hapus(nama, purge)
			hasil.append(_info("Removing %s (%s) ..." % [nama, v]))
		if purge:
			s.repositori.bersihkan_konfig(nama)
			hasil.append(_info("Purging configuration files for %s ..." % nama))
	var sisa := s.repositori.kandidat_autoremove()
	if not sisa.is_empty():
		hasil.append(_info("The following packages were automatically installed and are no longer required:"))
		hasil.append(_info("  " + " ".join(PackedStringArray(sisa))))
		hasil.append(_info("Use 'apt autoremove' to remove them."))
	return hasil

static func _autoremove(s: ShellSession, yes: bool) -> Array:
	var daftar := s.repositori.kandidat_autoremove()
	var lines := _header()
	if daftar.is_empty():
		lines.append(_info("0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."))
		return lines
	lines.append(_info("The following packages will be REMOVED:"))
	lines.append(_info("  " + " ".join(PackedStringArray(daftar))))
	lines.append(_info("0 upgraded, 0 newly installed, %d to remove and 0 not upgraded." % daftar.size()))
	return _konfirmasi(s, lines, Callable(AptCommands, "_jalankan_hapus").bind(s, daftar, false), yes)

# list: daftar paket. --installed dan --upgradable menyaring hasil.
static func _list(s: ShellSession, opsi: Array) -> Array:
	s.jaringan.buka("apt:list")
	var hasil: Array = [_info("WARNING: apt does not have a stable CLI interface. Use with caution in scripts."), _info("Listing... Done")]
	if opsi.has("--upgradable"):
		for id in _upgradable(s):
			var nama := String(id)
			hasil.append(_info("%s/%s %s %s [upgradable from: %s]" % [nama, RILIS, Repositori.item(nama)["versi"], ARSITEKTUR, s.repositori.versi(nama)]))
		return hasil
	for id in Repositori.semua_id():
		var nama := String(id)
		var terpasang := s.repositori.punya(nama)
		if opsi.has("--installed") and not terpasang:
			continue
		var v := String(Repositori.item(nama)["versi"]) if not terpasang else s.repositori.versi(nama)
		if terpasang:
			var tanda := "installed,automatic" if s.repositori.auto(nama) else "installed"
			hasil.append(_info("%s/%s,now %s %s [%s]" % [nama, RILIS, v, ARSITEKTUR, tanda]))
		else:
			hasil.append(_info("%s/%s %s %s" % [nama, RILIS, v, ARSITEKTUR]))
	return hasil

# search: mencari paket berdasarkan nama, kategori, atau deskripsi (bahasa Inggris).
static func _search(s: ShellSession, kata: Array) -> Array:
	var hasil: Array = [_info("Sorting... Done"), _info("Full Text Search... Done")]
	var kueri := " ".join(PackedStringArray(kata)).to_lower()
	if kueri != "":
		s.jaringan.buka("cari:" + kueri)
	for id in Repositori.semua_id():
		var nama := String(id)
		var it := Repositori.item(nama)
		var deskripsi := _deskripsi_en(nama)
		var teks := (nama + " " + String(it["nama"]) + " " + String(it["kategori"]) + " " + deskripsi).to_lower()
		if kueri != "" and not teks.contains(kueri):
			continue
		var tanda := ""
		if s.repositori.punya(nama):
			tanda = " [installed]" if s.repositori.versi(nama) == String(it["versi"]) else " [installed,upgradable to: %s]" % it["versi"]
		hasil.append(_info("%s/%s %s %s%s" % [nama, RILIS, it["versi"], ARSITEKTUR, tanda]))
		hasil.append(_info("  " + deskripsi))
	return hasil

# show: detail satu paket. Paket yang tidak ada menghasilkan galat seperti apt asli.
static func _show(s: ShellSession, paket: Array) -> Array:
	var hasil: Array = []
	for nama in paket:
		var id := String(nama)
		var it := Repositori.item(id)
		if it.is_empty():
			hasil.append(_err("E: No packages found"))
			continue
		if not hasil.is_empty():
			hasil.append(_info(""))
		hasil.append(_info("Package: %s" % id))
		hasil.append(_info("Version: %s" % it["versi"]))
		hasil.append(_info("Priority: optional"))
		hasil.append(_info("Section: %s" % _bagian_en(String(it["kategori"]))))
		hasil.append(_info("Installed-Size: %s" % it["ukuran"]))
		var deps: Array = it.get("deps", [])
		if not deps.is_empty():
			hasil.append(_info("Depends: %s" % ", ".join(PackedStringArray(deps))))
		hasil.append(_info("Description: %s" % _deskripsi_en(id)))
	return hasil

# Paket terpasang yang versinya lebih lama dari katalog.
static func _upgradable(s: ShellSession) -> Array:
	var hasil: Array = []
	for id in Repositori.semua_id():
		var nama := String(id)
		if s.repositori.punya(nama) and s.repositori.versi(nama) != String(Repositori.item(nama)["versi"]):
			hasil.append(nama)
	return hasil

# Konfirmasi seperti apt: tanpa -y, terminal menunggu jawaban Y/n pada baris berikutnya.
static func _konfirmasi(s: ShellSession, lines: Array, aksi: Callable, yes: bool) -> Array:
	if yes:
		var langsung: Array = aksi.call()
		return lines + langsung
	lines.append(_info("Do you want to continue? [Y/n] "))
	s.konfirmasi_tertunda = Callable(AptCommands, "_jawab").bind(s, aksi)
	return lines

# Argumen dari bind() ditambahkan di belakang, jadi masukan pengguna menjadi parameter pertama.
static func _jawab(masukan: String, s: ShellSession, aksi: Callable) -> Array:
	var j := masukan.strip_edges().to_lower()
	if j == "" or j == "y" or j == "yes":
		var hasil: Array = aksi.call()
		return hasil
	# Bukan jawaban Y/n: apt membatalkan, lalu baris itu dijalankan sebagai perintah biasa.
	var batal := [_err("Abort.")]
	if j == "n" or j == "no":
		return batal
	return batal + s.jalankan(masukan)

static func _header() -> Array:
	return [
		_info("Reading package lists... Done"),
		_info("Building dependency tree... Done"),
		_info("Reading state information... Done"),
	]

# Kategori katalog disimpan dalam bahasa Indonesia; apt menampilkan nama bagian dalam bahasa Inggris.
static func _bagian_en(kategori: String) -> String:
	var peta := {"Nirkabel": "net", "Analisis": "utils", "Autentikasi": "admin", "Driver": "kernel"}
	return String(peta.get(kategori, "misc"))

static func _deskripsi_en(id: String) -> String:
	var it := Repositori.item(id)
	var kunci := String(it.get("deskripsi_kunci", ""))
	var entri: Dictionary = Bahasa.KAMUS.get(kunci, {})
	return String(entri.get("en", kunci))

# Mengubah ukuran katalog seperti "3.4 MB" atau "512 kB" menjadi kilobita.
static func _kb(ukuran: String) -> float:
	var bagian := ukuran.strip_edges().split(" ")
	if bagian.is_empty():
		return 0.0
	var angka := float(bagian[0])
	var satuan := String(bagian[1]).to_upper() if bagian.size() > 1 else "KB"
	match satuan:
		"MB":
			return angka * 1024.0
		"GB":
			return angka * 1024.0 * 1024.0
		_:
			return angka

static func _ukuran_tampil(kb: float) -> String:
	if kb >= 1024.0:
		return "%.1f MB" % (kb / 1024.0)
	return "%d kB" % int(round(kb))

static func _info(teks: String) -> Dictionary:
	return {"tipe": "info", "teks": teks}

static func _err(teks: String) -> Dictionary:
	return {"tipe": "error", "teks": teks}
