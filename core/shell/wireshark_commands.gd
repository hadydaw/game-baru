class_name WiresharkCommands
extends RefCounted

# Perintah Wireshark: wireshark (membuka aplikasi grafis) dan tshark (keluaran teks). Keduanya membaca
# paket simulasi dari berkas .simcap atau contoh di /usr/share/wireshark/samples/. Capture hanya memutar
# skenario lab; tidak ada lalu lintas jaringan sungguhan. Versi dan kolom mengikuti Wireshark 4.6.
# Tidak disimulasikan: dumpcap, capinfos, editcap, berkas pcap/pcapng asli, dan penyaringan IP per antarmuka.

const VERSI := "4.6.6"
const NILAI_OPSI := ["-r", "-i", "-Y", "-c", "-z", "-w"]

# Versi yang tampil mengikuti paket yang terpasang (bisa berbeda setelah apt upgrade).
static func _versi(s: ShellSession, paket: String) -> String:
	return s.repositori.versi(paket) if s.repositori.punya(paket) else VERSI

static func _info(teks: String) -> Dictionary:
	return {"tipe": "info", "teks": teks}

static func _galat(teks: String) -> Dictionary:
	return {"tipe": "error", "teks": teks}

# Membaca opsi dengan nilainya dari teks mentah, karena parser memisahkan opsi dan argumen dan
# kehilangan urutannya. Mengembalikan {"bendera": Array, "nilai": Dictionary, "posisi": Array}.
static func urai_opsi(mentah: String) -> Dictionary:
	var token := ShellParser.tokenkan(mentah)
	var bendera: Array = []
	var nilai := {}
	var posisi: Array = []
	var i := 1
	while i < token.size():
		var t := String(token[i])
		if NILAI_OPSI.has(t) and i + 1 < token.size():
			nilai[t] = String(token[i + 1])
			i += 2
			continue
		if t.begins_with("-") and t.length() > 1:
			bendera.append(t)
		else:
			posisi.append(t)
		i += 1
	return {"bendera": bendera, "nilai": nilai, "posisi": posisi}

# Membaca berkas .simcap atau contoh lab. Mengembalikan {"ok", "galat", "judul", "antarmuka", "paket"}.
static func baca_berkas(s: ShellSession, path: String) -> Dictionary:
	var abs := Vfs.normalisasi(s.cwd, path, s.home)
	var id := WiresharkData.id_contoh_dari_path(abs)
	if id != "":
		var d := WiresharkData.muat_contoh(id)
		if d.is_empty():
			return {"ok": false, "galat": "corrupt", "nama": path}
		return {"ok": true, "judul": id, "antarmuka": String(d.get("antarmuka", "")), "paket": d["paket"]}
	var node := s.fs.ambil(abs)
	if node.is_empty():
		return {"ok": false, "galat": "No such file or directory", "nama": path}
	if String(node.get("tipe", "")) == "dir":
		return {"ok": false, "galat": "Is a directory", "nama": path}
	if not Permissions.boleh(node, s.user, s.grup, "r"):
		return {"ok": false, "galat": "Permission denied", "nama": path}
	var r := WiresharkData.urai(ShellCommands.isi_berkas(node))
	if not bool(r["ok"]):
		return {"ok": false, "galat": "corrupt", "nama": path}
	return {"ok": true, "judul": s.fs.nama_terakhir(abs), "antarmuka": String(r["antarmuka"]), "paket": r["paket"]}

static func wireshark(s: ShellSession, p: Dictionary) -> Array:
	var o := urai_opsi(String(p.get("mentah", "")))
	var bendera: Array = o["bendera"]
	if bendera.has("-v") or bendera.has("--version"):
		return [_info("Wireshark %s (simulasi)" % _versi(s, "wireshark"))]
	var berkas := String(o["nilai"].get("-r", ""))
	if berkas == "" and not (o["posisi"] as Array).is_empty():
		berkas = String(o["posisi"][0])
	if berkas != "":
		var r := baca_berkas(s, berkas)
		if not bool(r["ok"]):
			return [_galat(_pesan_baca_wireshark(r))]
		s.wireshark_perintah = {"judul": String(r["judul"]), "antarmuka": String(r["antarmuka"]), "paket": r["paket"]}
	elif o["nilai"].has("-i"):
		var iface := String(o["nilai"]["-i"])
		if not WiresharkModel.antarmuka_tersedia(s.wifi.monitor).has(iface):
			return [_galat('The capture session could not be initiated on capture device "%s" (No such device exists).' % iface)]
		s.wireshark_perintah = {"tangkap": iface}
	s.permintaan_aplikasi = "wireshark"
	return []

static func _pesan_baca_wireshark(r: Dictionary) -> String:
	var nama := String(r["nama"])
	match String(r["galat"]):
		"corrupt":
			return 'The file "%s" appears to be damaged or corrupt.' % nama
	return '"%s" cannot be opened: %s.' % [nama, String(r["galat"])]

static func tshark(s: ShellSession, p: Dictionary) -> Array:
	var o := urai_opsi(String(p.get("mentah", "")))
	var bendera: Array = o["bendera"]
	var nilai: Dictionary = o["nilai"]
	if bendera.has("-v") or bendera.has("--version"):
		return [_info("TShark (Wireshark) %s (simulasi)" % _versi(s, "tshark"))]
	if bendera.has("-D"):
		var hasil: Array = []
		var no := 1
		for iface in WiresharkModel.antarmuka_tersedia(s.wifi.monitor):
			hasil.append(_info("%d. %s" % [no, iface]))
			no += 1
		return hasil
	var judul := ""
	var paket_sumber: Array = []
	var hasil_awal: Array = []
	if nilai.has("-r"):
		var r := baca_berkas(s, String(nilai["-r"]))
		if not bool(r["ok"]):
			return [_galat("tshark: Can't open %s: %s" % [String(r["nama"]), String(r["galat"])])]
		judul = String(r["judul"])
		paket_sumber = r["paket"]
	else:
		var iface := String(nilai.get("-i", "eth0"))
		if not WiresharkModel.antarmuka_tersedia(s.wifi.monitor).has(iface):
			return [_galat('tshark: The capture session could not be initiated on capture device "%s" (No such device exists).' % iface)]
		var skenario := WiresharkModel.skenario_untuk(iface, s.wifi.monitor)
		var d := WiresharkData.muat_contoh(skenario)
		paket_sumber = d.get("paket", [])
		judul = iface
		hasil_awal.append(_info("Capturing on '%s'" % iface))
	var filter := _filter_dari(o)
	var q := WiresharkFilter.parse(filter) if filter != "" else {"ok": true, "node": {}}
	if not bool(q["ok"]):
		return [_galat("tshark: %s" % Bahasa.pilih(String(q["pesan"])))]
	var batas := int(nilai.get("-c", "-1")) if String(nilai.get("-c", "-1")).is_valid_int() else -1
	var tampil: Array = []
	for pk in paket_sumber:
		if filter != "" and not WiresharkFilter.cocok(q["node"], pk):
			continue
		tampil.append(pk)
		if batas > 0 and tampil.size() >= batas:
			break
	var hasil: Array = hasil_awal
	if not bendera.has("-q"):
		for pk in tampil:
			hasil.append(_info(baris_paket(pk)))
	if nilai.has("-i"):
		hasil.append(_info("%d packets captured" % tampil.size()))
	for z in _nilai_z(o):
		hasil += _statistik(z, tampil, filter)
	return hasil

static func _filter_dari(o: Dictionary) -> String:
	return String(o["nilai"].get("-Y", ""))

# Satu nilai -z per perintah (urai_opsi menyimpan nilai terakhir bila diulang).
static func _nilai_z(o: Dictionary) -> Array:
	var z := String(o["nilai"].get("-z", ""))
	return [] if z == "" else [z]

static func _statistik(z: String, tampil: Array, filter: String) -> Array:
	var rapi := "".lpad(80, "=")
	var filter_teks := filter if filter != "" else "<No Filter>"
	match z:
		"io,phs":
			var hasil: Array = [_info(rapi), _info("Protocol Hierarchy Statistics"), _info("Filter: %s" % filter_teks)]
			for baris in WiresharkStats.hierarki(tampil):
				var kedalaman := int(baris["kedalaman"])
				var nama := "".lpad(2 * kedalaman, " ") + String(baris["nama"])
				hasil.append(_info("%s  frames:%d bytes:%d" % [nama.rpad(40), int(baris["paket"]), int(baris["bytes"])]))
			hasil.append(_info(rapi))
			return hasil
		"conv,ip":
			var hasil: Array = [_info(rapi), _info("IPv4 Conversations"), _info("Filter: %s" % filter_teks), _info(rapi)]
			hasil.append(_info("| %-18s | %-18s | %7s | %8s |" % ["Address A", "Address B", "Packets", "Bytes"]))
			for k in WiresharkStats.percakapan(tampil):
				var a := String(k["a"])
				var b := String(k["b"])
				if a.count(".") != 3 or b.count(".") != 3:
					continue
				hasil.append(_info("| %-18s | %-18s | %7d | %8d |" % [a, b, int(k["paket"]), int(k["bytes"])]))
			hasil.append(_info(rapi))
			return hasil
	return [_galat("tshark: Invalid -z argument \"%s\"" % z)]

# Satu baris keluaran tshark: No., waktu, sumber, tujuan, protokol, panjang, dan info.
static func baris_paket(pk: Dictionary) -> String:
	var no := str(int(pk.get("no", 0))).lpad(5, " ")
	var waktu := "%.6f" % float(pk.get("waktu", 0.0))
	var sumber := String(pk.get("sumber", "")).rpad(20)
	var tujuan := String(pk.get("tujuan", "")).rpad(20)
	var proto := String(pk.get("protokol", "")).rpad(8)
	var panjang := str(int(pk.get("panjang", 0))).lpad(5, " ")
	return "%s %s %s → %s %s %s %s" % [no, waktu.lpad(12, " "), sumber, tujuan, proto, panjang, String(pk.get("info", ""))]
