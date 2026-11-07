extends SceneTree

const SHOTS := "user://"
var _gagal := 0

func _cek(k: bool, p: String) -> void:
	print(("LULUS: " if k else "GAGAL: ") + p)
	if not k:
		_gagal += 1

func _bocor(layar: Node, lebar: float) -> Array:
	var b := []
	for c in layar.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree() or not (ctl is Label or ctl is Button or ctl is RichTextLabel or ctl is LineEdit):
			continue
		var r := ctl.get_global_rect()
		if r.size.x <= 0:
			continue
		if r.position.x < -0.5 or r.end.x > lebar + 0.5:
			b.append(ctl.get_class())
	return b

func _initialize() -> void:
	await process_frame
	Penyimpanan.berkas_aktif = "user://uji_smoke_terminal_hp.json"
	Penyimpanan.arsipkan("user://uji_terminal_tmp.json")
	SesiUtama.reset()
	var env := (OS.get_environment("UKURAN_HP") if OS.get_environment("UKURAN_HP") != "" else "360x640").split("x")
	var lebar := float(env[0])
	var tinggi := float(env[1])
	var ukuran := "%dx%d" % [lebar, tinggi]
	var wadah := Control.new()
	wadah.size = Vector2(lebar, tinggi)
	root.add_child(wadah)
	var layar: Control = TerminalScreen.new()
	layar.size = Vector2(lebar, tinggi)
	wadah.add_child(layar)
	for i in range(3):
		await process_frame
	_cek(_bocor(layar, lebar).is_empty(), "terminal tidak keluar lebar %s: %s" % [ukuran, str(_bocor(layar, lebar))])
	layar.call("_kirim", "help")
	layar.call("_selesaikan_cepat")
	for i in range(2):
		await process_frame
	_cek(_bocor(layar, lebar).is_empty(), "terminal setelah help tidak keluar lebar %s" % ukuran)
	var masukan: LineEdit = layar.get("_masukan")
	_cek(masukan != null and masukan.is_visible_in_tree(), "kolom masukan terlihat")
	var lr := masukan.get_global_rect()
	_cek(lr.end.y <= tinggi + 0.5 and lr.size.y >= 40, "kolom masukan utuh di layar (y=%d h=%d)" % [lr.position.y, lr.size.y])
	var tombol_bawah := []
	for b in layar.find_children("*", "Button", true, false):
		var br := (b as Button).get_global_rect()
		if (b as Button).is_visible_in_tree():
			tombol_bawah.append("%s:%d" % [(b as Button).text, br.size.y])
	for b in layar.find_children("*", "Button", true, false):
		var br := (b as Button).get_global_rect()
		if (b as Button).is_visible_in_tree():
			_cek(br.size.y >= 48 and br.size.x >= 48, "tombol %s cukup besar untuk disentuh (%dx%d)" % [(b as Button).text, br.size.x, br.size.y])
	get_root().get_texture().get_image().save_png(SHOTS + "terminal_%s.png" % ukuran)
	print("HASIL TERMINAL %s gagal=%d" % [ukuran, _gagal])
	quit(1 if _gagal > 0 else 0)
