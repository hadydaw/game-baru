class_name Bahasa
extends RefCounted

# Terjemahan teks antarmuka JTN. Bahasa Indonesia adalah default; bahasa lain menyusul di kamus ini.
# Kunci memakai format "bagian.nama". Teks yang belum punya terjemahan memakai Bahasa Indonesia.

const KODE := ["id", "en"]
const NAMA := {"id": "Bahasa Indonesia", "en": "English"}
const KODE_AWAL := "id"

# Bahasa yang sedang dipakai. Diisi dari Pengaturan saat aplikasi dibuka dan saat pemain memilih bahasa.
static var kode := KODE_AWAL

const KAMUS := {
	"pengaturan.bahasa": {"id": "Bahasa", "en": "Language"},
	"pengaturan.bahasa_diganti": {"id": "Bahasa diubah ke Bahasa Indonesia.", "en": "Language changed to English."},
}

static func t(kunci: String) -> String:
	var entri: Dictionary = KAMUS.get(kunci, {})
	if entri.has(kode):
		return String(entri[kode])
	if entri.has(KODE_AWAL):
		return String(entri[KODE_AWAL])
	return kunci

# Membaca bahasa tersimpan. Dipanggil sekali saat aplikasi dibuka.
static func muat_dari_pengaturan() -> void:
	kode = Pengaturan.bahasa()
