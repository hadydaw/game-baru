class_name PusatMisi
extends Control

# Aplikasi Misi. Tiga tampilan:
#   1. Misi Tersedia: kisi kategori dengan ikon.
#   2. Daftar kategori: baris misi di atas, panel Deskripsi di bawah (Tujuan, Pembayaran, Persyaratan).
#      RINCIAN membuka detail lengkap; MENERIMA membuka pesan misi itu.
#   3. Pembaca pesan: kepala DARI dan JUDUL, isi pesan, lalu KELUAR atau MENGHAPUS.
# Membaca sesi yang sama dengan Terminal. Misi yang belum diterima tidak ditampilkan.

const LATAR_KARTU := Color(0.04, 0.07, 0.09, 1.0)
const LATAR_BARIS := Color(0.05, 0.1, 0.12, 1.0)

var _sesi: ShellSession
var _terpilih := ""              # kunci kategori yang disorot di kisi
var _tampil_daftar := ""         # kunci kategori yang daftarnya tampil; "" = kisi kategori
var _misi_terpilih := ""         # id misi yang sedang disorot di daftar
var _rincian := false            # panel Deskripsi menampilkan detail lengkap
var _belajar := false            # panel Deskripsi menampilkan materi pembelajaran, bukan tugas
var _tahap_belajar := -1         # nomor tahap (dari 0) yang materinya dibuka; -1 = tahap aktif
var _judul: Label
var _kisi_wrap: VBoxContainer
var _grid: GridContainer
var _tombol_kategori: Dictionary = {}
var _daftar_wrap: VBoxContainer
var _kolom_misi: VBoxContainer
var _isi_deskripsi: VBoxContainer
var _hint: Label
var _bawah: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesi = SesiUtama.ambil()
	var latar := ColorRect.new()
	latar.color = Color("0d1117")
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(margin, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	_judul = Tema.label("", Tema.TEAL, 34)
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_judul)

	# Kisi kategori.
	_kisi_wrap = VBoxContainer.new()
	_kisi_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_kisi_wrap)
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_kisi_wrap.add_child(gulir)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	gulir.add_child(_grid)

	# Daftar misi: atas berisi baris misi, bawah berisi panel Deskripsi.
	_daftar_wrap = VBoxContainer.new()
	_daftar_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_daftar_wrap.add_theme_constant_override("separation", 12)
	_daftar_wrap.visible = false
	root.add_child(_daftar_wrap)
	var gulir_daftar := ScrollContainer.new()
	gulir_daftar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir_daftar.size_flags_stretch_ratio = 1.0
	gulir_daftar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_daftar_wrap.add_child(gulir_daftar)
	_kolom_misi = VBoxContainer.new()
	_kolom_misi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom_misi.add_theme_constant_override("separation", 10)
	gulir_daftar.add_child(_kolom_misi)
	var kartu_deskripsi := PanelContainer.new()
	kartu_deskripsi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kartu_deskripsi.size_flags_stretch_ratio = 1.6
	kartu_deskripsi.add_theme_stylebox_override("panel", Tema.kotak(LATAR_KARTU, Tema.TEAL, 2, 14))
	_daftar_wrap.add_child(kartu_deskripsi)
	var gulir_deskripsi := ScrollContainer.new()
	gulir_deskripsi.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kartu_deskripsi.add_child(gulir_deskripsi)
	var pad_deskripsi := MarginContainer.new()
	pad_deskripsi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tema.margin_seragam(pad_deskripsi, 18)
	gulir_deskripsi.add_child(pad_deskripsi)
	_isi_deskripsi = VBoxContainer.new()
	_isi_deskripsi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_isi_deskripsi.add_theme_constant_override("separation", 14)
	pad_deskripsi.add_child(_isi_deskripsi)

	_hint = Tema.label("", Tema.AMBER, 22)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	_bawah = HBoxContainer.new()
	_bawah.add_theme_constant_override("separation", 14)
	root.add_child(_bawah)

	Bahasa.daftar_penyegar(self, _segarkan_semua)

# Semua tampilan dibangun ulang dari data sesi dan bahasa aktif, sehingga selalu sesuai.
func _segarkan_semua() -> void:
	if _tampil_daftar == "":
		_misi_terpilih = ""
		_rincian = false
		_belajar = false
		_tahap_belajar = -1
	_judul.text = Bahasa.t("misi.judul_tersedia") if _tampil_daftar == "" else Bahasa.t(_judul_kategori(_tampil_daftar))
	_kisi_wrap.visible = _tampil_daftar == ""
	_daftar_wrap.visible = _tampil_daftar != ""
	if _kisi_wrap.visible:
		_bangun_kisi()
	if _daftar_wrap.visible:
		_bangun_daftar()
	_bangun_tombol()
	_hint.text = ""

func _judul_kategori(kunci: String) -> String:
	for k in Misi.KATEGORI:
		if String(k["kunci"]) == kunci:
			return String(k["judul"])
	return "misi.judul_tersedia"

# Kisi kategori: setiap sel berisi ikon, nama kategori, dan jumlah misi.
func _bangun_kisi() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_tombol_kategori.clear()
	for k in Misi.KATEGORI:
		var kunci := String(k["kunci"])
		var tombol := Button.new()
		tombol.focus_mode = Control.FOCUS_NONE
		tombol.custom_minimum_size = Vector2(0, 250)
		tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dipilih := kunci == _terpilih
		var batas := Tema.AMBER if dipilih else Tema.TEAL
		tombol.add_theme_stylebox_override("normal", Tema.kotak(LATAR_KARTU, batas, 3 if dipilih else 2, 14))
		tombol.add_theme_stylebox_override("hover", Tema.kotak(LATAR_KARTU, Tema.AMBER, 3, 14))
		tombol.add_theme_stylebox_override("pressed", Tema.kotak(LATAR_KARTU, Tema.AMBER, 3, 14))
		tombol.add_theme_stylebox_override("focus", Tema.kotak(LATAR_KARTU, Tema.AMBER, 3, 14))

		var pad := MarginContainer.new()
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		Tema.margin_seragam(pad, 14)
		tombol.add_child(pad)
		var isi := VBoxContainer.new()
		isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.alignment = BoxContainer.ALIGNMENT_CENTER
		isi.add_theme_constant_override("separation", 10)
		pad.add_child(isi)

		var ikon := TextureRect.new()
		ikon.texture = load(Misi.ikon_kategori(kunci)) as Texture2D
		ikon.custom_minimum_size = Vector2(0, 110)
		ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.add_child(ikon)

		var nama := Tema.label(Bahasa.t(String(k["judul"])), Tema.TEKS, 24)
		nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nama.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.add_child(nama)

		var banyak := Misi.daftar_kategori(kunci).size()
		var jumlah := Tema.label(Bahasa.t("misi.jumlah") % banyak if banyak > 0 else Bahasa.t("misi.belum_ada_kategori"), Tema.TEKS_REDUP, 20)
		jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jumlah.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.add_child(jumlah)

		tombol.pressed.connect(_pilih_kategori.bind(kunci))
		_grid.add_child(tombol)
		_tombol_kategori[kunci] = tombol

func _pilih_kategori(kunci: String) -> void:
	_terpilih = kunci
	_hint.text = ""
	_bangun_kisi()
	_bangun_tombol()

# Baris tampilan dengan ikon di kiri, judul, dan keterangan.
func _baris(ikon_path: String, judul: String, keterangan: String, dipilih: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 124)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var batas := Tema.AMBER if dipilih else Tema.TEAL
	b.add_theme_stylebox_override("normal", Tema.kotak(LATAR_BARIS, batas, 3 if dipilih else 2, 14))
	b.add_theme_stylebox_override("hover", Tema.kotak(LATAR_BARIS, Tema.AMBER, 3, 14))
	b.add_theme_stylebox_override("pressed", Tema.kotak(LATAR_BARIS, Tema.AMBER, 3, 14))
	b.add_theme_stylebox_override("focus", Tema.kotak(LATAR_BARIS, Tema.AMBER, 3, 14))
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(pad, 12)
	b.add_child(pad)
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 16)
	pad.add_child(hb)
	var ikon := TextureRect.new()
	ikon.texture = load(ikon_path) as Texture2D
	ikon.custom_minimum_size = Vector2(96, 96)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(ikon)
	var kolom := VBoxContainer.new()
	kolom.alignment = BoxContainer.ALIGNMENT_CENTER
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(kolom)
	var l_judul := Tema.label(judul, Tema.AMBER if dipilih else Tema.TEKS, 28)
	l_judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_judul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_child(l_judul)
	if keterangan != "":
		var l_ket := Tema.label(keterangan, Tema.TEKS_REDUP, 20)
		l_ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_ket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kolom.add_child(l_ket)
	return b

# Daftar: baris misi, lalu panel Deskripsi untuk misi yang disorot. Pesan misi ada di aplikasi Email.
func _bangun_daftar() -> void:
	for c in _kolom_misi.get_children():
		c.queue_free()
	for c in _isi_deskripsi.get_children():
		c.queue_free()
	var misi_kat := Misi.daftar_kategori(_tampil_daftar)
	if misi_kat.is_empty():
		_kolom_misi.add_child(_teks(Bahasa.t("misi.kategori_kosong"), Tema.TEKS_REDUP, 22))
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.tidak_aktif"), Tema.TEKS_REDUP, 22))
		return

	var terlihat: Array = []
	for m in misi_kat:
		var st := String(_sesi.misi.get(String(m["id"]), ""))
		if st == "aktif" or st == "selesai" or Misi.tersedia(_sesi, m):
			terlihat.append(m)
	if not terlihat.has(_cari_misi(_misi_terpilih)):
		_misi_terpilih = String(terlihat[0]["id"]) if not terlihat.is_empty() else ""

	for m in terlihat:
		var id := String(m["id"])
		var selesai := String(_sesi.misi.get(id, "")) == "selesai"
		var ket := Bahasa.t("misi.tag_selesai").strip_edges() if selesai else ""
		var b := _baris(Misi.ikon_kategori(String(m.get("kategori", _tampil_daftar))), String(m["judul"]), ket, id == _misi_terpilih)
		b.pressed.connect(_pilih_misi.bind(id))
		_kolom_misi.add_child(b)

	if _misi_terpilih == "":
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.tidak_aktif"), Tema.TEKS_REDUP, 22))
		return
	var terpilih := _cari_misi(_misi_terpilih)
	if _belajar and terpilih.has("tahap"):
		_isi_panel_belajar(terpilih)
		return
	_isi_panel_deskripsi(terpilih)

# Panel Pembelajaran: materi satu tahap, dipisah dari daftar tugas. Hanya berisi penjelasan.
func _isi_panel_belajar(m: Dictionary) -> void:
	_isi_deskripsi.add_child(_teks(Bahasa.t("misi.pembelajaran"), Tema.AMBER, 34, HORIZONTAL_ALIGNMENT_CENTER))
	var jumlah := Misi.pembelajaran(String(m["id"])).size()
	if jumlah == 0:
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.materi_kosong"), Tema.TEKS_REDUP, 22))
		return
	var idx := _indeks_belajar(m)
	var materi := Misi.materi_tahap(String(m["id"]), idx + 1)
	_isi_deskripsi.add_child(_teks(Bahasa.t("misi.materi_tahap") % [idx + 1, jumlah], Tema.TEKS_REDUP, 22, HORIZONTAL_ALIGNMENT_CENTER))
	_isi_deskripsi.add_child(_teks(String(materi.get("judul", "")), Tema.TEAL, 30))
	var bagian := [
		["misi.materi_konsep", "konsep"],
		["misi.materi_cara", "cara_kerja"],
		["misi.materi_contoh", "contoh"],
		["misi.materi_hubungan", "hubungan"],
		["misi.materi_ringkasan", "ringkasan"],
	]
	for b in bagian:
		_isi_deskripsi.add_child(_teks(Bahasa.t(String(b[0])), Tema.AMBER, 24))
		_isi_deskripsi.add_child(_teks(String(materi.get(String(b[1]), "")), Tema.TEKS, 22))

# Nomor tahap (dari 0) yang materinya sedang dibuka. Bila belum dipilih, tahap yang sedang dikerjakan.
func _indeks_belajar(m: Dictionary) -> int:
	var jumlah := Misi.pembelajaran(String(m["id"])).size()
	if _tahap_belajar >= 0:
		return clampi(_tahap_belajar, 0, max(jumlah - 1, 0))
	var progres := Misi.tahap_progres(_sesi, m)
	for i in range(progres.size()):
		if not bool(progres[i]["selesai"]):
			return i
	return max(progres.size() - 1, 0)

# Isi panel Deskripsi. Mode ringkas: Tujuan, Pembayaran, Persyaratan. Mode RINCIAN: detail lengkap.
func _isi_panel_deskripsi(m: Dictionary) -> void:
	_isi_deskripsi.add_child(_teks(Bahasa.t("misi.deskripsi"), Tema.AMBER, 34, HORIZONTAL_ALIGNMENT_CENTER))
	if not _rincian:
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.tujuan_ringkas") % String(m.get("tujuan_ringkas", "")), Tema.TEKS, 26, HORIZONTAL_ALIGNMENT_CENTER))
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.pembayaran") % _kredit_hadiah(String(m["id"])), Tema.TEKS, 26, HORIZONTAL_ALIGNMENT_CENTER))
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.persyaratan") % String(m.get("persyaratan", "-")), Tema.TEKS, 26, HORIZONTAL_ALIGNMENT_CENTER))
		return
	_isi_deskripsi.add_child(_teks(String(m["latar"]), Tema.TEKS, 22))
	_isi_deskripsi.add_child(_teks(Bahasa.t("misi.target") % Misi.ganti_ip(_sesi, String(m["target"])), Tema.TEKS, 22))
	if m.has("node"):
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.ip_target") % _sesi.jaringan.ip(String(m["node"])), Tema.TEAL, 22))
	var petunjuk := Misi.petunjuk_ditemukan(_sesi, m)
	_isi_deskripsi.add_child(_teks(Bahasa.t("misi.petunjuk") % [petunjuk.size(), m.get("petunjuk", []).size()], Tema.TEKS_REDUP, 22))
	for t in petunjuk:
		_isi_deskripsi.add_child(_teks("· " + String(t), Tema.TEKS, 22))
	if m.has("tahap"):
		var progres := Misi.tahap_progres(_sesi, m)
		var aktif := -1
		for i in range(progres.size()):
			if not bool(progres[i]["selesai"]):
				aktif = i
				break
		# Tutorial dipandu satu langkah: langkah aktif menjelaskan alasan dan pengetahuannya.
		if aktif >= 0:
			_isi_deskripsi.add_child(_teks(Bahasa.t("misi.langkah") % [aktif + 1, progres.size()], Tema.AMBER, 22))
			_isi_deskripsi.add_child(_teks(Bahasa.t("misi.alasan") + ": " + String(progres[aktif]["alasan"]), Tema.TEKS, 21))
			if String(progres[aktif]["pengetahuan"]) != "":
				_isi_deskripsi.add_child(_teks(Bahasa.t("misi.pengetahuan") + ": " + String(progres[aktif]["pengetahuan"]), Tema.TEKS_REDUP, 20))
		for i in range(progres.size()):
			var tahap: Dictionary = progres[i]
			var selesai := bool(tahap["selesai"])
			_isi_deskripsi.add_child(_baris_ceklis(selesai, String(tahap["judul"]), Tema.AMBER if selesai else (Tema.TEKS if i == aktif else Tema.TEKS_REDUP), 24, 0))
			for t in tahap["tujuan"]:
				_isi_deskripsi.add_child(_baris_ceklis(bool(t["selesai"]), String(t["teks"]), Tema.TEAL if bool(t["selesai"]) else Tema.TEKS_REDUP, 21, 28))
	else:
		_isi_deskripsi.add_child(_teks(Bahasa.t("misi.tujuan"), Tema.TEKS, 22))
		for t in Misi.status_tujuan(_sesi, m):
			_isi_deskripsi.add_child(_baris_ceklis(bool(t["selesai"]), String(t["teks"]), Tema.TEAL if bool(t["selesai"]) else Tema.TEKS, 22, 0))
	_isi_deskripsi.add_child(_teks(_teks_hadiah(String(m["id"])), Tema.TEKS_REDUP, 22))

# Satu baris tahap atau tujuan: ceklis di kiri, teks di kanan. Menjorok bila tujuan berada di dalam tahap.
func _baris_ceklis(selesai: bool, teks: String, warna: Color, ukuran: int, jorok: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tepi := Control.new()
	tepi.custom_minimum_size = Vector2(jorok, 0)
	tepi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tepi)
	var pusat := CenterContainer.new()
	pusat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pusat.add_child(Ceklis.new(selesai))
	h.add_child(pusat)
	var label := _teks(teks, warna, ukuran)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(label)
	return h

func _pilih_misi(id: String) -> void:
	_misi_terpilih = id
	_rincian = false
	_belajar = false
	_tahap_belajar = -1
	_segarkan_semua()

# Tombol bawah per tampilan.
func _bangun_tombol() -> void:
	for c in _bawah.get_children():
		c.queue_free()
	if _tampil_daftar != "":
		var m := _cari_misi(_misi_terpilih)
		if _belajar and m.has("tahap"):
			_bangun_tombol_belajar(m)
			return
		var keluar := _tombol_bawah(Bahasa.t("misi.tombol_keluar"), Tema.TEKS_REDUP, true)
		keluar.pressed.connect(func():
			_tampil_daftar = ""
			_misi_terpilih = ""
			_rincian = false
			_segarkan_semua())
		_bawah.add_child(keluar)
		var ada := _misi_terpilih != ""
		var bisa_terima := ada and Misi.tersedia(_sesi, m)
		var terima := _tombol_bawah(Bahasa.t("misi.tombol_terima"), Tema.TEAL, bisa_terima)
		terima.pressed.connect(_terima_misi)
		_bawah.add_child(terima)
		var rincian := _tombol_bawah(Bahasa.t("misi.tombol_rincian"), Tema.TEAL, ada)
		rincian.pressed.connect(func():
			_rincian = not _rincian
			_segarkan_semua())
		_bawah.add_child(rincian)
		# Materi tutorial terbuka setelah misi diterima.
		if m.has("tahap"):
			var sudah_terima := ada and (String(_sesi.misi.get(_misi_terpilih, "")) == "aktif" or String(_sesi.misi.get(_misi_terpilih, "")) == "selesai")
			var belajar := _tombol_bawah(Bahasa.t("misi.tombol_belajar"), Tema.TEAL, sudah_terima and not Misi.pembelajaran(_misi_terpilih).is_empty(), 24)
			belajar.pressed.connect(func():
				_belajar = true
				_rincian = false
				_tahap_belajar = -1
				_segarkan_semua())
			_bawah.add_child(belajar)
		return
	var keluar_kisi := _tombol_bawah(Bahasa.t("misi.tombol_keluar"), Tema.TEKS_REDUP, true)
	keluar_kisi.pressed.connect(func():
		_terpilih = ""
		_hint.text = ""
		_bangun_kisi())
	_bawah.add_child(keluar_kisi)
	var pilih := _tombol_bawah(Bahasa.t("misi.tombol_pilih"), Tema.TEAL, _terpilih != "")
	pilih.pressed.connect(func():
		if _terpilih == "":
			_hint.text = Bahasa.t("misi.pilih_kategori")
			return
		_tampil_daftar = _terpilih
		_segarkan_semua())
	_bawah.add_child(pilih)

# MENERIMA: misi diterima pemain, lalu pesan masuk ke aplikasi Email.
func _terima_misi() -> void:
	if _misi_terpilih == "" or not Misi.terima(_sesi, _misi_terpilih):
		return
	Penyimpanan.simpan_sesi(_sesi)
	_segarkan_semua()
	_hint.text = Bahasa.t("misi.diterima")

# Tombol bawah saat materi pembelajaran dibuka: kembali ke tugas, dan pindah antar tahap.
func _bangun_tombol_belajar(m: Dictionary) -> void:
	var jumlah := Misi.pembelajaran(String(m["id"])).size()
	var idx := _indeks_belajar(m)
	var kembali := _tombol_bawah(Bahasa.t("misi.tombol_kembali"), Tema.TEKS_REDUP, true)
	kembali.pressed.connect(func():
		_belajar = false
		_tahap_belajar = -1
		_segarkan_semua())
	_bawah.add_child(kembali)
	var sebelum := _tombol_bawah(Bahasa.t("misi.tombol_sebelumnya"), Tema.TEAL, idx > 0, 24)
	sebelum.pressed.connect(func():
		_tahap_belajar = idx - 1
		_segarkan_semua())
	_bawah.add_child(sebelum)
	var sesudah := _tombol_bawah(Bahasa.t("misi.tombol_berikutnya"), Tema.TEAL, idx < jumlah - 1, 24)
	sesudah.pressed.connect(func():
		_tahap_belajar = idx + 1
		_segarkan_semua())
	_bawah.add_child(sesudah)

func _tombol_bawah(teks: String, warna_batas: Color, aktif: bool, ukuran: int = 30) -> Button:
	var b := Button.new()
	b.text = Bahasa.pilih(teks)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not aktif
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", ukuran)
	b.add_theme_color_override("font_color", Tema.TEKS)
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.45, 0.45))
	b.add_theme_stylebox_override("normal", Tema.kotak(Color(0.05, 0.1, 0.12), warna_batas, 2, 16))
	b.add_theme_stylebox_override("hover", Tema.kotak(Color(0.08, 0.18, 0.2), warna_batas, 2, 16))
	b.add_theme_stylebox_override("pressed", Tema.kotak(Color(0.08, 0.18, 0.2), warna_batas, 2, 16))
	b.add_theme_stylebox_override("disabled", Tema.kotak(Color(0.05, 0.06, 0.07), Color(0.25, 0.3, 0.3), 2, 16))
	return b

func _teks(isi: String, warna: Color, ukuran: int = 22, rata := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Tema.label(isi, warna, ukuran)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = rata
	return l

func _cari_misi(id: String) -> Dictionary:
	return Misi.temukan(id) if id != "" else {}

func _kredit_hadiah(id: String) -> int:
	return int(Hadiah.data().get(id, {}).get("kredit", 0))

func _teks_hadiah(id: String) -> String:
	var h: Dictionary = Hadiah.data().get(id, {})
	if h.is_empty():
		return Bahasa.t("misi.hadiah_kosong")
	var bagian: Array = [Bahasa.t("panel.saldo") % int(h.get("kredit", 0))]
	for g in h.get("reputasi", {}):
		bagian.append(Bahasa.t("misi.reputasi") % [g, int(h["reputasi"][g])])
	return Bahasa.t("misi.hadiah") + ", ".join(PackedStringArray(bagian))
