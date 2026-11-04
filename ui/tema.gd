class_name Tema

# Warna dan gaya bersama untuk seluruh UI JTN, mengikuti referensi desain.

const TEAL := Color("#2dd4bf")
const AMBER := Color("#f59e0b")
const TEKS := Color("#e6f7f5")
const TEKS_REDUP := Color("#8fa8a4")
const LATAR_PANEL := Color(0.04, 0.06, 0.08, 0.72)
const LATAR_HEADER := Color(0.03, 0.05, 0.07, 0.96)

static func kotak(bg: Color, batas: Color, lebar: int, radius: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = batas
    s.set_border_width_all(lebar)
    s.set_corner_radius_all(radius)
    s.content_margin_left = 14.0
    s.content_margin_right = 14.0
    s.content_margin_top = 8.0
    s.content_margin_bottom = 8.0
    return s

static func header_bawah(bg: Color, batas: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = batas
    s.set_border_width(SIDE_BOTTOM, 2)
    s.content_margin_left = 12.0
    s.content_margin_right = 12.0
    s.content_margin_top = 4.0
    s.content_margin_bottom = 4.0
    return s

static func label(teks: String, warna: Color = TEKS, ukuran: int = 22) -> Label:
    var l := Label.new()
    l.text = teks
    l.add_theme_color_override("font_color", warna)
    l.add_theme_font_size_override("font_size", ukuran)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

static func margin_seragam(node: MarginContainer, nilai: int) -> void:
    for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        node.add_theme_constant_override(k, nilai)
