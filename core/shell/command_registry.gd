class_name CommandRegistry
extends RefCounted

# Menentukan perintah mana yang tersedia. Perintah milik tool hanya ada jika tool itu dimiliki.
# Perintah tanpa pemilik (ls, cd, ping, dan lainnya) selalu tersedia.

static func pemilik(nama: String) -> String:
	for id in ToolDefs.DEFS:
		if ToolDefs.perintah(String(id)).has(nama):
			return String(id)
	return ""

# Perintah tool memerlukan tool itu; perintah aplikasi repositori memerlukan aplikasi terpasang.
static func tersedia(s: ShellSession, nama: String) -> bool:
	var p := pemilik(nama)
	if p != "":
		return s.inventory.punya(p)
	var sw := Repositori.pemilik_perintah(nama)
	if sw != "":
		return s.repositori.punya(sw)
	return true
