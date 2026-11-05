class_name UnlockRules
extends RefCounted

# Evaluasi jalur unlock tool. Aturan dibaca dari data/economy/unlock.json.
# Jalur: misi, penemuan, hadiah_kontak (berbasis flag di Jaringan.progres) dan grup (berbasis reputasi).
# Jalur black_market tidak perlu aturan: pembelian sendiri yang membuka tool.

const DATA := "res://data/economy/unlock.json"

static func aturan(path: String = DATA) -> Array:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_ARRAY:
		return []
	return parser.data

# Memberi tool yang syaratnya sudah terpenuhi dan belum dimiliki pada tingkat itu.
# Mengembalikan daftar id tool yang baru diberikan.
static func evaluasi(s: ShellSession) -> Array:
	var diberi: Array = []
	for a in aturan():
		var tool := String(a["tool"])
		var tgt := int(a.get("tingkat", 1))
		if s.inventory.tingkat(tool) >= tgt or not _terpenuhi(s, a):
			continue
		if s.inventory.punya(tool):
			s.inventory.setel_tingkat(tool, tgt)
		else:
			s.inventory.miliki(tool, String(a["jalur"]), tgt)
		diberi.append(tool)
	return diberi

static func _terpenuhi(s: ShellSession, a: Dictionary) -> bool:
	if String(a["jalur"]) == "grup":
		return s.reputation.get_nilai(String(a.get("grup", "kolektif_senja"))) >= int(a.get("reputasi", 0))
	return s.jaringan.progres.has(String(a.get("flag", "")))
