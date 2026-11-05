extends GutTest

# Uji perintah scan: identifikasi perangkat lewat IP, pemisahan dari ssh/ping/nmap, dan penyimpanan.

const BERKAS := "user://test_scan_fs.json"

func _sesi() -> ShellSession:
	var isi := FileAccess.get_file_as_string("res://data/fs/pemain.json")
	var data: Dictionary = JSON.parse_string(isi)
	return ShellSession.new(Vfs.new(data["/"]))

func _teks(hasil: Array) -> String:
	var baris: Array = []
	for b in hasil:
		baris.append(Bahasa.pilih(String(b["teks"])))
	return "\n".join(PackedStringArray(baris))

func _galat(hasil: Array) -> bool:
	for b in hasil:
		if String(b["tipe"]) == "error":
			return true
	return false

func test_scan_arsip_menemukan_dan_menampilkan_identitas():
	var s := _sesi()
	var hasil := s.jalankan("scan 10.7.0.8")
	assert_false(_galat(hasil))
	var t := _teks(hasil)
	assert_true(t.contains("Perangkat ditemukan: arsip"))
	assert_true(t.contains("IP      : 10.7.0.8"))
	assert_true(t.contains("Status  : Aktif"))
	assert_true(s.jaringan.dikenal("arsip"), "node terbuka setelah scan")

func test_scan_ip_tidak_dikenal_galat():
	var s := _sesi()
	var hasil := s.jalankan("scan 10.9.9.9")
	assert_true(_galat(hasil))
	assert_true(_teks(hasil).contains("Tidak ada perangkat yang ditemukan pada 10.9.9.9"))
	assert_false(s.jaringan.dikenal("arsip"))

func test_scan_tanpa_argumen_dan_format_salah_galat():
	var s := _sesi()
	assert_true(_galat(s.jalankan("scan")))
	assert_true(_teks(s.jalankan("scan arsip")).contains("masukkan alamat IP"))

func test_scan_tidak_memberi_akses_ssh():
	var s := _sesi()
	s.jalankan("scan 10.7.0.8")
	assert_false(s.jaringan.progres.has("ssh:arsip"), "scan tidak menandai login")
	assert_true(s.jaringan.progres.has("pindai:arsip"), "scan menandai pemindaian")

func test_trace_tidak_membuka_node_scan_sebelum_scan():
	var s := _sesi()
	s.inventory.miliki("signal_tracer", "awal", 3)
	s.jalankan("ping -c 1 gerbang")
	var t := _teks(s.jalankan("trace gerbang"))
	assert_false(t.contains("arsip"), "trace tidak menampilkan node scan")
	assert_false(s.jaringan.dikenal("arsip"))

func test_migrasi_idempoten_dan_tidak_mengubah_progres_lain():
	var s := _sesi()
	s.jaringan.tandai_ditemukan("arsip")
	PerintahScan.migrasi(s)
	PerintahScan.migrasi(s)
	var jumlah := 0
	for id in s.jaringan.ditemukan:
		if id == "arsip":
			jumlah += 1
	assert_eq(jumlah, 1, "penemuan tidak digandakan")
	assert_true(s.jaringan.progres.has("pindai:arsip"))
	assert_eq(s.jaringan.progres.count("pindai:arsip"), 1, "flag tidak digandakan")

func test_hasil_scan_bertahan_setelah_simpan_dan_muat():
	var s := _sesi()
	s.jalankan("scan 10.7.0.8")
	assert_true(Penyimpanan.simpan_sesi(s, BERKAS))
	var pulih := ShellSession.dari_dict(Penyimpanan.muat(BERKAS)["data"])
	assert_true(pulih.jaringan.dikenal("arsip"), "penemuan tersimpan")
	assert_true(pulih.jaringan.sudah_dipindai("arsip") or pulih.jaringan.progres.has("pindai:arsip"), "status pindai tersimpan")
	assert_false(pulih.jaringan.progres.has("ssh:arsip"), "tidak ada login palsu")
