class_name CommandRegistry
extends RefCounted

# Menentukan perintah mana yang tersedia. Perintah milik tool hanya ada jika tool itu dimiliki.
# Perintah tanpa pemilik (ls, cd, ping, dan lainnya) selalu tersedia.

static func pemilik(nama: String) -> String:
	for id in ToolDefs.DEFS:
		if ToolDefs.perintah(String(id)).has(nama):
			return String(id)
	return ""

static func tersedia(inv: Inventory, nama: String) -> bool:
	var p := pemilik(nama)
	return p == "" or inv.punya(p)
