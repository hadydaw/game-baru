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
	"misi.deskripsi": {"id": "DESKRIPSI", "en": "DESCRIPTION"},
	"misi.tujuan_ringkas": {"id": "Tujuan : %s", "en": "Goal : %s"},
	"misi.pembayaran": {"id": "Pembayaran : Kr %d", "en": "Payment : Kr %d"},
	"misi.persyaratan": {"id": "Persyaratan : %s", "en": "Requirement : %s"},
	"misi.tombol_terima": {"id": "MENERIMA", "en": "ACCEPT"},
	"misi.tombol_rincian": {"id": "RINCIAN", "en": "DETAILS"},
	"misi.tombol_hapus": {"id": "MENGHAPUS", "en": "DELETE"},
	"misi.label_dari": {"id": "DARI : %s", "en": "FROM : %s"},
	"misi.label_judul": {"id": "JUDUL : %s", "en": "TITLE : %s"},
	"misi.pesan_belum_ada": {"id": "Belum ada pesan untuk misi ini.", "en": "No message for this mission yet."},
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
	"app.tools": {"id": "Tools Repository", "en": "Tools Repository"},
	"dm.st_misi": {"id": "didapat dari misi", "en": "received from mission"},
	"dm.st_terpasang": {"id": "terpasang di rakitan", "en": "installed in assembly"},
	"dm.st_dimiliki": {"id": "dimiliki, belum dirakit", "en": "owned, not assembled"},
	"dm.kompat_ok": {"id": "Kompatibel: chipset %s didukung %s", "en": "Compatible: chipset %s is supported by %s"},
	"dm.kompat_tidak": {"id": "Tidak kompatibel: driver terpasang tidak mendukung chipset %s", "en": "Incompatible: the installed driver does not support chipset %s"},
	"dm.kompat_belum": {"id": "Belum ada driver untuk chipset %s. Pasang dari Tools Repository.", "en": "No driver for chipset %s yet. Install one from the Tools Repository."},
	"app.netmgr": {"id": "Network Manager", "en": "Network Manager"},
	"app.inventaris": {"id": "Inventaris", "en": "Inventory"},
	"netmgr.judul": {"id": "NETWORK MANAGER", "en": "NETWORK MANAGER"},
	"netmgr.hint": {"id": "Uji jaringan laboratorium. Setiap tombol menjalankan perintah yang sama dengan Terminal.", "en": "Test laboratory networks. Each button runs the same command as the Terminal."},
	"netmgr.perangkat": {"id": "Perangkat", "en": "Device"},
	"netmgr.rincian_perangkat": {"id": "%s · %s · driver: %s", "en": "%s · %s · driver: %s"},
	"netmgr.belum_rakit": {"id": "Belum ada perangkat yang dirakit. Rakit di Device Manager.", "en": "No device has been assembled yet. Assemble one in Device Manager."},
	"netmgr.tahap": {"id": "Tahap pengujian", "en": "Test stages"},
	"netmgr.t_perangkat": {"id": "Deteksi perangkat", "en": "Hardware detection"},
	"netmgr.t_scan": {"id": "Pemindaian jaringan", "en": "Wireless scanning"},
	"netmgr.t_pilih": {"id": "Pemilihan jaringan", "en": "Network selection"},
	"netmgr.t_analisis": {"id": "Analisis keamanan", "en": "Security analysis"},
	"netmgr.t_auth": {"id": "Uji autentikasi", "en": "Authentication testing"},
	"netmgr.t_audit": {"id": "Audit kata sandi", "en": "Password audit"},
	"netmgr.t_akses": {"id": "Verifikasi akses", "en": "Access verification"},
	"netmgr.jaringan": {"id": "Jaringan laboratorium", "en": "Laboratory networks"},
	"netmgr.belum_scan": {"id": "Belum ada hasil pemindaian. Jalankan pemindaian Wi-Fi.", "en": "No scan results yet. Run a Wi-Fi scan."},
	"netmgr.detail": {"id": "Kanal %d · sinyal %d dBm · %s", "en": "Channel %d · signal %d dBm · %s"},
	"netmgr.st_terlihat": {"id": "terlihat", "en": "visible"},
	"netmgr.st_pilih": {"id": "dipilih", "en": "selected"},
	"netmgr.st_analisis": {"id": "dianalisis", "en": "analyzed"},
	"netmgr.st_handshake": {"id": "handshake didapat", "en": "handshake captured"},
	"netmgr.st_kata": {"id": "kata sandi ditemukan", "en": "password found"},
	"netmgr.st_akses": {"id": "akses terbuka", "en": "access open"},
	"netmgr.akses_terbuka": {"id": "Jaringan ini sudah terbuka untukmu.", "en": "This network is already open to you."},
	"netmgr.pilih": {"id": "Pilih jaringan", "en": "Select network"},
	"netmgr.analisis": {"id": "Analisis keamanan", "en": "Analyze security"},
	"netmgr.auth": {"id": "Tangkap autentikasi", "en": "Capture authentication"},
	"netmgr.audit": {"id": "Jalankan audit kata sandi", "en": "Run password audit"},
	"netmgr.kata_sandi": {"id": "Masukkan kata sandi hasil audit", "en": "Enter the password from the audit"},
	"netmgr.verifikasi": {"id": "Verifikasi akses", "en": "Verify access"},
	"netmgr.scan": {"id": "Pindai Wi-Fi", "en": "Scan Wi-Fi"},
	"netmgr.keluaran": {"id": "Keluaran terakhir", "en": "Last output"},
	"netmgr.keluaran_kosong": {"id": "(belum ada keluaran)", "en": "(no output yet)"},
	"inv.judul": {"id": "INVENTARIS", "en": "INVENTORY"},
	"inv.saldo": {"id": "Saldo: %d Kr", "en": "Balance: %d Kr"},
	"inv.xp": {"id": "XP: %d", "en": "XP: %d"},
	"inv.tool": {"id": "Tool yang dimiliki", "en": "Owned tools"},
	"inv.tool_kosong": {"id": "Belum ada tool. Beli di Pasar.", "en": "No tools yet. Buy them at the Market."},
	"inv.komponen": {"id": "Komponen perangkat", "en": "Device components"},
	"inv.komponen_kosong": {"id": "Belum ada komponen. Beli di Pasar > Komponen.", "en": "No components yet. Buy them at Market > Components."},
	"inv.software": {"id": "Software terpasang", "en": "Installed software"},
	"inv.software_kosong": {"id": "Belum ada software. Pasang lewat Tools Repository.", "en": "No software yet. Install it from the Tools Repository."},
	"inv.hadiah": {"id": "Hadiah yang sudah diterima", "en": "Rewards received"},
	"inv.hadiah_kosong": {"id": "Belum ada hadiah.", "en": "No rewards yet."},
	"inv.misi": {"id": "Progres misi", "en": "Mission progress"},
	"inv.misi_kosong": {"id": "Belum ada misi yang diterima.", "en": "No missions received yet."},
	"inv.reputasi": {"id": "Reputasi", "en": "Reputation"},
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
	"panel.saldo": {"id": "Kr %d", "en": "Kr %d"},
	"pasar.beli": {"id": "Beli", "en": "Buy"},
	"pasar.dimiliki": {"id": "Sudah dimiliki", "en": "Owned"},
	"pasar.habis": {"id": "Stok habis", "en": "Out of stock"},
	"pasar.harga": {"id": "%d Kr  ·  stok %d  ·  %s", "en": "%d Kr  ·  stock %d  ·  %s"},
	"pasar.saldo": {"id": "Saldo %d Kr  ·  Reputasi %s: %d", "en": "Balance %d Kr  ·  Reputation %s: %d"},
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
	"hw.tidak_dijual": {"id": "Komponen tidak dijual: %s", "en": "Component is not for sale: %s"},
	"hw.saldo_kurang": {"id": "Saldo tidak cukup. Harga %d Kr, saldo %d Kr.", "en": "Not enough funds. Price %d Kr, balance %d Kr."},
	"hw.dibeli": {"id": "Dibeli: %s seharga %d Kr.", "en": "Purchased: %s for %d Kr."},
	"hw.sudah_dirakit": {"id": "Perangkat sudah dirakit.", "en": "The device is already assembled."},
	"hw.adapter_kurang": {"id": "Adapter USB belum dimiliki.", "en": "No USB adapter owned."},
	"hw.antena_kurang": {"id": "Antena eksternal belum dimiliki.", "en": "No external antenna owned."},
	"hw.kabel_kurang": {"id": "Kabel USB belum dimiliki.", "en": "No USB cable owned."},
	"hw.dirakit": {"id": "Perangkat dirakit: %s.", "en": "Device assembled: %s."},
	"hw.belum_dirakit": {"id": "Perangkat belum dirakit.", "en": "The device is not assembled yet."},
	"hw.antena_sudah_maks": {"id": "Antena sudah tingkat maksimal.", "en": "The antenna is already at its maximum level."},
	"hw.antena_penguat_kurang": {"id": "Antena Penguat belum dimiliki.", "en": "No booster antenna owned."},
	"hw.antena_naik": {"id": "Antena perangkat naik ke tingkat 2.", "en": "Device antenna upgraded to level 2."},
	"hw.sudah_terhubung": {"id": "Perangkat sudah terhubung.", "en": "The device is already connected."},
	"hw.driver_kurang": {"id": "Driver belum terpasang. Pasang lewat Tools Repository.", "en": "Driver not installed. Install it from the Tools Repository."},
	"hw.chipset_tidak_cocok": {"id": "Driver tidak mendukung chipset %s.", "en": "The driver does not support chipset %s."},
	"hw.terhubung": {"id": "Perangkat terhubung dengan driver %s.", "en": "Device connected with driver %s."},
	"hw.belum_terhubung": {"id": "Perangkat belum terhubung.", "en": "The device is not connected."},
	"hw.terputus": {"id": "Perangkat diputuskan.", "en": "Device disconnected."},
	"sw.tidak_ada": {"id": "Aplikasi tidak ditemukan: %s", "en": "Application not found: %s"},
	"sw.sudah_terpasang": {"id": "%s sudah terpasang.", "en": "%s is already installed."},
	"sw.dependensi": {"id": "Dependensi belum terpasang: %s", "en": "Missing dependency: %s"},
	"sw.butuh_adapter": {"id": "%s membutuhkan adapter Wi-Fi.", "en": "%s requires a Wi-Fi adapter."},
	"sw.dipasang": {"id": "%s versi %s berhasil dipasang.", "en": "%s version %s installed."},
	"sw.belum_terpasang": {"id": "Aplikasi belum terpasang: %s", "en": "Application not installed: %s"},
	"sw.sudah_terbaru": {"id": "%s sudah versi terbaru.", "en": "%s is already up to date."},
	"sw.diperbarui": {"id": "%s diperbarui ke versi %s.", "en": "%s updated to version %s."},
	"dev.usage": {"id": "device: gunakan list, detect, rakit, hubungkan, putuskan, atau upgrade antena.", "en": "device: use list, detect, rakit, hubungkan, putuskan, or upgrade antena."},
	"dev.judul_komponen": {"id": "Komponen:", "en": "Components:"},
	"dev.kosong": {"id": "  (kosong)", "en": "  (empty)"},
	"dev.judul_perangkat": {"id": "Perangkat:", "en": "Device:"},
	"dev.belum_rakit": {"id": "  Belum dirakit.", "en": "  Not assembled."},
	"dev.rincian": {"id": "  Antena tingkat %d · %s · driver: %s", "en": "  Antenna level %d · %s · driver: %s"},
	"dev.terhubung": {"id": "terhubung", "en": "connected"},
	"dev.tidak_terhubung": {"id": "tidak terhubung", "en": "not connected"},
	"dev.belum_driver": {"id": "belum ada", "en": "none"},
	"dev.detect_perangkat": {"id": "Terdeteksi: %s (chipset %s)", "en": "Detected: %s (chipset %s)"},
	"dev.detect_driver": {"id": "Driver: %s", "en": "Driver: %s"},
	"dev.detect_status": {"id": "Status: %s", "en": "Status: %s"},
	"dev.detect_komponen": {"id": "Komponen ditemukan, belum dirakit: %s", "en": "Components found, not assembled: %s"},
	"dev.detect_tidak_ada": {"id": "Tidak ada perangkat nirkabel yang terdeteksi.", "en": "No wireless device detected."},
	"toko.usage": {"id": "toko: gunakan 'toko' atau 'toko beli <id>'.", "en": "toko: use 'toko' or 'toko beli <id>'."},
	"toko.judul": {"id": "Toko komponen perangkat keras:", "en": "Hardware component shop:"},
	"toko.dimiliki": {"id": "dimiliki %d", "en": "owned %d"},
	"err.butuh_argumen": {"id": "argumen diperlukan", "en": "argument required"},
	"app.perangkat": {"id": "Perangkat", "en": "Devices"},
	"perangkat.judul": {"id": "PERANGKAT", "en": "DEVICES"},
	"perangkat.komponen": {"id": "Komponen", "en": "Components"},
	"perangkat.kosong": {"id": "Belum ada komponen. Beli di Pasar.", "en": "No components yet. Buy them at the Market."},
	"perangkat.status": {"id": "Status perangkat", "en": "Device status"},
	"perangkat.belum_rakit": {"id": "Belum dirakit. Butuh adapter USB, antena eksternal, dan kabel USB.", "en": "Not assembled. Requires a USB adapter, an external antenna, and a USB cable."},
	"perangkat.rincian": {"id": "Antena tingkat %d · %s · driver: %s", "en": "Antenna level %d · %s · driver: %s"},
	"perangkat.rakit": {"id": "RAKIT", "en": "ASSEMBLE"},
	"perangkat.hubungkan": {"id": "HUBUNGKAN", "en": "CONNECT"},
	"perangkat.putuskan": {"id": "PUTUSKAN", "en": "DISCONNECT"},
	"perangkat.upgrade": {"id": "UPGRADE ANTENA", "en": "UPGRADE ANTENNA"},
	"hw.desk.usb_wireless_adapter": {"id": "Adapter Wi-Fi USB dengan chipset Atheros AR9271. Mendukung driver resmi JTN.", "en": "USB Wi-Fi adapter with an Atheros AR9271 chipset. Supported by the official JTN driver."},
	"hw.desk.usb_wireless_adapter_rt": {"id": "Adapter Wi-Fi USB murah dengan chipset RT5370. Belum ada driver di Tools Repository.", "en": "Cheap USB Wi-Fi adapter with an RT5370 chipset. No driver in the Tools Repository yet."},
	"hw.desk.antena_eksternal": {"id": "Antena standar. Jangkauan sinyal terbatas.", "en": "Standard antenna. Limited signal range."},
	"hw.desk.antena_penguat": {"id": "Antena berpenguat. Menaikkan tingkat antena perangkat yang sudah dirakit.", "en": "Booster antenna. Raises the antenna level of an assembled device."},
	"hw.desk.kabel_usb": {"id": "Kabel penghubung adapter ke perangkat.", "en": "Cable connecting the adapter to the device."},
	"hw.desk.wifi_hacking_kit": {"id": "Paket perangkat pertama dari JTN. Antena perangkat otomatis ditingkatkan.", "en": "The first device kit from JTN. The device antenna is upgraded automatically."},
	"sw.desk.driver-ar9271": {"id": "Driver resmi untuk chipset Atheros AR9271.", "en": "Official driver for the Atheros AR9271 chipset."},
	"sw.desk.wifi-scanner": {"id": "Memindai jaringan Wi-Fi di sekitar perangkat yang terhubung.", "en": "Scans Wi-Fi networks around the connected device."},
	"sw.desk.network-analyzer": {"id": "Menganalisis konfigurasi dan keamanan jaringan laboratorium.", "en": "Analyzes the configuration and security of laboratory networks."},
	"sw.desk.password-auditor": {"id": "Menguji autentikasi jaringan dan memeriksa kekuatan kata sandi.", "en": "Tests network authentication and checks password strength."},
	"pasar.komponen": {"id": "Komponen", "en": "Components"},
	"pasar.harga_komponen": {"id": "%d Kr · dimiliki %d", "en": "%d Kr · owned %d"},
	"repo.usage": {"id": "tools: gunakan search <kata>, info <id>, install <id>, update <id>, atau list.", "en": "tools: use search <word>, info <id>, install <id>, update <id>, or list."},
	"repo.tidak_cocok": {"id": "Tidak ada aplikasi yang cocok dengan: %s", "en": "No application matches: %s"},
	"repo.judul_terpasang": {"id": "Aplikasi terpasang:", "en": "Installed applications:"},
	"repo.list_kosong": {"id": "  Belum ada aplikasi yang terpasang.", "en": "  No applications installed yet."},
	"repo.belum_dipasang": {"id": "belum dipasang", "en": "not installed"},
	"repo.tidak_ada": {"id": "tidak ada", "en": "none"},
	"repo.hw_adapter": {"id": "USB Wireless Adapter", "en": "USB Wireless Adapter"},
	"repo.hw_tidak": {"id": "tidak ada", "en": "none"},
	"repo.tipe.driver": {"id": "driver", "en": "driver"},
	"repo.tipe.aplikasi": {"id": "aplikasi", "en": "application"},
	"repo.st_tersedia": {"id": "tersedia", "en": "available"},
	"repo.st_terpasang": {"id": "terpasang", "en": "installed"},
	"repo.st_perlu_update": {"id": "terpasang, ada pembaruan", "en": "installed, update available"},
	"repo.info_nama": {"id": "Nama: %s (%s)", "en": "Name: %s (%s)"},
	"repo.info_tipe": {"id": "Tipe: %s · kategori %s", "en": "Type: %s · category %s"},
	"repo.info_versi": {"id": "Versi terbaru: %s · ukuran %s", "en": "Latest version: %s · size %s"},
	"repo.info_terpasang": {"id": "Versi terpasang: %s", "en": "Installed version: %s"},
	"repo.info_harga": {"id": "Harga: %d Kr", "en": "Price: %d Kr"},
	"repo.info_deps": {"id": "Dependensi: %s", "en": "Dependencies: %s"},
	"repo.info_hw": {"id": "Persyaratan hardware: %s", "en": "Hardware requirement: %s"},
	"repo.info_status": {"id": "Status: %s", "en": "Status: %s"},
	"repo.info_riwayat": {"id": "Riwayat versi: %s", "en": "Version history: %s"},
	"repo.judul_repo": {"id": "TOOLS REPOSITORY", "en": "TOOLS REPOSITORY"},
	"repo.cari": {"id": "Cari software atau driver", "en": "Search software or drivers"},
	"repo.pasang": {"id": "PASANG", "en": "INSTALL"},
	"repo.perbarui": {"id": "PERBARUI", "en": "UPDATE"},
	"repo.terpasang_label": {"id": "TERPASANG", "en": "INSTALLED"},
	"repo.kosong": {"id": "Tidak ada yang cocok.", "en": "Nothing matches."},
	"repo.ukuran": {"id": "Ukuran %s · %d Kr", "en": "Size %s · %d Kr"},
	"repo.dep_kurang": {"id": "Butuh: %s", "en": "Requires: %s"},
	"wifi.judul_scan": {"id": "Memindai jaringan Wi-Fi di sekitar...", "en": "Scanning nearby Wi-Fi networks..."},
	"wifi.usage_scan": {"id": "wifi-scanner: gunakan 'wifi-scanner --scan' untuk memindai.", "en": "wifi-scanner: use 'wifi-scanner --scan' to scan."},
	"wifi.belum_scan": {"id": "Belum ada hasil pemindaian. Jalankan wifi-scanner --scan lebih dulu.", "en": "No scan results yet. Run wifi-scanner --scan first."},
	"wifi.usage_network": {"id": "network: gunakan 'network list' atau 'network inspect <ssid>'.", "en": "network: use 'network list' or 'network inspect <ssid>'."},
	"wifi.judul_list": {"id": "Jaringan terdeteksi:", "en": "Detected networks:"},
	"wifi.tidak_terlihat": {"id": "Jaringan tidak ada dalam hasil pemindaian: %s", "en": "Network not in scan results: %s"},
	"wifi.judul_inspect": {"id": "Jaringan %s dipilih untuk pengujian.", "en": "Network %s selected for testing."},
	"wifi.detail": {"id": "  BSSID %s · kanal %d · sinyal %d dBm · enkripsi %s", "en": "  BSSID %s · channel %d · signal %d dBm · encryption %s"},
	"wifi.usage_security": {"id": "security: gunakan 'security analyze <ssid>' atau 'security verify <ssid> <kata_sandi>'.", "en": "security: use 'security analyze <ssid>' or 'security verify <ssid> <password>'."},
	"wifi.belum_dipilih": {"id": "Pilih jaringan lebih dulu dengan 'network inspect <ssid>'.", "en": "Select a network first with 'network inspect <ssid>'."},
	"wifi.analisis_judul": {"id": "Analisis keamanan %s:", "en": "Security analysis of %s:"},
	"wifi.analisis_wep": {"id": "  WEP: enkripsi lama dengan IV yang lemah. Kumpulkan paket lalu uji kata sandinya.", "en": "  WEP: old encryption with weak IVs. Collect packets, then audit the key."},
	"wifi.analisis_wpa2": {"id": "  WPA2: kata sandi diuji lewat handshake. Tangkap handshake lebih dulu.", "en": "  WPA2: the password is tested through a handshake. Capture the handshake first."},
	"wifi.belum_analisis": {"id": "Analisis keamanan belum dilakukan. Jalankan 'security analyze <ssid>'.", "en": "No security analysis yet. Run 'security analyze <ssid>'."},
	"wifi.usage_audit": {"id": "audit: gunakan 'audit auth <ssid>' atau 'audit run <ssid>'.", "en": "audit: use 'audit auth <ssid>' or 'audit run <ssid>'."},
	"wifi.handshake_wpa": {"id": "Handshake WPA2 ditangkap dari %s.", "en": "WPA2 handshake captured from %s."},
	"wifi.iv_wep": {"id": "Paket IV WEP dikumpulkan dari %s.", "en": "WEP IV packets collected from %s."},
	"wifi.belum_auth": {"id": "Autentikasi belum diuji. Jalankan 'audit auth <ssid>'.", "en": "Authentication not tested yet. Run 'audit auth <ssid>'."},
	"wifi.tidak_ada_kamus": {"id": "Kata sandi tidak ada dalam kamus audit.", "en": "The password is not in the audit dictionary."},
	"wifi.kunci_ditemukan": {"id": "KUNCI DITEMUKAN untuk %s: %s", "en": "KEY FOUND for %s: %s"},
	"wifi.belum_audit": {"id": "Kata sandi belum ditemukan. Jalankan 'audit run <ssid>'.", "en": "Password not found yet. Run 'audit run <ssid>'."},
	"wifi.kata_sandi_salah": {"id": "Kata sandi salah untuk %s.", "en": "Wrong password for %s."},
	"wifi.akses": {"id": "Akses ke %s terverifikasi. Jaringan laboratorium terbuka.", "en": "Access to %s verified. Laboratory network unlocked."},
	"term.siap": {"id": "Terminal siap. Ketik \"help\" untuk daftar perintah.", "en": "Terminal ready. Type \"help\" for the list of commands."},
}

# Teks terminal dua-bahasa: satu string membawa versi ID dan EN, dipilih saat ditampilkan.
# Dengan begitu baris yang sudah tercetak tetap bisa dirender ulang saat bahasa diganti.
const PEMBUKA := "\u0001"
const PEMISAH := "\u0002"
const PENUTUP := "\u0003"

static func dua(id: String, en: String, args: Array = []) -> String:
	var a := id % args if not args.is_empty() else id
	var b := en % args if not args.is_empty() else en
	return PEMBUKA + a + PEMISAH + b + PENUTUP

# Mengembalikan teks sesuai bahasa aktif. Teks biasa tanpa penanda dikembalikan apa adanya.
# Kunci bahasa menjadi pasangan dua-bahasa, supaya baris yang sudah tercetak tetap ikut bahasa aktif.
static func kunci_dua(kunci: String, args: Array = []) -> String:
	var entri: Dictionary = KAMUS.get(kunci, {})
	var id := String(entri.get("id", kunci))
	return dua(id, String(entri.get("en", id)), args)

static func pilih(teks: String) -> String:
	var keluar := ""
	var sisa := teks
	while true:
		var a := sisa.find(PEMBUKA)
		if a == -1:
			return keluar + sisa
		var b := sisa.find(PEMISAH, a)
		var c := sisa.find(PENUTUP, b)
		if b == -1 or c == -1:
			return keluar + sisa
		keluar += sisa.substr(0, a)
		keluar += sisa.substr(a + 1, b - a - 1) if kode == "id" else sisa.substr(b + 1, c - b - 1)
		sisa = sisa.substr(c + 1)
	return keluar

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
