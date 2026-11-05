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
	"misi.judul_tersedia": {"id": "MISI TERSEDIA", "en": "AVAILABLE MISSIONS"},
	"misi.kat.tutorial": {"id": "Tutorial", "en": "Tutorial"},
	"misi.kat.tutorial_lanjutan": {"id": "Tutorial Lanjutan", "en": "Advanced Tutorial"},
	"misi.kat.harian": {"id": "Misi Harian", "en": "Daily Missions"},
	"misi.kat.hacktivism": {"id": "Hacktivism", "en": "Hacktivism"},
	"misi.kat.rekayasa_sosial": {"id": "Rekayasa Sosial", "en": "Social Engineering"},
	"misi.kat.peretasan_perusahaan": {"id": "Peretasan Perusahaan", "en": "Corporate Breach"},
	"misi.kat.peretasan_industri": {"id": "Peretasan Industri", "en": "Industrial Breach"},
	"misi.kat.peretasan_bank": {"id": "Peretasan Bank", "en": "Bank Breach"},
	"misi.kat.perang_maya": {"id": "Perang Maya", "en": "Cyber War"},
	"misi.jumlah": {"id": "%d misi", "en": "%d missions"},
	"misi.belum_ada_kategori": {"id": "Belum ada misi.", "en": "No missions yet."},
	"misi.pilih_kategori": {"id": "Pilih kategori misi terlebih dahulu.", "en": "Select a mission category first."},
	"misi.kategori_kosong": {"id": "Belum ada misi di kategori ini.", "en": "No missions in this category yet."},
	"misi.tombol_keluar": {"id": "KELUAR", "en": "EXIT"},
	"misi.tombol_pilih": {"id": "PILIH", "en": "SELECT"},
	"misi.kembali_kategori": {"id": "Kembali ke kategori", "en": "Back to categories"},
	"app.email": {"id": "E-Mail", "en": "E-Mail"},
	"email.judul": {"id": "E-Mail", "en": "E-Mail"},
	"email.tab_masuk": {"id": "MASUK", "en": "INBOX"},
	"email.tab_sampah": {"id": "SAMPAH", "en": "TRASH"},
	"email.baca": {"id": "BACA", "en": "READ"},
	"email.hapus": {"id": "MENGHAPUS", "en": "DELETE"},
	"email.sampah": {"id": "SAMPAH", "en": "TRASH"},
	"email.keluar": {"id": "KELUAR", "en": "BACK"},
	"email.pulihkan": {"id": "PULIHKAN", "en": "RESTORE"},
	"email.hapus_permanen": {"id": "HAPUS PERMANEN", "en": "DELETE FOREVER"},
	"email.kosong": {"id": "Kotak masuk kosong.", "en": "Inbox is empty."},
	"email.sampah_kosong": {"id": "Sampah kosong.", "en": "Trash is empty."},
	"email.dari": {"id": "DARI", "en": "FROM"},
	"email.pilih": {"id": "Pilih email untuk dibaca.", "en": "Select an email to read."},
	"email.belum_dibaca": {"id": "%d belum dibaca", "en": "%d unread"},
	"email.sambutan_judul": {"id": "Selamat datang!", "en": "Welcome!"},
	"email.sambutan_isi": {"id": "Anda memiliki 2 email baru!", "en": "You have 2 new emails!"},
	"email.sambutan_ok": {"id": "OK", "en": "OK"},
	"email.panduan.dari": {"id": "Biro Jaringan Terbuka", "en": "Open Network Bureau"},
	"email.panduan.judul": {"id": "Penting: panduan memulai", "en": "Important: getting started"},
	"email.panduan.isi": {"id": "Selamat datang di Jaringan Terbuka Nusantara.\n\nAnda sekarang punya terminal. Ketik help untuk melihat daftar perintah, lalu coba pwd dan ls untuk memahami berkas di komputer Anda.\n\nUntuk menemukan perangkat baru di jaringan, gunakan scan dengan alamat IP. Setiap perangkat punya alamat unik, dan alamatnya bisa berbeda dari sesi ke sesi.\n\nPeta Jaringan menampilkan perangkat yang sudah Anda temukan. Pusat Misi berisi tugas berikutnya dan pesan dari klien.\n\nBerhati-hatilah. Setiap jejak yang Anda tinggalkan bisa dilacak.", "en": "Welcome to the Nusantara Open Network.\n\nYou now have a terminal. Type help to see the command list, then try pwd and ls to learn the files on your machine.\n\nTo find new devices on the network, use scan with an IP address. Every device has a unique address, and it can change from one session to the next.\n\nThe Network Map shows devices you have found. The Mission Center holds your next tasks and messages from clients.\n\nBe careful. Every trace you leave can be followed."},
	"email.mira.dari": {"id": "Mira", "en": "Mira"},
	"email.mira.judul": {"id": "Jangan percaya sinyal pertama", "en": "Don't trust the first signal"},
	"email.mira.isi": {"id": "Aku dengar Pemerintahan Duka Janggal mulai memantau koneksi baru di beberapa kota.\n\nJadi, sebelum kamu menyentuh perangkat mana pun, cek dulu siapa yang sudah lebih dulu melihatnya. Catatan log bisa membantumu.\n\nKalau kamu butuh bantuan, cari aku di Forum. Jangan balas email ini dari perangkat yang kamu anggap aman.", "en": "I heard the Duka Janggal Government has started watching new connections in several cities.\n\nSo before you touch any device, check who saw it first. Log records can help you.\n\nIf you need help, look for me on the Forum. Don't reply to this email from a device you think is safe."},
	"pengaturan.susunan_ikon": {"id": "Susunan ikon Desktop", "en": "Desktop icon layout"},
	"pengaturan.atur_ulang_ikon": {"id": "Atur ulang susunan ikon", "en": "Reset icon layout"},
	"pengaturan.ikon_dikembalikan": {"id": "Susunan ikon Desktop dikembalikan ke awal. Buka Desktop untuk melihatnya.", "en": "Desktop icon layout reset. Open the Desktop to see it."},
	"pengaturan.ikon_gagal": {"id": "Gagal menyimpan pengaturan.", "en": "Failed to save settings."},
	"intro.judul_cerita": {"id": "Jaringan Terbuka Nusantara", "en": "Nusantara Open Network"},
	"intro.lewati": {"id": "Lewati", "en": "Skip"},
	"intro.kembali_pilih": {"id": "Kembali", "en": "Back"},
	"intro.hal1": {"id": "Selamat datang di Jaringan Terbuka Nusantara.\n\nKami adalah jaringan peretas independen yang bekerja di luar kendali siapa pun. Sejak Pemerintahan Duka Janggal mulai menyaring informasi yang boleh diakses warga, kami hadir supaya data tetap terbuka bagi siapa saja yang berhak mengetahuinya.", "en": "Welcome to the Nusantara Open Network.\n\nWe are an independent hacker network operating beyond anyone's control. Since the Duka Janggal Government began filtering the information citizens may access, we exist so that data stays open to everyone who has a right to know."},
	"intro.hal2": {"id": "Pemerintahan Duka Janggal menyebut dirinya penjaga ketertiban. Di balik layar, arsip dan catatan publik dikunci, dan siapa pun yang membukanya dianggap ancaman.\n\nKami tidak mencari kekuasaan. Kami mencari kebenaran yang sengaja disembunyikan.", "en": "The Duka Janggal Government calls itself the guardian of order. Behind the scenes, archives and public records are locked, and anyone who opens them is treated as a threat.\n\nWe do not seek power. We seek the truth that has been deliberately hidden."},
	"intro.hal3": {"id": "Sebagai agen baru, Anda akan menerima identitas baru, perangkat khusus, dan akses ke jaringan kami.\n\nTugas pertama Anda sederhana: ikuti jejak, pelajari sistem, dan jangan meninggalkan jejak.", "en": "As a new agent, you will receive a new identity, special equipment, and access to our network.\n\nYour first task is simple: follow the trail, learn the systems, and leave no trace."},
	"intro.hal4": {"id": "Pilih negara tempat Anda memulai. Dari sana, Anda akan membangun reputasi di dunia maya.\n\nKota tempat Anda berada bisa berubah seiring misi berjalan.", "en": "Choose the country where you begin. From there, you will build your reputation in the digital world.\n\nThe city you are in can change as your missions progress."},
	"intro.judul": {"id": "Selamat datang! Pilih lokasi awalmu!", "en": "Welcome! Choose your starting location!"},
	"intro.lanjut": {"id": "Lanjutkan", "en": "Continue"},
	"intro.mulai": {"id": "Mulai", "en": "Start"},
	"intro.pilih_kota": {"id": "Pilih kota", "en": "Choose a city"},
	"intro.pilih_negara_dulu": {"id": "Ketuk negara di peta.", "en": "Tap a country on the map."},
	"intro.lokasi_terpilih": {"id": "Lokasi awal: %s, %s", "en": "Starting location: %s, %s"},
	"menu_app.judul": {"id": "> Menu Aplikasi", "en": "> Applications"},
	"menu_app.cari": {"id": "Cari aplikasi...", "en": "Search apps..."},
	"menu_app.kosong": {"id": "Tidak ada aplikasi yang cocok.", "en": "No matching apps."},
	"menu_app.keluar": {"id": "Keluar", "en": "Exit"},
	"kategori.sistem": {"id": "Sistem", "en": "System"},
	"kategori.jaringan": {"id": "Jaringan", "en": "Network"},
	"kategori.pasar": {"id": "Pasar", "en": "Market"},
	"kategori.komunitas": {"id": "Komunitas", "en": "Community"},
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

# Teks UI yang bergantung pada bahasa disimpan sebagai kunci (metadata "bkey" dan "bargs") di node-nya.
# Saat bahasa diganti, segarkan() menelusuri seluruh pohon node dan menulis ulang teksnya.
# Dengan begitu semua layar yang sedang terbuka ikut berubah tanpa restart atau pemuatan ulang save.

# Mengisi teks Label atau Button dari kunci, dan mencatat kunci agar bisa diperbarui saat bahasa berganti.
static func isi(node: Node, kunci: String, args: Array = []) -> void:
	node.set_meta("bkey", kunci)
	node.set_meta("bargs", args)
	_tulis(node)

# Mendaftarkan fungsi yang menghitung ulang teks node dari keadaan saat bahasa berganti.
static func daftar_penyegar(node: Node, fungsi: Callable) -> void:
	node.set_meta("bsegar", fungsi)
	fungsi.call()

static func _tulis(node: Node) -> void:
	var teks := t(String(node.get_meta("bkey")))
	var args: Array = node.get_meta("bargs", [])
	if not args.is_empty():
		teks = teks % args
	if node is Label or node is Button:
		node.text = teks

# Memperbarui semua node di bawah root yang memiliki kunci bahasa.
static func segarkan(root: Node) -> void:
	if root == null:
		return
	if root.has_meta("bkey"):
		_tulis(root)
	# Teks yang dihitung dari keadaan (status, saldo, harga) memakai fungsi penyegar sendiri.
	if root.has_meta("bsegar"):
		var fungsi: Callable = root.get_meta("bsegar")
		if fungsi.is_valid():
			fungsi.call()
	for anak in root.get_children():
		segarkan(anak)

# Mengganti bahasa aktif dan memperbarui seluruh teks yang tampil di SceneTree, tanpa restart.
static func set_kode(baru: String) -> void:
	if not KODE.has(baru):
		return
	kode = baru
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		segarkan(tree.root)
