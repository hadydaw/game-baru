extends GutTest

# Peta Jaringan menampilkan identitas pemain dari sesi aktif (nama Login), bukan nama tetap.

func before_each() -> void:
	Penyimpanan.berkas_aktif = "user://uji_identitas_peta.json"
	Pengaturan.berkas_aktif = "user://uji_identitas_peta_pengaturan.json"
	if FileAccess.file_exists(Pengaturan.berkas_aktif):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Pengaturan.berkas_aktif))
	# Nama Login adalah sumber identitas; sesi disinkronkan dengannya saat Peta dibuka.
	Pengaturan.set_nama_profil("badai")
	SesiUtama.sesi = null

func after_all() -> void:
	Penyimpanan.berkas_aktif = Penyimpanan.BERKAS
	Pengaturan.berkas_aktif = Pengaturan.BERKAS

func _peta(ukuran: Vector2) -> NetworkMap:
	var wadah := Control.new()
	wadah.size = ukuran
	add_child(wadah)
	var peta := NetworkMap.new()
	peta.size = ukuran
	wadah.add_child(peta)
	return peta

func test_menampilkan_nama_login_aktif() -> void:
	var peta := _peta(Vector2(1080, 1920))
	await get_tree().process_frame
	assert_eq(peta.teks_identitas(), "Operator: badai | Perangkat: JTN | Status: Lokal")
	peta.get_parent().free()

func test_nama_ikut_sesi_setelah_ganti_nama() -> void:
	Pengaturan.set_nama_profil("irmod")
	var peta := _peta(Vector2(720, 1280))
	await get_tree().process_frame
	assert_true(peta.teks_identitas().begins_with("Operator: irmod"))
	peta.get_parent().free()

func test_identitas_tidak_terpotong_di_layar_sempit() -> void:
	for ukuran in [Vector2(720, 1280), Vector2(1080, 1920)]:
		var peta := _peta(ukuran)
		await get_tree().process_frame
		await get_tree().process_frame
		for l in peta._lbl_identitas:
			var r := (l as Label).get_global_rect()
			assert_true(r.position.x >= 0 and r.end.x <= ukuran.x, "label identitas di dalam lebar %s" % ukuran)
		peta.get_parent().free()
