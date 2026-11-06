extends GutTest

# Setiap langkah misi 1 membawa alasan dan pengetahuan. Pengetahuan tampil di aplikasi Misi,
# sedangkan email langkah tetap singkat dan mengarahkan pemain ke aplikasi Misi.

func before_each() -> void:
	Bahasa.kode = "id"

func _sesi() -> ShellSession:
	return ShellSession.new(Vfs.new({"tipe": "dir", "pemilik": "root", "grup": "root", "izin": "rwxr-xr-x", "isi": {}}), Jaringan.muat(), "operator")

func test_setiap_langkah_punya_alasan_dan_pengetahuan() -> void:
	var m := Misi.temukan("misi_1")
	assert_eq((m["tahap"] as Array).size(), 26, "misi 1 punya 26 langkah")
	for i in range(m["tahap"].size()):
		var t: Dictionary = m["tahap"][i]
		# Langkah penyelesaian tidak punya tindakan, jadi tidak memerlukan alasan.
		var punya_tujuan := false
		for g in m["tujuan"]:
			if int(g["tahap"]) == i + 1:
				punya_tujuan = true
		if not punya_tujuan:
			continue
		assert_true(String(t.get("alasan", "")).length() > 10, "alasan terisi: " + Bahasa.pilih(String(t["judul"])))
		assert_true(String(t.get("pengetahuan", "")).length() > 40, "pengetahuan terisi: " + Bahasa.pilih(String(t["judul"])))

func test_email_langkah_mengarahkan_ke_aplikasi_misi() -> void:
	var s := _sesi()
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	var email_tahap_1 := ""
	for p in s.pesan_misi:
		if Bahasa.pilih(String(p["subjek"])).contains("Tahap 1"):
			email_tahap_1 = Bahasa.pilih(String(p["isi"]))
	assert_true(email_tahap_1.contains("Buka aplikasi Misi"), "email langkah mengarahkan ke Misi")
	assert_false(email_tahap_1.contains("Pengetahuan:"), "pengetahuan tidak menumpuk di email")

func test_pengetahuan_tampil_di_aplikasi_misi_untuk_langkah_aktif() -> void:
	var s := _sesi()
	Misi.perbarui(s)
	Misi.terima(s, "misi_1")
	var progres := Misi.tahap_progres(s, Misi.temukan("misi_1"))
	assert_true(String(progres[0]["pengetahuan"]).length() > 40, "langkah aktif membawa pengetahuan")
	assert_true(String(progres[0]["alasan"]).length() > 10, "langkah aktif membawa alasan")
