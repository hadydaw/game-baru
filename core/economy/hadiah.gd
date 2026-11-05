class_name Hadiah
extends RefCounted

# Menyelesaikan misi: menandai flag, memberi hadiah (sekali per flag), dan mengevaluasi unlock.
# Misi nyata dipasang pada tahap berikutnya; sampai saat itu fungsi ini dipanggil oleh tes.

const DATA := "res://data/economy/hadiah.json"

# Berkas sumber hadiah. Tes dapat mengarahkannya ke fixture; permainan memakai DATA.
static var berkas: String = DATA

static func data(path: String = "") -> Dictionary:
	var sumber := path if path != "" else berkas
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(sumber)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

static func selesaikan_misi(s: ShellSession, flag: String) -> Dictionary:
	s.jaringan.buka(flag)
	var hasil := {"hadiah": false, "tool_diberi": [], "unlock": []}
	var h: Dictionary = data().get(flag, {})
	if not h.is_empty() and not s.hadiah_diambil.has(flag):
		hasil["hadiah"] = true
		s.hadiah_diambil.append(flag)
		s.economy.tambah(int(h.get("kredit", 0)))
		var rep: Dictionary = h.get("reputasi", {})
		for g in rep:
			s.reputation.ubah(String(g), int(rep[g]))
		if bool(h.get("pulihkan_pasar", false)):
			s.market.pulihkan_untuk_flag(flag)
		for k in h.get("kontak", []):
			s.jaringan.buka("kontak:" + String(k))
		var tool: Dictionary = h.get("tool", {})
		if not tool.is_empty():
			var id := String(tool["id"])
			var tgt := int(tool.get("tingkat", 1))
			if s.inventory.punya(id):
				s.inventory.setel_tingkat(id, tgt)
			else:
				s.inventory.miliki(id, "misi", tgt)
			hasil["tool_diberi"].append(id)
	hasil["unlock"] = UnlockRules.evaluasi(s)
	return hasil
