class_name Bahasa
extends RefCounted

# Terjemahan teks antarmuka JTN. Bahasa Indonesia adalah default; bahasa lain menyusul di kamus ini.
# Kunci memakai format "bagian.nama". Teks yang belum punya terjemahan memakai Bahasa Indonesia.

const KODE := ["id", "en"]
const NAMA := {"id": "Bahasa Indonesia", "en": "English"}
const KODE_AWAL := "id"
# Bendera untuk pilihan bahasa di Pengaturan.
const BENDERA := {"id": "res://assets/bendera/bendera_id.png", "en": "res://assets/bendera/bendera_en.png"}

# Bahasa yang sedang dipakai. Diisi dari Pengaturan saat aplikasi dibuka dan saat pemain memilih bahasa.
static var kode := KODE_AWAL

const KAMUS := {
	"app.berkas": {"id": "Berkas", "en": "Files"},
	"app.forum": {"id": "Forum", "en": "Forum"},
	"app.log": {"id": "Log", "en": "Logs"},
	"app.misi": {"id": "Misi", "en": "Missions"},
	"app.pasar": {"id": "Black Market", "en": "Black Market"},
	"app.peta": {"id": "Peta Jaringan", "en": "Network Map"},
	"app.terminal": {"id": "Terminal", "en": "Terminal"},
	"app.tools": {"id": "Tools", "en": "Tools"},
	"desktop.segera": {"id": "%s akan tersedia pada tahap berikutnya.", "en": "%s will be available in a later stage."},
	"dialog.gagal_simpan": {"id": "Sesi gagal disimpan; tetap di Desktop agar data tidak hilang.", "en": "The session could not be saved. Staying on Desktop so no data is lost."},
	"dialog.kembali_menu_isi": {"id": "Progres kamu disimpan. Pilih Lanjutkan di menu untuk meneruskan dari sini. Tidak ada data yang dihapus.", "en": "Your progress is saved. Choose Continue in the menu to pick up from here. No data was deleted."},
	"dialog.kembali_menu_judul": {"id": "Kembali ke menu?", "en": "Return to menu?"},
	"dialog.kembali_menu_ok": {"id": "Kembali ke Menu", "en": "Back to Menu"},
	"dialog.mulai_baru": {"id": "Mulai Baru", "en": "Start Fresh"},
	"dialog.sesi_baru_isi": {"id": "Simpanan lama tidak dihapus permanen. Ia dipindahkan ke arsip di perangkat, lalu sesi dimulai dari awal.", "en": "The old save is not permanently deleted. It is moved to an archive on this device, and the session starts from the beginning."},
	"dialog.sesi_baru_judul": {"id": "Mulai sesi baru?", "en": "Start a new session?"},
	"login.berhasil": {"id": "Login sebagai %s.", "en": "Logged in as %s."},
	"login.contoh": {"id": "contoh: operator_01", "en": "e.g. operator_01"},
	"login.gagal": {"id": "Nama tidak bisa disimpan. Coba lagi.", "en": "The name could not be saved. Try again."},
	"login.judul": {"id": "Login", "en": "Login"},
	"login.nama_salah": {"id": "Nama harus 3–16 karakter: huruf, angka, atau _.", "en": "Name must be 3–16 characters: letters, digits, or _."},
	"login.petunjuk": {"id": "Nama operator (3–16 huruf, angka, atau _)", "en": "Operator name (3–16 letters, digits, or _)"},
	"menu.keluar": {"id": "> Keluar", "en": "> Exit"},
	"menu.lanjutkan": {"id": "> Lanjutkan", "en": "> Continue"},
	"menu.login": {"id": "> Login", "en": "> Login"},
	"menu.nama_game": {"id": "JARINGAN TERBUKA NUSANTARA", "en": "NUSANTARA OPEN NETWORK"},
	"menu.offline": {"id": "● Offline", "en": "● Offline"},
	"menu.pengaturan": {"id": "> Pengaturan", "en": "> Settings"},
	"menu.sesi_baru": {"id": "> Sesi Baru", "en": "> New Session"},
	"menu.status_belum_simpanan": {"id": "Belum ada simpanan. Mulai dengan Sesi Baru.", "en": "No saved session yet. Start with New Session."},
	"menu.status_siap": {"id": "Sistem siap. Pilih menu...", "en": "System ready. Choose a menu..."},
	"misi.aktif": {"id": "Misi aktif", "en": "Active missions"},
	"misi.belum_pesan": {"id": "Belum ada pesan.", "en": "No messages yet."},
	"misi.belum_selesai": {"id": "Belum ada misi yang selesai.", "en": "No completed missions yet."},
	"misi.dari": {"id": "Dari: %s", "en": "From: %s"},
	"misi.hadiah": {"id": "Hadiah: ", "en": "Reward: "},
	"misi.hadiah_kosong": {"id": "Hadiah: -", "en": "Reward: -"},
	"misi.ip_target": {"id": "IP target: %s", "en": "Target IP: %s"},
	"misi.judul": {"id": "> Pusat Misi", "en": "> Mission Center"},
	"misi.pesan_masuk": {"id": "Pesan masuk", "en": "Inbox"},
	"misi.petunjuk": {"id": "Petunjuk ditemukan: %d dari %d", "en": "Clues found: %d of %d"},
	"misi.reputasi": {"id": "reputasi %s +%d", "en": "reputation %s +%d"},
	"misi.selesai": {"id": "Misi selesai", "en": "Completed missions"},
	"misi.tag_selesai": {"id": "[selesai] ", "en": "[done] "},
	"misi.target": {"id": "Target: %s", "en": "Target: %s"},
	"misi.tidak_aktif": {"id": "Tidak ada misi aktif. Ikuti pesan yang masuk.", "en": "No active missions. Follow incoming messages."},
	"misi.tujuan": {"id": "Tujuan:", "en": "Objectives:"},
	"panel.lokal": {"id": "● Lokal", "en": "● Local"},
	"panel.saldo": {"id": "Kr %d", "en": "Cr %d"},
	"pasar.beli": {"id": "Beli", "en": "Buy"},
	"pasar.dimiliki": {"id": "Sudah dimiliki", "en": "Owned"},
	"pasar.habis": {"id": "Stok habis", "en": "Out of stock"},
	"pasar.harga": {"id": "%d Kr  ·  stok %d  ·  %s", "en": "%d Cr  ·  stock %d  ·  %s"},
	"pasar.saldo": {"id": "Saldo %d Kr  ·  Reputasi %s: %d", "en": "Balance %d Cr  ·  Reputation %s: %d"},
	"pasar.terkunci": {"id": "Belum terbuka. Butuh reputasi %d.", "en": "Locked. Requires reputation %d."},
	"pasar.tersedia": {"id": "Tersedia", "en": "Available"},
	"pasar.tingkat": {"id": "Peningkatan tingkat", "en": "Level upgrade"},
	"pengaturan.ukuran_kecil": {"id": "Kecil", "en": "Small"},
	"pengaturan.ukuran_sedang": {"id": "Sedang", "en": "Medium"},
	"pengaturan.ukuran_besar": {"id": "Besar", "en": "Large"},
	"pengaturan.bahasa": {"id": "Bahasa", "en": "Language"},
	"pengaturan.bahasa_diganti": {"id": "Bahasa diubah ke Bahasa Indonesia.", "en": "Language changed to English."},
	"pengaturan.berlaku_terminal": {"id": "Berlaku saat Terminal dibuka berikutnya.", "en": "Applies the next time Terminal opens."},
	"pengaturan.contoh": {"id": "Contoh: begini teks Terminal akan tampil.", "en": "Example: this is how Terminal text will look."},
	"pengaturan.judul": {"id": "Pengaturan", "en": "Settings"},
	"pengaturan.teks_terminal": {"id": "Teks Terminal", "en": "Terminal text"},
	"pengaturan.ukuran_disimpan": {"id": "Ukuran teks disimpan: %s.", "en": "Text size saved: %s."},
	"peta.akses": {"id": "Akses  %s", "en": "Access  %s"},
	"peta.aktif": {"id": "Aktif", "en": "Active"},
	"peta.ketuk": {"id": "Ketuk node untuk melihat detail.", "en": "Tap a node to see its details."},
	"peta.operator": {"id": "Operator: %s", "en": "Operator: %s"},
	"peta.operator_kosong": {"id": "Operator: -", "en": "Operator: -"},
	"peta.perangkat": {"id": "Perangkat: JTN", "en": "Device: JTN"},
	"peta.port_kosong": {"id": "Detail port tidak tersedia.", "en": "Port details are unavailable."},
	"peta.status": {"id": "Status  %s", "en": "Status  %s"},
	"peta.status_lokal": {"id": "Status: Lokal", "en": "Status: Local"},
	"peta.terhubung": {"id": "Terhubung ke  ", "en": "Connected to  "},
	"peta.terkunci": {"id": "Terkunci", "en": "Locked"},
	"peta.terkunci_akses": {"id": "terkunci, akses belum terbuka", "en": "locked, access not yet open"},
	"peta.tidak_aktif": {"id": "Tidak aktif", "en": "Inactive"},
	"umum.batal": {"id": "Batal", "en": "Cancel"},
	"umum.kembali": {"id": "Kembali", "en": "Back"},
	"umum.simpan": {"id": "Simpan", "en": "Save"},
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
