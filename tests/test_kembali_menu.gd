extends GutTest

# Kembali ke menu menyimpan sesi tanpa menghapus atau mengatur ulang data.

const BERKAS := "user://uji_kembali_menu.json"

func before_each() -> void:
	Penyimpanan.berkas_aktif = BERKAS
	if FileAccess.file_exists(BERKAS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BERKAS))
	SesiUtama.sesi = ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}))

func after_all() -> void:
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS

func test_simpan_sesi_tidak_mengarsipkan_simpanan() -> void:
	var sesi := SesiUtama.ambil()
	sesi.jalankan("ping -c 1 gerbang")
	assert_true(Penyimpanan.simpan_sesi(sesi, BERKAS), "simpan berhasil")
	assert_true(Penyimpanan.ada_simpanan(BERKAS), "simpanan masih ada")
	assert_false(FileAccess.file_exists(BERKAS + ".bak"), "tidak ada arsip .bak")

func test_progres_bertahan_setelah_kembali_ke_menu() -> void:
	var sesi := SesiUtama.ambil()
	sesi.jalankan("ping -c 1 gerbang")
	Penyimpanan.simpan_sesi(sesi, BERKAS)
	# Simulasi kembali ke menu lalu Lanjutkan: sesi dimuat dari penyimpanan.
	var data: Dictionary = Penyimpanan.muat(BERKAS)
	assert_false(data.is_empty(), "data bisa dibaca")
	var pulih := ShellSession.dari_dict(data)
	assert_true(pulih.jaringan.dikenal("arsip") or pulih.jaringan.dikenal("gerbang"), "progres jaringan tetap ada")
	assert_eq(pulih.cwd, sesi.cwd, "direktori kerja tetap sama")

func test_sesi_di_memori_tidak_direset() -> void:
	var sesi := SesiUtama.ambil()
	sesi.jalankan("ping -c 1 gerbang")
	var sebelum := sesi.jaringan.to_dict()
	Penyimpanan.simpan_sesi(sesi, BERKAS)
	assert_true(SesiUtama.ambil() == sesi, "objek sesi yang sama")
	assert_eq(SesiUtama.ambil().jaringan.to_dict(), sebelum, "isi jaringan tidak berubah")
