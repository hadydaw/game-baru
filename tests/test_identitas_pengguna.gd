extends GutTest

# Nama operator dari Login menjadi identitas Terminal: prompt, whoami, home, dan kepemilikan file.

const BERKAS_PENGATURAN := "user://uji_identitas_pengaturan.json"
const BERKAS_SIMPAN := "user://uji_identitas_sesi.json"

func _fs_operator() -> Dictionary:
	var dokumen := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {
		"kunci_arsip.txt": {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "arsip:TK-7731", "ukuran": 13}
	}}
	var readme := {"tipe": "file", "pemilik": "operator", "grup": "operator", "izin": "rw-r-----", "isi": "halo", "ukuran": 4}
	var rumah := {"tipe": "dir", "pemilik": "operator", "grup": "operator", "izin": "rwxr-x---", "isi": {"dokumen": dokumen, "readme.txt": readme}}
	return {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {
		"home": {"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {"operator": rumah}}
	}}

func before_each() -> void:
	Pengaturan.berkas_aktif = BERKAS_PENGATURAN
	Penyimpanan.berkas_aktif = BERKAS_SIMPAN
	for b in [BERKAS_PENGATURAN, BERKAS_SIMPAN]:
		if FileAccess.file_exists(b):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(b))
	Pengaturan.set_nama_profil("irmod")

func after_all() -> void:
	Pengaturan.berkas_aktif = Pengaturan.BERKAS
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS

func test_whoami_dan_prompt_memakai_nama_login() -> void:
	var s := ShellSession.new(Vfs.new(Vfs.ganti_pengguna(_fs_operator(), "operator", "irmod")), null, "irmod")
	assert_eq(s.jalankan("whoami")[0]["teks"], "irmod")
	assert_eq(s.home, "/home/irmod")
	assert_eq(s.cwd, "/home/irmod")
	assert_eq(s.prompt(), "irmod@jtn:~$")

func test_home_dan_pemilik_berkas_berpindah_tanpa_mengubah_isi() -> void:
	var fs := Vfs.ganti_pengguna(_fs_operator(), "operator", "irmod")
	var v := Vfs.new(fs)
	assert_true(v.ada("/home/irmod/readme.txt"), "readme ikut pindah")
	assert_false(v.ada("/home/operator"), "home lama tidak ada lagi")
	assert_eq(v.ambil("/home/irmod/readme.txt")["pemilik"], "irmod")
	assert_eq(v.ambil("/home/irmod/readme.txt")["isi"], "halo")

func test_pemilik_bisa_membaca_berkas_sendiri() -> void:
	var s := ShellSession.new(Vfs.new(Vfs.ganti_pengguna(_fs_operator(), "operator", "irmod")), null, "irmod")
	var keluaran := s.jalankan("cat readme.txt")
	assert_eq(keluaran[0]["teks"], "halo", "pemilik baru bisa membaca berkasnya")

func test_simpanan_lama_dipetakan_ke_nama_login() -> void:
	var lama := ShellSession.new(Vfs.new(_fs_operator()), null, "operator")
	lama.jalankan("cd dokumen")
	var data := lama.to_dict()
	data.erase("pengguna")  # simpanan dari versi sebelum identitas disimpan
	var s := ShellSession.dari_dict(data)
	assert_eq(s.user, "irmod")
	assert_eq(s.cwd, "/home/irmod/dokumen", "direktori kerja ikut pindah")
	assert_true(s.fs.ada("/home/irmod/dokumen/kunci_arsip.txt"), "isi berkas tetap ada")

func test_nama_tersimpan_ikut_saat_dimuat_ulang() -> void:
	var s := ShellSession.new(Vfs.new(Vfs.ganti_pengguna(_fs_operator(), "operator", "irmod")), null, "irmod")
	var pulih := ShellSession.dari_dict(s.to_dict())
	assert_eq(pulih.user, "irmod")
	assert_eq(pulih.prompt(), "irmod@jtn:~$")

func test_sesi_berjalan_mengikuti_ganti_nama() -> void:
	var s := ShellSession.new(_fs_v(), null, "operator")
	s.jalankan("cd dokumen")
	s.sinkron_pengguna("irmod")
	assert_eq(s.prompt(), "irmod@jtn:~/dokumen$")
	assert_true(s.fs.ada("/home/irmod/dokumen"))

func test_ssh_tetap_memakai_akun_server_dan_kunci_lokal() -> void:
	var s := ShellSession.new(Vfs.new(Vfs.ganti_pengguna(_fs_operator(), "operator", "irmod")), null, "irmod")
	s.jalankan("ping -c 1 gerbang")
	s.jalankan("scan 10.7.0.8")
	s.jalankan("ssh operator@arsip")
	assert_not_null(s.ssh_aktif, "ssh ke akun operator milik server tetap berhasil")
	assert_eq(s.ssh_aktif.user, "operator", "akun di server tetap operator")
	assert_eq(s.ssh_aktif.cwd, "/home/operator")
	s.jalankan("exit")
	assert_null(s.ssh_aktif)

func _fs_v() -> Vfs:
	return Vfs.new(_fs_operator())
