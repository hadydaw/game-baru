extends GutTest

# Pusat Misi 4A: status misi, pemeriksaan tujuan dari tindakan nyata, hadiah sekali, dan persistensi.

const BERKAS := "user://uji_misi.json"

func _fs_awal() -> Dictionary:
	var kunci := {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "arsip:TK-7731", "ukuran": 13}
	var dokumen := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {"kunci_arsip.txt": kunci}}
	var rumah := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {"dokumen": dokumen}}
	return {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": rumah}}}}

func _baru() -> ShellSession:
	var s := ShellSession.new(Vfs.new(_fs_awal()), Jaringan.muat(), "operator")
	Misi.perbarui(s)
	return s

func before_each() -> void:
	Penyimpanan.berkas_aktif = BERKAS
	Pengaturan.berkas_aktif = "user://uji_misi_pengaturan.json"
	if FileAccess.file_exists(BERKAS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BERKAS))

func after_all() -> void:
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	Pengaturan.berkas_aktif = Pengaturan.BERKAS

func test_data_misi_valid() -> void:
	var daftar := Misi.daftar()
	assert_eq(daftar.size(), 1, "baru misi 1 yang masuk Tahap 4A")
	var m: Dictionary = daftar[0]
	assert_eq(String(m["id"]), "misi_1")
	assert_eq(String(m["pengirim"]), "Mira")
	assert_eq(m["tujuan"].size(), 2)
	assert_false(Hadiah.data().get("misi_1", {}).is_empty(), "hadiah misi 1 terdaftar")

func test_misi_1_diterima_saat_sesi_dimulai() -> void:
	var s := _baru()
	assert_eq(String(s.misi.get("misi_1", "")), "aktif")
	assert_eq(s.pesan_misi.size(), 1, "satu pesan masuk")
	assert_eq(String(s.pesan_misi[0]["dari"]), "Mira")

func test_notifikasi_hanya_sekali() -> void:
	var s := _baru()
	assert_eq(s.notifikasi_misi().size(), 1)
	assert_eq(s.notifikasi_misi().size(), 0, "pesan yang sudah dilaporkan tidak diulang")

func test_petunjuk_hanya_muncul_setelah_dibaca() -> void:
	var s := _baru()
	var m := Misi.temukan("misi_1")
	assert_eq(Misi.petunjuk_ditemukan(s, m).size(), 0, "belum ada petunjuk")
	s.jalankan("cat dokumen/kunci_arsip.txt")
	assert_eq(Misi.petunjuk_ditemukan(s, m).size(), 1, "kunci ditemukan lewat eksplorasi")

func test_ssh_gagal_tidak_menyelesaikan_tujuan() -> void:
	var s := _baru()
	s.jalankan("ssh operator@arsip")  # belum ping, jadi gagal
	assert_false(s.jaringan.progres.has("ssh:arsip"), "login gagal tidak menandai tujuan")
	assert_eq(String(s.misi["misi_1"]), "aktif")

func test_misi_selesai_setelah_tindakan_nyata_dan_hadiah_sekali() -> void:
	var s := _baru()
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("ping -c 1 arsip")
	s.jalankan("ssh operator@arsip")
	assert_true(s.jaringan.progres.has("ssh:arsip"), "login berhasil menandai tujuan")
	assert_eq(String(s.misi["misi_1"]), "aktif", "belum selesai: catatan belum dibaca")
	s.jalankan("cat catatan.txt")
	assert_eq(String(s.misi["misi_1"]), "selesai")
	assert_eq(s.economy.saldo, 500 + 150, "hadiah kredit diberikan")
	assert_eq(s.reputation.get_nilai("kolektif_senja"), 5, "hadiah reputasi diberikan")
	Misi.perbarui(s)
	Misi.perbarui(s)
	assert_eq(s.economy.saldo, 650, "hadiah tidak berulang")
	assert_eq(s.pesan_misi.size(), 2, "pesan selesai hanya sekali")

func test_status_dan_hadiah_bertahan_setelah_muat_ulang() -> void:
	var s := _baru()
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("ping -c 1 arsip")
	s.jalankan("ssh operator@arsip")
	s.jalankan("cat catatan.txt")
	assert_true(Penyimpanan.simpan_sesi(s, BERKAS))
	var pulih := ShellSession.dari_dict(Penyimpanan.muat(BERKAS)["data"])
	assert_eq(String(pulih.misi["misi_1"]), "selesai")
	assert_eq(pulih.pesan_misi.size(), 2)
	assert_eq(pulih.economy.saldo, 650, "saldo tidak berubah saat dimuat")

func test_simpanan_lama_tanpa_status_misi_menerima_pesan() -> void:
	var data := {"fs": _fs_awal(), "cwd": "/home/operator", "riwayat": []}
	var s := ShellSession.dari_dict(data)
	assert_eq(String(s.misi.get("misi_1", "")), "aktif")
	assert_eq(s.pesan_misi.size(), 1)

func test_simpanan_lama_dengan_tindakan_selesai_diberi_hadiah_sekali() -> void:
	var data := {"fs": _fs_awal(), "cwd": "/home/operator", "riwayat": [],
		"jaringan": {"progres": ["ssh:arsip", "baca:arsip:catatan.txt"]}}
	var s := ShellSession.dari_dict(data)
	assert_eq(String(s.misi["misi_1"]), "selesai", "tindakan lama langsung dihitung")
	assert_eq(s.economy.saldo, 650)
	Misi.perbarui(s)
	assert_eq(s.economy.saldo, 650, "tidak berulang")

# Layar Pusat Misi harus bisa dibangun dari sesi yang sudah berisi misi aktif.
func test_pusat_misi_bisa_dibangun() -> void:
	SesiUtama.sesi = _baru()
	var layar := PusatMisi.new()
	add_child(layar)
	await get_tree().process_frame
	assert_true(layar.find_children("*", "Label", true, false).size() > 0, "layar menampilkan label")
	layar.free()
