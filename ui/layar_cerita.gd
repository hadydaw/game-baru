class_name LayarCerita
extends Control

# Pembukaan untuk pemain baru: empat halaman cerita dengan ilustrasi vektor yang digambar dari kode.
# Sinyal selesai dikirim setelah halaman terakhir atau saat pemain melewati cerita.

signal selesai

const JUMLAH := 4
const DURASI_TRANSISI := 0.45
const TEKS_HALAMAN := ["intro.hal1", "intro.hal2", "intro.hal3", "intro.hal4"]

var _halaman := 0
var _aman := Vector4.ZERO
var _ilustrasi: IlustrasiCerita
var _teks: Label
var _judul_bab: Label
var _titik: Array = []
var _tombol_lanjut: Button
var _konten: Control
var _wallpaper: TextureRect
var _tween: Tween
var _sedang_pindah := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_wallpaper = TextureRect.new()
	_wallpaper.texture = load("res://assets/wallpaper/wp_potret.png") as Texture2D
	_wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_wallpaper)
	var redup := ColorRect.new()
	redup.color = Color(0.02, 0.03, 0.04, 0.82)
	redup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(redup)
	_bangun()
	_tampilkan(0, false)

func atur_aman(nilai: Vector4) -> void:
	_aman = nilai
	var m := get_node_or_null("Margin") as MarginContainer
	if m:
		m.add_theme_constant_override("margin_left", int(_aman.x) + 28)
		m.add_theme_constant_override("margin_top", int(_aman.y) + 24)
		m.add_theme_constant_override("margin_right", int(_aman.z) + 28)
		m.add_theme_constant_override("margin_bottom", int(_aman.w) + 24)

func _bangun() -> void:
	var m := MarginContainer.new()
	m.name = "Margin"
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_bottom", 24)
	add_child(m)

	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 18)
	m.add_child(kolom)

	var atas := HBoxContainer.new()
	kolom.add_child(atas)
	_judul_bab = Tema.label(Bahasa.t("intro.judul_cerita"), Tema.TEAL, 26)
	_judul_bab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_judul_bab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	atas.add_child(_judul_bab)
	var lewati := _tombol_kecil(Bahasa.t("intro.lewati"))
	lewati.pressed.connect(func(): selesai.emit())
	atas.add_child(lewati)

	_konten = Control.new()
	_konten.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_konten.clip_contents = true
	kolom.add_child(_konten)

	_ilustrasi = IlustrasiCerita.new()
	_ilustrasi.anchor_right = 1.0
	_ilustrasi.offset_bottom = 440.0
	_konten.add_child(_ilustrasi)

	_teks = Tema.label("", Tema.TEKS, 30)
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks.anchor_right = 1.0
	_teks.anchor_bottom = 1.0
	_teks.offset_top = 470.0
	_teks.add_theme_constant_override("line_spacing", 8)
	_konten.add_child(_teks)

	var bawah := VBoxContainer.new()
	bawah.add_theme_constant_override("separation", 16)
	kolom.add_child(bawah)

	var baris_titik := HBoxContainer.new()
	baris_titik.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_titik.add_theme_constant_override("separation", 14)
	bawah.add_child(baris_titik)
	for i in JUMLAH:
		var titik := ColorRect.new()
		titik.custom_minimum_size = Vector2(16, 16)
		titik.mouse_filter = Control.MOUSE_FILTER_IGNORE
		baris_titik.add_child(titik)
		_titik.append(titik)

	_tombol_lanjut = Button.new()
	_tombol_lanjut.custom_minimum_size = Vector2(0, 96.0)
	_tombol_lanjut.focus_mode = Control.FOCUS_NONE
	_tombol_lanjut.add_theme_font_size_override("font_size", 30)
	_tombol_lanjut.add_theme_color_override("font_color", Color("#06201c"))
	_tombol_lanjut.add_theme_stylebox_override("normal", Tema.kotak(Tema.TEAL, Tema.TEAL, 0, 18))
	_tombol_lanjut.add_theme_stylebox_override("hover", Tema.kotak(Tema.TEAL, Tema.TEAL, 0, 18))
	_tombol_lanjut.add_theme_stylebox_override("pressed", Tema.kotak(Color("#1fb3a1"), Tema.TEAL, 0, 18))
	_tombol_lanjut.pressed.connect(_lanjut)
	bawah.add_child(_tombol_lanjut)

func _tombol_kecil(teks: String) -> Button:
	var b := Button.new()
	b.text = teks
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Tema.TEKS_REDUP)
	return b

func _lanjut() -> void:
	if _sedang_pindah:
		return
	if _halaman >= JUMLAH - 1:
		selesai.emit()
		return
	_tampilkan(_halaman + 1, true)

# Pindah halaman dengan transisi: teks dan ilustrasi memudar lalu muncul dari kanan.
func _tampilkan(indeks: int, animasi: bool) -> void:
	_halaman = indeks
	_ilustrasi.halaman = indeks
	_tombol_lanjut.text = Bahasa.t("intro.mulai") if indeks == JUMLAH - 1 else Bahasa.t("intro.lanjut")
	for i in _titik.size():
		(_titik[i] as ColorRect).color = Tema.AMBER if i == indeks else Color(Tema.TEKS_REDUP, 0.35)
	if not animasi:
		_teks.text = Bahasa.t(TEKS_HALAMAN[indeks])
		_ilustrasi.queue_redraw()
		return
	_sedang_pindah = true
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_konten, "modulate:a", 0.0, DURASI_TRANSISI * 0.5)
	_tween.tween_callback(_ganti_teks.bind(indeks))
	_tween.tween_property(_konten, "modulate:a", 1.0, DURASI_TRANSISI * 0.5)
	_tween.tween_callback(func(): _sedang_pindah = false)

func _ganti_teks(indeks: int) -> void:
	_teks.text = Bahasa.t(TEKS_HALAMAN[indeks])
	_ilustrasi.queue_redraw()

# Ilustrasi dibuat dengan kode: setiap halaman punya komposisi sendiri dalam gaya jaringan JTN.
class IlustrasiCerita extends Control:
	var halaman := 0
	var _waktu := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_waktu += delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.03, 0.05, 0.07, 0.9))
		_gambar_kisi(r)
		match halaman:
			0: _gambar_jaringan(r)
			1: _gambar_arsip_terkunci(r)
			2: _gambar_operator(r)
			_: _gambar_peta_jejak(r)
		draw_rect(r, Color(Tema.TEAL, 0.35), false, 2.0)

	func _gambar_kisi(r: Rect2) -> void:
		var warna := Color(Tema.TEAL, 0.07)
		var x := 0.0
		while x < r.size.x:
			draw_line(Vector2(x, 0), Vector2(x, r.size.y), warna, 1.0)
			x += 40.0
		var y := 0.0
		while y < r.size.y:
			draw_line(Vector2(0, y), Vector2(r.size.x, y), warna, 1.0)
			y += 40.0
		var sapuan := fposmod(_waktu * 60.0, r.size.y)
		draw_line(Vector2(0, sapuan), Vector2(r.size.x, sapuan), Color(Tema.TEAL, 0.12), 2.0)

	# Halaman 1: beberapa node tersambung, dengan satu sinyal berdenyut.
	func _gambar_jaringan(r: Rect2) -> void:
		var pusat := r.size * 0.5
		var titik: Array = [
			pusat + Vector2(-190, -110), pusat + Vector2(170, -150), pusat + Vector2(-60, 40),
			pusat + Vector2(210, 90), pusat + Vector2(-220, 120), pusat + Vector2(40, 170),
		]
		for i in titik.size():
			for j in range(i + 1, titik.size()):
				if (i + j) % 3 != 0:
					draw_line(titik[i], titik[j], Color(Tema.TEAL, 0.25), 2.0, true)
		var denyut := 0.5 + 0.5 * sin(_waktu * 3.0)
		for i in titik.size():
			var warna := Tema.AMBER if i == 2 else Tema.TEAL
			draw_circle(titik[i], 9.0, warna)
			draw_arc(titik[i], 18.0 + 6.0 * denyut * (1.0 if i == 2 else 0.0), 0.0, TAU, 32, Color(warna, 0.4), 2.0, true)
		var dari: Vector2 = titik[2]
		var ke: Vector2 = titik[int(fposmod(_waktu, titik.size()))]
		draw_circle(dari.lerp(ke, fposmod(_waktu, 1.0)), 5.0, Color(Tema.TEKS))

	# Halaman 2: arsip dengan gembok, dikelilingi garis merah peringatan.
	func _gambar_arsip_terkunci(r: Rect2) -> void:
		var pusat := r.size * 0.5
		var kotak := Rect2(pusat - Vector2(150, 110), Vector2(300, 220))
		draw_rect(kotak, Color(0.06, 0.09, 0.11, 1.0))
		draw_rect(kotak, Color(Tema.TEAL, 0.6), false, 3.0)
		for i in 4:
			var y := kotak.position.y + 40 + i * 42
			draw_line(Vector2(kotak.position.x + 30, y), Vector2(kotak.position.x + kotak.size.x - 30, y), Color(Tema.TEKS_REDUP, 0.5), 3.0)
		var gembok := pusat + Vector2(0, 10)
		draw_rect(Rect2(gembok + Vector2(-34, -6), Vector2(68, 56)), Color("#ff7b72"))
		draw_arc(gembok + Vector2(0, -6), 24.0, PI, TAU, 24, Color("#ff7b72"), 8.0, true)
		var garis := fposmod(_waktu * 90.0, 80.0)
		for i in 6:
			var x := -40.0 + i * 90.0 + garis
			draw_line(Vector2(x, 0), Vector2(x + 120, r.size.y), Color(Color("#ff7b72"), 0.12), 14.0)

	# Halaman 3: layar terminal dengan kursor berkedip dan satu baris perintah.
	func _gambar_operator(r: Rect2) -> void:
		var layar := Rect2(r.size * 0.5 - Vector2(250, 150), Vector2(500, 300))
		draw_rect(layar, Color(0.02, 0.04, 0.05, 1.0))
		draw_rect(layar, Color(Tema.TEAL, 0.7), false, 3.0)
		var font := ThemeDB.fallback_font
		var baris := ["$ whoami", "operator", "$ nmap 10.x.x.x", "1 perangkat ditemukan", "$ _"]
		for i in baris.size():
			draw_string(font, layar.position + Vector2(24, 52 + i * 46), baris[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Tema.TEAL if i % 2 == 0 else Tema.TEKS)
		if fmod(_waktu, 1.0) < 0.5:
			draw_rect(Rect2(layar.position + Vector2(24 + 26, 52 + 4 * 46 - 22), Vector2(14, 26)), Tema.AMBER)

	# Halaman 4: peta sederhana dengan jejak yang menyala satu per satu.
	func _gambar_peta_jejak(r: Rect2) -> void:
		var pusat := r.size * 0.5
		var jejak: Array = [pusat + Vector2(-200, 90), pusat + Vector2(-80, -40), pusat + Vector2(40, 60), pusat + Vector2(190, -100)]
		for i in jejak.size() - 1:
			draw_line(jejak[i], jejak[i + 1], Color(Tema.AMBER, 0.5), 3.0, true)
		var aktif := int(fposmod(_waktu * 1.2, jejak.size()))
		for i in jejak.size():
			var warna := Tema.AMBER if i <= aktif else Color(Tema.TEKS_REDUP, 0.4)
			draw_circle(jejak[i], 10.0, warna)
		var kursor: Vector2 = jejak[aktif]
		draw_arc(kursor, 26.0 + 4.0 * sin(_waktu * 5.0), 0.0, TAU, 32, Color(Tema.AMBER, 0.6), 2.0, true)
