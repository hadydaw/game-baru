class_name WiresharkFilter
extends RefCounted

# Filter tampilan Wireshark: protokol (tcp, http, eapol, ...), field (ip.addr, tcp.port, ...), perbandingan
# (== != > < >= <= contains), frame contains "teks", serta and/or/not dengan tanda kurung.
# Hasil parse dipakai ulang untuk setiap paket. Field yang tidak dikenal ditolak dengan pesan galat.

const PROTOKOL := ["radiotap", "wlan", "llc", "eapol", "eth", "ip", "tcp", "udp", "dns", "http", "icmp", "arp"]
const FIELD := ["frame.len", "ip.addr", "ip.src", "ip.dst", "eth.addr",
	"tcp.port", "tcp.srcport", "tcp.dstport", "tcp.flags.syn", "tcp.flags.ack", "tcp.flags.fin", "tcp.flags.rst", "tcp.flags.psh",
	"udp.port", "udp.srcport", "udp.dstport", "icmp.type", "arp.opcode",
	"dns.qry.name", "dns.flags.response",
	"http.request.method", "http.request.uri", "http.host", "http.response.code", "http.content_type", "http.form.password",
	"wlan.bssid", "wlan.ssid", "wlan.sa", "wlan.da", "wlan.channel", "wlan.fc.type_subtype", "eapol.msg"]
const PERBANDINGAN := ["==", "!=", ">", "<", ">=", "<=", "contains", "eq", "ne"]

# Hasil: {"ok": true, "node": Dictionary} atau {"ok": false, "pesan": String}
static func parse(ekspresi: String) -> Dictionary:
	var toks := _tokenkan(ekspresi)
	if toks.is_empty():
		return {"ok": false, "pesan": Bahasa.dua("Filter kosong.", "The filter is empty.")}
	var p := {"toks": toks, "i": 0, "galat": ""}
	var node = _or(p)
	if String(p["galat"]) != "":
		return {"ok": false, "pesan": String(p["galat"])}
	if int(p["i"]) < toks.size():
		return {"ok": false, "pesan": _galat_tak_terduga(toks[p["i"]])}
	return {"ok": true, "node": node}

static func cocok(node: Dictionary, paket: Dictionary) -> bool:
	match String(node["op"]):
		"or": return cocok(node["a"], paket) or cocok(node["b"], paket)
		"and": return cocok(node["a"], paket) and cocok(node["b"], paket)
		"not": return not cocok(node["a"], paket)
		"proto": return Array(paket.get("lapisan", [])).has(String(node["nama"]))
		"frame": return _ascii(paket).contains(String(node["nilai"]))
		"ada": return _ambil(paket, String(node["field"])) != null
		"cmp": return _bandingkan(paket, node)
	return false

# Pemakaian di layar dan tshark: satu paket dicek dengan filter yang sudah diparse.
static func lolos(ekspresi: String, paket: Dictionary) -> bool:
	var r := parse(ekspresi)
	return bool(r["ok"]) and cocok(r["node"], paket)

# ---------------------------------------------------------------- tokenizer
static func _tokenkan(s: String) -> Array:
	var hasil: Array = []
	var i := 0
	while i < s.length():
		var c := s[i]
		if c == " " or c == "\t":
			i += 1
			continue
		if c == "(" or c == ")":
			hasil.append({"t": c, "v": c})
			i += 1
			continue
		if c == "\"":
			var akhir := s.find("\"", i + 1)
			if akhir == -1:
				hasil.append({"t": "galat", "v": "\""})
				break
			hasil.append({"t": "str", "v": s.substr(i + 1, akhir - i - 1)})
			i = akhir + 1
			continue
		var op := _operator_di(s, i)
		if op != "":
			hasil.append({"t": "op", "v": op})
			i += op.length()
			continue
		var j := i
		while j < s.length() and _kata_char(s[j]):
			j += 1
		if j == i:
			hasil.append({"t": "galat", "v": c})
			i += 1
			continue
		hasil.append({"t": "kata", "v": s.substr(i, j - i)})
		i = j
	return hasil

static func _operator_di(s: String, i: int) -> String:
	for op in ["&&", "||", "==", "!=", ">=", "<=", ">", "<", "!"]:
		if s.substr(i, op.length()) == op:
			return op
	return ""

static func _kata_char(c: String) -> bool:
	return c.is_valid_identifier() or c.is_valid_int() or c == "." or c == "-" or c == ":" or c == "_"

# ---------------------------------------------------------------- parser rekursif
static func _or(p: Dictionary):
	var kiri = _and(p)
	while String(p["galat"]) == "" and _kata_kunci(p, ["or", "||"]):
		var kanan = _and(p)
		kiri = {"op": "or", "a": kiri, "b": kanan}
	return kiri

static func _and(p: Dictionary):
	var kiri = _satu(p)
	while String(p["galat"]) == "" and _kata_kunci(p, ["and", "&&"]):
		var kanan = _satu(p)
		kiri = {"op": "and", "a": kiri, "b": kanan}
	return kiri

static func _satu(p: Dictionary):
	if String(p["galat"]) != "":
		return {}
	var toks: Array = p["toks"]
	var i := int(p["i"])
	if i >= toks.size():
		p["galat"] = Bahasa.dua("Filter belum lengkap.", "The filter is incomplete.")
		return {}
	var t: Dictionary = toks[i]
	if _cocok_tok(t, ["not", "!"]):
		p["i"] = i + 1
		return {"op": "not", "a": _satu(p)}
	if t["t"] == "(":
		p["i"] = i + 1
		var dalam = _or(p)
		if String(p["galat"]) != "":
			return {}
		if int(p["i"]) >= toks.size() or toks[p["i"]]["t"] != ")":
			p["galat"] = Bahasa.dua("Tanda kurung ')' tidak ditemukan.", "Missing closing parenthesis ')'.")
			return {}
		p["i"] = int(p["i"]) + 1
		return dalam
	if t["t"] != "kata":
		p["galat"] = _galat_tak_terduga(t)
		return {}
	var nama := String(t["v"])
	if nama == "frame" and i + 2 < toks.size() and _cocok_tok(toks[i + 1], ["contains"]) and toks[i + 2]["t"] in ["str", "kata"]:
		p["i"] = i + 3
		return {"op": "frame", "nilai": String(toks[i + 2]["v"])}
	if PROTOKOL.has(nama):
		p["i"] = i + 1
		return {"op": "proto", "nama": nama}
	if FIELD.has(nama):
		if i + 1 < toks.size() and toks[i + 1]["t"] in ["op", "kata"] and PERBANDINGAN.has(String(toks[i + 1]["v"])):
			if i + 2 >= toks.size() or toks[i + 2]["t"] not in ["str", "kata"]:
				p["galat"] = Bahasa.dua("Nilai untuk '%s' belum diisi." % nama, "A value for '%s' is missing." % nama)
				return {}
			p["i"] = i + 3
			var rel := String(toks[i + 1]["v"])
			return {"op": "cmp", "field": nama, "rel": _rel_normal(rel), "nilai": String(toks[i + 2]["v"])}
		p["i"] = i + 1
		return {"op": "ada", "field": nama}
	p["galat"] = Bahasa.dua("'%s' bukan protokol atau field yang dikenal." % nama, "'%s' is not a valid protocol or field." % nama)
	return {}

static func _rel_normal(r: String) -> String:
	match r:
		"eq": return "=="
		"ne": return "!="
	return r

static func _kata_kunci(p: Dictionary, daftar: Array) -> bool:
	var toks: Array = p["toks"]
	var i := int(p["i"])
	if i < toks.size() and _cocok_tok(toks[i], daftar):
		p["i"] = i + 1
		return true
	return false

static func _cocok_tok(t: Dictionary, daftar: Array) -> bool:
	return (t["t"] == "kata" or t["t"] == "op") and daftar.has(String(t["v"]))

static func _galat_tak_terduga(t: Dictionary) -> String:
	return Bahasa.dua("Token tidak terduga: '%s'." % String(t["v"]), "Unexpected token: '%s'." % String(t["v"]))

# ---------------------------------------------------------------- evaluasi
static func _ambil(paket: Dictionary, field: String) -> Variant:
	if field == "frame.len":
		return int(paket.get("panjang", 0))
	var fitur: Dictionary = paket.get("fitur", {})
	return fitur.get(field, null)

static func _bandingkan(paket: Dictionary, node: Dictionary) -> bool:
	var nilai = _ambil(paket, String(node["field"]))
	var rel := String(node["rel"])
	var lit := String(node["nilai"])
	if rel == "contains":
		if nilai == null:
			return false
		if typeof(nilai) == TYPE_ARRAY:
			for x in nilai:
				if _teks(x).contains(lit):
					return true
			return false
		return _teks(nilai).contains(lit)
	var sama := _sama(nilai, lit)
	match rel:
		"==": return sama
		"!=": return not sama
	if nilai == null or not (_teks(nilai).is_valid_float()):
		return false
	var a := float(_teks(nilai))
	var b := float(lit)
	match rel:
		">": return a > b
		"<": return a < b
		">=": return a >= b
		"<=": return a <= b
	return false

# Field daftar (mis. tcp.port berisi [asal, tujuan]) cocok bila salah satu anggotanya sama dengan nilai.
static func _sama(nilai: Variant, lit: String) -> bool:
	if nilai == null:
		return false
	if typeof(nilai) == TYPE_ARRAY:
		for x in nilai:
			if _teks(x) == lit:
				return true
		return false
	return _teks(nilai) == lit

# JSON memuat semua angka sebagai float (80 menjadi 80.0). Bilangan bulat ditampilkan tanpa desimal.
static func _teks(v: Variant) -> String:
	if typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), round(float(v))):
		return str(int(v))
	return str(v)

# Teks ASCII dari byte frame; byte di luar rentang cetak menjadi '.', sama seperti kolom ASCII Wireshark.
static func _ascii(paket: Dictionary) -> String:
	var b := WiresharkData.hex_ke_byte(String(paket.get("hex", "")))
	var s := ""
	for x in b:
		s += char(x) if x >= 32 and x < 127 else "."
	return s
