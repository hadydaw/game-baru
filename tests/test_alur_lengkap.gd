extends GutTest

# Uji alur utuh sebagai satu permainan: dari sesi baru sampai Tutorial 1 selesai, lalu disimpan,
# dimuat ulang lewat jalur aplikasi (SesiUtama), dan diperiksa tidak ada hadiah ganda.
# Juga memeriksa bahwa keluaran Terminal dalam bahasa Inggris tidak memuat kata Indonesia.

const JALUR := "user://test_alur_lengkap.json"
const LANGKAH := [
	"help",
	"device list",
	"toko beli usb_wireless_adapter",
	"toko beli antena_eksternal",
	"toko beli kabel_usb",
	"device rakit",
	"tools search driver",
	"tools install driver-ar9271",
	"device hubungkan",
	"tools install wifi-scanner",
	"wifi-scanner --scan",
	"__netmgr__",
	"tools install network-analyzer",
	"network inspect LAB-WIFI-01",
	"security analyze LAB-WIFI-01",
	"man password-auditor",
	"tools install password-auditor",
	"tools list",
	"man handshake",
	"audit auth LAB-WIFI-01",
	"man hasil-handshake",
	"man audit",
	"audit run LAB-WIFI-01",
	"man kesimpulan-audit",
	"security verify LAB-WIFI-01 senja1234",
	"device list",
	"tools",
	"toko",
	"wallet",
	"network list",
]

func before_each() -> void:
	Penyimpanan.berkas_aktif = JALUR
	Penyimpanan.arsipkan(JALUR)
	SesiUtama.reset()

func after_each() -> void:
	Penyimpanan.arsipkan(JALUR)
	SesiUtama.reset()
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	Bahasa.set_kode("id")

func _jalankan(s: ShellSession, cmd: String) -> Array:
	var hasil := _jalankan_asli(s, cmd)
	_baca_tahap_aktif(s)
	return hasil

func _jalankan_asli(s: ShellSession, cmd: String) -> Array:
	var teks: Array = []
	# Membuka aplikasi Network Manager dari desktop dicatat sebagai flag, bukan perintah Terminal.
	if cmd == "__netmgr__":
		s.jaringan.buka("ui:netmgr")
		Misi.perbarui(s)
		return teks
	for b in s.jalankan(cmd):
		teks.append(ShellSession.teks_baris(b))
	return teks

# Pemain membaca materi tahap yang sedang aktif (tombol KEMBALI), lalu menyelesaikan tugasnya.
func _baca_tahap_aktif(s: ShellSession) -> void:
	var m := Misi.temukan("misi_1")
	var n := Misi.tahap_aktif(s, m)
	while n > 0 and not s.jaringan.progres.has(Misi.baca_flag("misi_1", n)):
		if not Misi.tandai_baca(s, "misi_1", n):
			break
		n = Misi.tahap_aktif(s, m)

func test_tutorial_selesai_lalu_bertahan_setelah_dimuat_ulang() -> void:
	var s := SesiUtama.ambil()
	for cmd in LANGKAH:
		_jalankan(s, cmd)
		Misi.perbarui(s)
		Misi.terima(s, "misi_1")
	assert_eq(String(s.misi.get("misi_1", "")), "selesai", "Tutorial 1 harus selesai")
	assert_true(s.hadiah_diambil.has("misi_1"), "hadiah misi_1 diterima")
	assert_true(s.wifi.terakses.has("LAB-WIFI-01"), "akses jaringan laboratorium terbuka")
	Penyimpanan.simpan_sesi(s)
	var saldo := s.economy.saldo
	var xp := s.xp

	SesiUtama.reset()
	var s2 := SesiUtama.ambil()
	assert_eq(String(s2.misi.get("misi_1", "")), "selesai", "status misi tetap setelah dimuat")
	assert_eq(s2.economy.saldo, saldo, "saldo tetap setelah dimuat")
	assert_eq(s2.xp, xp, "XP tetap setelah dimuat")
	assert_true(s2.perangkat.terhubung(), "perangkat tetap terhubung")
	assert_true(s2.repositori.punya("wifi-scanner"), "software tetap terpasang")
	assert_true(s2.wifi.terakses.has("LAB-WIFI-01"), "akses jaringan tetap terbuka")

	# Mengulang pemuatan atau membuka misi lagi tidak boleh memberi hadiah ganda.
	Misi.perbarui(s2)
	Misi.perbarui(s2)
	assert_eq(s2.hadiah_diambil.count("misi_1"), 1, "hadiah hanya sekali")
	assert_eq(s2.economy.saldo, saldo, "saldo tidak bertambah lagi")
	assert_eq(s2.xp, xp, "XP tidak bertambah lagi")

func test_keluaran_bahasa_inggris_tidak_memuat_kata_indonesia() -> void:
	Bahasa.set_kode("en")
	var s := ShellSession.new(Vfs.new(_fs_awal()))
	var semua: Array = []
	for cmd in LANGKAH:
		semua.append_array(_jalankan(s, cmd))
		Misi.perbarui(s)
		Misi.terima(s, "misi_1")
	var kata := [" tidak ", " belum ", " sudah ", " dengan ", " untuk ", " dari ", " ditemukan", " dimiliki", " terkunci", " berkas", " Pilih", " tingkat ", "Tahap ", "Agensi", "Penjual", "Saldo", "Reputasi:", "Perangkat ", "Tidak ada", "butuh", "terbuka", "tanpa", "Umum", "Spesialis", "Kolektif", "Elite", "terhubung", "Antena", "dirakit", "dimiliki", "berhasil", "Dibeli", "belum", "Kanal", "sinyal", "terlihat", "dipilih", "dianalisis", "Komponen"]
	var bocor: Array = []
	for baris in semua:
		for k in kata:
			if String(baris).contains(k):
				bocor.append("%s  <- %s" % [baris, k])
	# Kotak masuk dan teks misi juga harus berbahasa Inggris.
	for p in s.pesan_misi:
		semua.append(Bahasa.pilih(String(p["subjek"])))
		semua.append(Bahasa.pilih(String(p["isi"])))
	var m := Misi.temukan("misi_1")
	for t in m["tahap"]:
		semua.append(Bahasa.pilih(String(t["judul"])))
		semua.append(Bahasa.pilih(String(t["pesan"])))
	for t in m["tujuan"]:
		semua.append(Bahasa.pilih(String(t["teks"])))
	for baris in semua:
		for k in kata:
			if String(baris).contains(k):
				bocor.append("%s  <- %s" % [baris, k])
	for baris in semua:
		if String(baris).contains("bash: :"):
			bocor.append("prefiks kosong: " + String(baris))
	assert_eq(bocor, [], "teks Indonesia bocor ke mode Inggris")
	assert_true(String(s.misi.get("misi_1", "")) == "selesai")

func _fs_awal() -> Dictionary:
	return SesiUtama._fs_awal()
