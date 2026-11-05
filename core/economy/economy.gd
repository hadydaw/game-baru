class_name Economy
extends RefCounted

# Saldo kredit pemain (Kr). Saldo tidak pernah negatif: pembelian yang melebihi saldo ditolak
# dan saldo tidak berubah. Nilai awal dibaca dari data/economy/ekonomi.json.

const DATA := "res://data/economy/ekonomi.json"

var saldo: int = 0

func _init(p_saldo: int = 0) -> void:
	saldo = maxi(p_saldo, 0)

static func baru() -> Economy:
	return Economy.new(int(Economy.data_ekonomi().get("saldo_awal", 0)))

static func data_ekonomi(path: String = DATA) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return parser.data

func bisa_bayar(harga: int) -> bool:
	return harga >= 0 and harga <= saldo

# Mengurangi saldo bila mencukupi. Mengembalikan false tanpa mengubah saldo bila tidak cukup.
func bayar(harga: int) -> bool:
	if not bisa_bayar(harga):
		return false
	saldo -= harga
	return true

func tambah(jumlah: int) -> void:
	if jumlah > 0:
		saldo += jumlah

func to_dict() -> Dictionary:
	return {"saldo": saldo}

func terapkan(d: Dictionary) -> void:
	saldo = maxi(int(d.get("saldo", saldo)), 0)
