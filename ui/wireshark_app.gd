class_name WiresharkApp
extends Control

# Aplikasi Wireshark di game. Tiga panel seperti Wireshark asli: daftar paket (No., Time, Source, Destination,
# Protocol, Length, Info), rincian protokol, dan bytes paket (heks dan ASCII) dengan sorotan rentang yang dipilih.
# Ada filter tampilan, statistik (ringkasan, hierarki protokol, percakapan), buka/simpan berkas .simcap,
# dan capture simulasi. Semua data berasal dari WiresharkModel; tidak ada lalu lintas jaringan nyata.

const WARNA_LATAR := Color("0d1117")
const WARNA_KERTAS := Color("f4f4f4")
const WARNA_TINTA := Color("1a1a1a")
const WARNA_SOROT := "#2dd4bf88"
const WARNA_GALAT := Color("f87171")
const JEDA_TANGKAP := 0.4
const BYTE_PER_BARIS := 16
const WARNA_PROTOKOL := {"tcp": "#e7e6ff", "udp": "#daeeff", "dns": "#d9f1ff", "http": "#e4ffc7",
	"icmp": "#fce0ff", "arp": "#faf0d7", "eapol": "#fff7b3", "802.11": "#e8e8e8"}
const KOLOM_JUDUL := ["kolom_no", "kolom_waktu", "kolom_sumber", "kolom_tujuan", "kolom_protokol", "kolom_panjang", "kolom_info"]
const LEBAR_KOLOM := [56, 120, 170, 170, 100, 88, 420]

var _sesi: ShellSession
var _model := WiresharkModel.new()
var _daftar: Tree
var _rincian: Tree
var _bytes: RichTextLabel
var _filter: LineEdit
var _hitung: Label
var _pesan: Label
var _btn_mulai: Button
var _btn_berhenti: Button
var _overlay: PanelContainer
var _overlay_judul: Label
var _overlay_isi: VBoxContainer
var _timer: Timer
var _galat := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesi = SesiUtama.ambil()
	var latar := ColorRect.new()
	latar.color = WARNA_LATAR
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Tema.margin_seragam(margin, 8)
	add_child(margin)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 6)
	margin.add_child(kolom)
	kolom.add_child(_bar_tombol())
	kolom.add_child(_bar_filter())
	var pisah := VSplitContainer.new()
	pisah.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kolom.add_child(pisah)
	_daftar = _buat_tree(KOLOM_JUDUL.size(), true)
	# Lebar kolom tetap seperti Wireshark asli; daftar yang lebih lebar dari layar digulir ke samping.
	for i in range(LEBAR_KOLOM.size()):
		_daftar.set_column_expand(i, false)
		_daftar.set_column_custom_minimum_width(i, LEBAR_KOLOM[i])
	_daftar.item_selected.connect(_pilih_paket)
	pisah.add_child(_daftar)
	_rincian = _buat_tree(1, false)
	_rincian.set_column_expand(0, false)
	_rincian.set_column_custom_minimum_width(0, 760)
	_rincian.item_selected.connect(_pilih_rincian)
	pisah.add_child(_rincian)
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	gulir.custom_minimum_size = Vector2(0, 120)
	var panel_bytes := PanelContainer.new()
	panel_bytes.add_theme_stylebox_override("panel", Tema.kotak(WARNA_KERTAS, Color("8a8a8a"), 1, 4))
	panel_bytes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gulir.add_child(panel_bytes)
	_bytes = RichTextLabel.new()
	_bytes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bytes.bbcode_enabled = true
	_bytes.fit_content = true
	_bytes.scroll_active = false
	_bytes.selection_enabled = true
	_bytes.add_theme_color_override("default_color", WARNA_TINTA)
	_bytes.add_theme_font_override("normal_font", _mono())
	_bytes.add_theme_font_size_override("normal_font_size", 16)
	panel_bytes.add_child(_bytes)
	pisah.add_child(gulir)
	_hitung = Tema.label("", Tema.TEKS, 18)
	kolom.add_child(_hitung)
	_pesan = Tema.label("", Tema.TEKS_REDUP, 18)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(_pesan)
	_buat_overlay()
	_timer = Timer.new()
	_timer.wait_time = JEDA_TANGKAP
	_timer.timeout.connect(_tangkap_langkah)
	add_child(_timer)
	segarkan_data()

# Dipanggil saat jendela sudah terbuka dan perintah 'wireshark' dijalankan lagi.
func segarkan_data() -> void:
	var p: Dictionary = _sesi.wireshark_perintah
	_sesi.wireshark_perintah = {}
	if p.has("paket"):
		_muat({"paket": p["paket"], "antarmuka": p.get("antarmuka", "")}, String(p.get("judul", "")))
	elif p.has("tangkap"):
		_mulai_tangkap(String(p["tangkap"]))
	_catat("wireshark:buka")
	_segar()

func _exit_tree() -> void:
	if _timer != null:
		_timer.stop()

# ---------------------------------------------------------------- bangun tampilan
func _bar_tombol() -> HBoxContainer:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	baris.add_child(_tombol(Bahasa.t("wireshark.buka"), _buka_dialog))
	_btn_mulai = _tombol(Bahasa.t("wireshark.mulai"), _pilih_antarmuka)
	baris.add_child(_btn_mulai)
	_btn_berhenti = _tombol(Bahasa.t("wireshark.berhenti"), _berhenti)
	_btn_berhenti.disabled = true
	baris.add_child(_btn_berhenti)
	baris.add_child(_tombol(Bahasa.t("wireshark.simpan"), _simpan_dialog))
	baris.add_child(_tombol(Bahasa.t("wireshark.statistik"), _statistik))
	return baris

func _bar_filter() -> HBoxContainer:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	_filter = LineEdit.new()
	_filter.placeholder_text = Bahasa.t("wireshark.filter_isi")
	_filter.keep_editing_on_text_submit = true
	_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter.custom_minimum_size = Vector2(0, 56)
	_filter.add_theme_font_size_override("font_size", 20)
	_filter.text_submitted.connect(func(_t): _terapkan())
	baris.add_child(_filter)
	baris.add_child(_tombol(Bahasa.t("wireshark.terapkan"), _terapkan))
	baris.add_child(_tombol(Bahasa.t("wireshark.hapus"), _hapus_filter))
	return baris

func _tombol(teks: String, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(aksi)
	return b

func _buat_tree(kolom: int, berjudul: bool) -> Tree:
	var t := Tree.new()
	t.columns = kolom
	t.hide_root = true
	t.select_mode = Tree.SELECT_ROW
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	t.custom_minimum_size = Vector2(0, 180)
	t.add_theme_font_override("font", _mono())
	t.add_theme_font_size_override("font_size", 17)
	t.add_theme_color_override("font_color", WARNA_TINTA)
	t.add_theme_color_override("font_selected_color", WARNA_TINTA)
	t.add_theme_stylebox_override("panel", Tema.kotak(WARNA_KERTAS, Color("8a8a8a"), 1, 4))
	t.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if berjudul:
		t.column_titles_visible = true
		for i in range(KOLOM_JUDUL.size()):
			t.set_column_title(i, Bahasa.t("wireshark." + KOLOM_JUDUL[i]))
	return t

func _buat_overlay() -> void:
	_overlay = PanelContainer.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_theme_stylebox_override("panel", Tema.kotak(WARNA_LATAR, Tema.TEAL, 2, 12))
	_overlay.visible = false
	add_child(_overlay)
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	var margin := MarginContainer.new()
	Tema.margin_seragam(margin, 14)
	_overlay.add_child(margin)
	margin.add_child(kolom)
	_overlay_judul = Tema.label("", Tema.TEAL, 24)
	kolom.add_child(_overlay_judul)
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(gulir)
	_overlay_isi = VBoxContainer.new()
	_overlay_isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay_isi.add_theme_constant_override("separation", 8)
	gulir.add_child(_overlay_isi)
	kolom.add_child(_tombol(Bahasa.t("wireshark.tutup"), _tutup_overlay))

func _buka_overlay(judul: String) -> void:
	_overlay_judul.text = judul
	for anak in _overlay_isi.get_children():
		anak.queue_free()
	_overlay.visible = true

func _tutup_overlay() -> void:
	_overlay.visible = false

func _label_overlay(teks: String, warna: Color = Tema.TEKS) -> void:
	var l := Tema.label(teks, warna, 20)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_isi.add_child(l)

# Font monospace untuk daftar dan bytes; jatuh ke font default bila sistem tidak punya monospace.
func _mono() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Monospace", "Courier New", "DejaVu Sans Mono"])
	return f

# ---------------------------------------------------------------- aksi
func _terapkan() -> void:
	var galat := _model.terapkan_filter(_filter.text)
	_galat = "" if galat == "" else Bahasa.t("wireshark.filter_galat") % galat
	_segar()
	if galat == "" and _filter.text.strip_edges() != "":
		_cek_misi()

func _hapus_filter() -> void:
	_filter.text = ""
	_terapkan()

func _pilih_paket() -> void:
	var item := _daftar.get_selected()
	if item == null:
		return
	_model.pilih(int(item.get_metadata(0)))
	_tampil_rincian()
	_cek_misi()

func _pilih_rincian() -> void:
	var item := _rincian.get_selected()
	if item == null or item.get_metadata(0) == null:
		return
	var rentang: Dictionary = item.get_metadata(0)
	_sorot(int(rentang["mulai"]), int(rentang["panjang"]))

func _buka_dialog() -> void:
	_buka_overlay(Bahasa.t("wireshark.buka_judul"))
	_label_overlay(Bahasa.t("wireshark.contoh"), Tema.TEAL)
	for id in WiresharkData.CONTOH:
		_overlay_isi.add_child(_tombol(String(id), _muat_contoh.bind(String(id))))
	_label_overlay(Bahasa.t("wireshark.berkas_saya"), Tema.TEAL)
	var simpanan := _berkas_simpan_saya()
	if simpanan.is_empty():
		_label_overlay(Bahasa.t("wireshark.tidak_ada_berkas"), Tema.TEKS_REDUP)
	for abs in simpanan:
		_overlay_isi.add_child(_tombol(_sesi.fs.nama_terakhir(abs), _muat_berkas.bind(abs)))

func _berkas_simpan_saya() -> Array:
	var hasil: Array = []
	var home := _sesi.fs.ambil(_sesi.home)
	var isi: Dictionary = home.get("isi", {}) if typeof(home.get("isi", {})) == TYPE_DICTIONARY else {}
	var nama := isi.keys()
	nama.sort()
	for n in nama:
		var node: Dictionary = isi[n]
		if String(n).ends_with(WiresharkData.EKSTENSI) and String(node.get("tipe", "")) == "file":
			hasil.append(_sesi.home.rstrip("/") + "/" + String(n))
	return hasil

func _muat_contoh(id: String) -> void:
	var d := WiresharkData.muat_contoh(id)
	if d.is_empty():
		_pesan.text = Bahasa.t("wireshark.buka_gagal") % id
		return
	_tutup_overlay()
	_model.muat_berkas({"paket": d["paket"], "antarmuka": d.get("antarmuka", "")}, id)
	_galat = ""
	_segar()

func _muat_berkas(abs: String) -> void:
	var node := _sesi.fs.ambil(abs)
	var r := WiresharkData.urai(ShellCommands.isi_berkas(node))
	if not bool(r["ok"]):
		_pesan.text = Bahasa.t("wireshark.buka_gagal") % _sesi.fs.nama_terakhir(abs)
		_tutup_overlay()
		return
	_tutup_overlay()
	_model.muat_berkas(r, _sesi.fs.nama_terakhir(abs))
	_galat = ""
	_segar()

func _pilih_antarmuka() -> void:
	if _model.menangkap:
		return
	_buka_overlay(Bahasa.t("wireshark.mulai"))
	for iface in WiresharkModel.antarmuka_tersedia(_sesi.wifi.monitor):
		_overlay_isi.add_child(_tombol(String(iface), _mulai_dari_dialog.bind(String(iface))))
	_label_overlay(Bahasa.t("wireshark.status_siap"), Tema.TEKS_REDUP)

func _mulai_dari_dialog(iface: String) -> void:
	_tutup_overlay()
	_mulai_tangkap(iface)

func _mulai_tangkap(iface: String) -> void:
	var skenario := WiresharkModel.skenario_untuk(iface, _sesi.wifi.monitor)
	if skenario == "":
		_galat = Bahasa.t("wireshark.iface_tidak_ada") % iface
		_segar()
		return
	var d := WiresharkData.muat_contoh(skenario)
	_model.mulai_tangkap(iface, d.get("paket", []))
	_galat = ""
	_timer.start()
	_catat("wireshark:tangkap")
	_segar()
	_pesan.text = Bahasa.t("wireshark.capture_mulai") % iface

func _tangkap_langkah() -> void:
	if not _model.tangkap_satu():
		_timer.stop()
		_pesan.text = Bahasa.t("wireshark.capture_selesai")
	_segar()

func _berhenti() -> void:
	_timer.stop()
	_model.berhenti_tangkap()
	_pesan.text = Bahasa.t("wireshark.capture_berhenti")
	_segar()

func _simpan_dialog() -> void:
	if not _model.punya_paket():
		_pesan.text = Bahasa.t("wireshark.simpan_kosong")
		return
	_buka_overlay(Bahasa.t("wireshark.simpan_judul"))
	var dasar := _model.judul if _model.judul != "" else "capture"
	var isian := LineEdit.new()
	isian.text = dasar.replace(" ", "-") + WiresharkData.EKSTENSI
	isian.custom_minimum_size = Vector2(0, 56)
	isian.add_theme_font_size_override("font_size", 20)
	_overlay_isi.add_child(isian)
	_overlay_isi.add_child(Tema.label(Bahasa.t("wireshark.nama_berkas"), Tema.TEKS_REDUP, 18))
	_overlay_isi.add_child(_tombol(Bahasa.t("wireshark.simpan"), _simpan.bind(isian)))

func _simpan(isian: LineEdit) -> void:
	var n := isian.text.strip_edges()
	if n == "":
		return
	if not n.ends_with(WiresharkData.EKSTENSI):
		n += WiresharkData.EKSTENSI
	var abs := Vfs.normalisasi(_sesi.home, n, _sesi.home)
	_sesi.tulis_berkas(abs, WiresharkData.teks_simpan(_model.judul, _model.antarmuka, _model.paket))
	Penyimpanan.simpan_sesi(_sesi)
	_tutup_overlay()
	_pesan.text = Bahasa.t("wireshark.simpan_ok") % abs

func _statistik() -> void:
	var tampil := _model.paket_tampil()
	_buka_overlay(Bahasa.t("wireshark.statistik"))
	if tampil.is_empty():
		_label_overlay(Bahasa.t("wireshark.kosong_tampil_stat"), Tema.TEKS_REDUP)
		return
	var r := WiresharkStats.ringkasan(tampil)
	_label_overlay(Bahasa.t("wireshark.ringkasan"), Tema.TEAL)
	_baris_stat(Bahasa.t("wireshark.ringkas_paket"), str(r["paket"]))
	_baris_stat(Bahasa.t("wireshark.ringkas_bytes"), str(r["bytes"]))
	_baris_stat(Bahasa.t("wireshark.ringkas_durasi"), "%.3f" % float(r["durasi"]))
	_baris_stat(Bahasa.t("wireshark.ringkas_rata"), "%.1f" % float(r["rata"]))
	_baris_stat(Bahasa.t("wireshark.ringkas_pps"), "%.2f" % float(r["rata_pps"]))
	_label_overlay(Bahasa.t("wireshark.hierarki"), Tema.TEAL)
	for b in WiresharkStats.hierarki(tampil):
		var teks := "".lpad(2 * int(b["kedalaman"]), " ") + String(b["nama"]) + "  " + str(b["paket"]) + "  " + ("%.1f%%" % float(b["persen"]))
		_overlay_isi.add_child(_label_mono(teks))
	_label_overlay(Bahasa.t("wireshark.percakapan"), Tema.TEAL)
	var percakapan := WiresharkStats.percakapan(tampil)
	if percakapan.is_empty():
		_label_overlay(Bahasa.t("wireshark.belum_ada_percakapan"), Tema.TEKS_REDUP)
	for k in percakapan:
		_overlay_isi.add_child(_label_mono("%s <-> %s  paket:%d bytes:%d" % [k["a"], k["b"], k["paket"], k["bytes"]]))
	_label_overlay(Bahasa.t("wireshark.catatan_simulasi"), Tema.TEKS_REDUP)

func _baris_stat(nama: String, nilai: String) -> void:
	_overlay_isi.add_child(_label_mono(nama.rpad(28) + nilai))

func _label_mono(teks: String) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_override("font", _mono())
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Tema.TEKS)
	return l

# ---------------------------------------------------------------- tampilan data
func _muat(data: Dictionary, judul: String) -> void:
	_model.muat_berkas(data, judul)

func _segar() -> void:
	_segar_daftar()
	_segar_status()
	_bytes.text = ""
	_tampil_rincian()

func _segar_daftar() -> void:
	_daftar.clear()
	var akar := _daftar.create_item()
	var pilih_item: TreeItem = null
	for idx in _model.tampil:
		var pk: Dictionary = _model.paket[idx]
		var item := _daftar.create_item(akar)
		var nilai := [str(int(pk.get("no", 0))), "%.6f" % float(pk.get("waktu", 0.0)), String(pk.get("sumber", "")),
			String(pk.get("tujuan", "")), String(pk.get("protokol", "")), str(int(pk.get("panjang", 0))), String(pk.get("info", ""))]
		var warna := _warna_protokol(String(pk.get("protokol", "")))
		for c in range(nilai.size()):
			item.set_text(c, nilai[c])
			item.set_custom_bg_color(c, warna)
			item.set_text_alignment(c, HORIZONTAL_ALIGNMENT_RIGHT if c == 5 else HORIZONTAL_ALIGNMENT_LEFT)
		item.set_metadata(0, idx)
		if idx == _model.terpilih:
			pilih_item = item
	if pilih_item != null:
		pilih_item.select(0)
	elif _model.menangkap and akar.get_child_count() > 0:
		_daftar.scroll_to_item(akar.get_child(akar.get_child_count() - 1))

func _warna_protokol(protokol: String) -> Color:
	return Color(WARNA_PROTOKOL.get(protokol.to_lower(), "#ffffff"))

func _tampil_rincian() -> void:
	_rincian.clear()
	var akar := _rincian.create_item()
	if _model.terpilih < 0:
		_bytes.text = "[color=#555555]" + Bahasa.t("wireshark.tanpa_rincian") + "[/color]"
		return
	var pk := _model.paket_terpilih()
	for lap in pk.get("rincian", []):
		var item := _rincian.create_item(akar)
		item.set_text(0, String(lap["judul"]))
		item.set_metadata(0, {"mulai": int(lap["mulai"]), "panjang": int(lap["panjang"])})
		for b in lap.get("bidang", []):
			var anak := _rincian.create_item(item)
			anak.set_text(0, "    " + String(b["teks"]))
			anak.set_metadata(0, {"mulai": int(b["mulai"]), "panjang": int(b["panjang"])})
	_sorot(0, int(pk.get("panjang", 0)))

func _sorot(mulai: int, panjang: int) -> void:
	var pk := _model.paket_terpilih()
	if pk.is_empty():
		return
	var raw := WiresharkData.hex_ke_byte(String(pk.get("hex", "")))
	var teks := ""
	var mulai_baris := 0
	while mulai_baris < raw.size():
		var hex := ""
		var asc := ""
		for i in range(BYTE_PER_BARIS):
			var pos := mulai_baris + i
			if pos >= raw.size():
				hex += "   "
				asc += " "
				continue
			var b := raw[pos]
			var disorot := pos >= mulai and pos < mulai + panjang
			var h := "%02x " % b
			var a := char(b) if b >= 32 and b < 127 else "."
			if a == "[":
				a = "[lb]"
			if disorot:
				h = "[bgcolor=%s]%s[/bgcolor]" % [WARNA_SOROT, h]
				a = "[bgcolor=%s]%s[/bgcolor]" % [WARNA_SOROT, a]
			hex += h
			asc += a
		teks += "%04x  %s %s\n" % [mulai_baris, hex, asc]
		mulai_baris += BYTE_PER_BARIS
	_bytes.text = teks

func _segar_status() -> void:
	var n := _model.paket.size()
	var tampil := _model.tampil.size()
	var baris := Bahasa.t("wireshark.status_paket") % [n, tampil]
	if _model.menangkap:
		baris = (Bahasa.t("wireshark.status_tangkap") % _model.antarmuka) + "  " + baris + "  sisa " + str(_model.sisa_tangkap())
	elif n == 0:
		baris = Bahasa.t("wireshark.kosong")
	_hitung.text = baris
	_hitung.add_theme_color_override("font_color", WARNA_GALAT if _galat != "" else Tema.TEKS)
	if _galat != "":
		_hitung.text = _galat
	_btn_mulai.disabled = _model.menangkap
	_btn_berhenti.disabled = not _model.menangkap

# ---------------------------------------------------------------- misi
# Catatan ke progres misi lewat flag. Hanya menambah flag baru; tidak mengubah tahap misi.
func _catat(flag: String) -> void:
	var sebelum := _sesi.jaringan.progres.size()
	_sesi.jaringan.buka(flag)
	if _sesi.jaringan.progres.size() != sebelum:
		Misi.perbarui(_sesi)
		Penyimpanan.simpan_sesi(_sesi)

func _cek_misi() -> void:
	var tampil := _model.paket_tampil()
	var eapol := 0
	for pk in tampil:
		if Array(pk.get("lapisan", [])).has("eapol"):
			eapol += 1
	if eapol >= 4:
		_catat("wireshark:handshake")
	var pk_terpilih := _model.paket_terpilih()
	if Dictionary(pk_terpilih.get("fitur", {})).has("http.form.password"):
		_catat("wireshark:kredensial")
