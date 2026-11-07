class_name Inventory
extends RefCounted

# Tool yang dimiliki pemain beserta tingkat dan sumbernya (awal, black_market, misi, dan seterusnya).
# Hanya tool yang dimiliki yang disimpan; tool lain dianggap belum dimiliki (terkunci).
# Tool tidak bisa dimiliki dua kali. Peningkatan tingkat lewat naikkan().

var milik: Dictionary = {}  # id -> {"tingkat": int, "sumber": String}

# Keadaan awal pemain: tanpa alat. Perintah dasar (ping, ip) tetap tersedia karena tidak dikunci oleh
# tool. Nmap harus dipasang lewat apt; alat didapat lewat misi dan pasar.
static func baru() -> Inventory:
	return Inventory.new()

func punya(id: String) -> bool:
	return milik.has(id)

func tingkat(id: String) -> int:
	return int(Dictionary(milik.get(id, {})).get("tingkat", 0))

func sumber(id: String) -> String:
	return String(Dictionary(milik.get(id, {})).get("sumber", ""))

func miliki(id: String, dari: String, tingkat_awal: int = 1) -> bool:
	if not ToolDefs.ada(id) or punya(id):
		return false
	milik[id] = {"tingkat": clampi(tingkat_awal, 1, ToolDefs.maks(id)), "sumber": dari}
	return true

# Mengatur tingkat tool yang sudah dimiliki. Hanya naik, dan tidak melewati batas maksimal.
func setel_tingkat(id: String, t: int) -> bool:
	if not punya(id) or t <= tingkat(id) or t > ToolDefs.maks(id):
		return false
	milik[id]["tingkat"] = t
	return true

func naikkan(id: String) -> bool:
	if not punya(id) or tingkat(id) >= ToolDefs.maks(id):
		return false
	milik[id]["tingkat"] = tingkat(id) + 1
	return true

# Semua nama perintah yang aktif dari tool yang dimiliki, sudah diurutkan.
func perintah_aktif() -> Array:
	var hasil: Array = []
	for id in milik:
		for c in ToolDefs.perintah(String(id)):
			hasil.append(String(c))
	hasil.sort()
	return hasil

func to_dict() -> Dictionary:
	return {"milik": milik.duplicate(true)}

func terapkan(d: Dictionary) -> void:
	milik = {}
	var tersimpan: Dictionary = d.get("milik", {})
	for id in tersimpan:
		if ToolDefs.ada(String(id)):
			var e: Dictionary = tersimpan[id]
			milik[String(id)] = {
				"tingkat": clampi(int(e.get("tingkat", 1)), 1, ToolDefs.maks(String(id))),
				"sumber": String(e.get("sumber", "")),
			}
