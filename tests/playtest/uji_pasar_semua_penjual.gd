extends SceneTree

# Pasar (Black Market) untuk SEMUA penjual dan SEMUA item, lewat jalur sinyal layar:
# penjual dipilih lewat tombolnya (id terikat ke pressed), item dibeli lewat tombol Beli (id terikat).
# Setiap pembelian diperiksa: saldo berkurang sesuai harga, stok berkurang, tingkat tool sesuai.
# Penjual yang belum terbuka harus menolak pembelian dengan pesan syarat reputasi.
# Prasyarat dicatat: saldo diatur tinggi sebelum pembelian. Bukan input OS.

const LOG := "/tmp/claude-0/-home-claude/8b937400-0bc0-5d55-a30f-257755c5fbe4/scratchpad/playtest/uji_pasar_semua_penjual.txt"

var lines: PackedStringArray = []
var gagal := 0
var lulus := 0
var root_app: Node

func _catat(s: String) -> void:
	print(s)
	lines.append(s)

func _cek(ok: bool, nama: String, bukti := "") -> void:
	if ok:
		lulus += 1
		_catat("PASS  %s %s" % [nama, bukti])
	else:
		gagal += 1
		_catat("FAIL  %s %s" % [nama, bukti])

func _frames(n := 3) -> void:
	for i in range(n):
		await process_frame

func _secs(t: float) -> void:
	await create_timer(t).timeout

func _sesi():
	return SesiUtama.ambil()

func _cari_berkas(node: Node, berkas: String) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("/" + berkas):
		return node
	for c in node.get_children():
		var r := _cari_berkas(c, berkas)
		if r != null:
			return r
	return null

func _tunggu_berkas(berkas: String, batas := 15.0) -> Node:
	var t := 0.0
	while t < batas:
		var n := _cari_berkas(root_app, berkas)
		if n != null and n.is_inside_tree():
			return n
		await _secs(0.2)
		t += 0.2
	return null

func _cari_tombol(node: Node, teks: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and not (node as Button).disabled and (node as Button).text.strip_edges() == teks:
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol(c, teks)
		if r != null:
			hasil = r
	return hasil

# Tombol yang terikat ke metode [metode] dengan argumen pertama [arg] (mis. _beli dengan id item).
func _tombol_terikat(node: Node, metode: String, arg: String) -> Button:
	var hasil: Button = null
	if node is Button:
		for c in (node as Button).get_signal_connection_list("pressed"):
			var cb: Callable = c["callable"]
			var args: Array = cb.get_bound_arguments()
			if String(cb.get_method()) == metode and args.size() > 0 and String(args[0]) == arg:
				hasil = node
	for c in node.get_children():
		var r := _tombol_terikat(c, metode, arg)
		if r != null:
			hasil = r
	return hasil

func _teks_node(node: Node) -> String:
	var t := ""
	if node is Label:
		t += (node as Label).text + " "
	if node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + " "
	for c in node.get_children():
		t += _teks_node(c)
	return t

func _buka(desk: Node, id: String, berkas: String) -> Node:
	var ikon: Button = desk.call("_tombol_id", id)
	if ikon == null:
		return null
	ikon.pressed.emit()
	await _secs(1.0)
	return await _tunggu_berkas(berkas)

func _tutup(app: Node) -> void:
	if app == null:
		return
	var d := _cari_tombol_berisi(app, "Desktop")
	if d != null:
		d.pressed.emit()
		await _secs(0.6)

func _cari_tombol_berisi(node: Node, bagian: String) -> Button:
	var hasil: Button = null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.contains(bagian):
		hasil = node
	for c in node.get_children():
		var r := _cari_tombol_berisi(c, bagian)
		if r != null:
			hasil = r
	return hasil

# Penjual dipilih lewat tombol yang terikat ke _pilih_penjual dengan id penjual.
func _pilih_penjual(pasar: Node, pid: String) -> bool:
	var t := _tombol_terikat(pasar, "_pilih_penjual", pid)
	if t == null:
		return false
	t.pressed.emit()
	await _secs(0.3)
	return true

func _initialize() -> void:
	await process_frame
	var packed: PackedScene = load("res://scenes/main.tscn")
	root_app = packed.instantiate()
	get_root().add_child(root_app)
	await _frames(10)
	var menu := await _tunggu_berkas("menu_utama.gd")
	if menu != null:
		await _secs(1.0)
		var lanjut := _cari_tombol(menu, Bahasa.t("menu.lanjutkan"))
		if lanjut != null:
			lanjut.pressed.emit()
	await _secs(1.5)
	var desk := await _tunggu_berkas("desktop_view.gd")
	_cek(desk != null, "[sinyal layar] desktop siap")
	if desk == null:
		_selesai()
		return

	var sesi = _sesi()
	# Prasyarat: saldo tinggi agar pembelian tidak tertahan oleh harga.
	sesi.economy.saldo = 999999
	# Prasyarat opsional REP=buka: reputasi grup dinaikkan agar penjual yang terkunci ikut terbuka.
	if OS.get_environment("REP") == "buka":
		sesi.reputation.ubah("kolektif_senja", 100)
		_catat("PRASYARAT reputasi kolektif_senja +100 (nilai sekarang %d)" % sesi.reputation.get_nilai("kolektif_senja"))
	var pasar := await _buka(desk, "pasar", "pasar_screen.gd")
	_cek(pasar != null, "[sinyal layar] Pasar terbuka")
	if pasar == null:
		_selesai()
		return

	var penjual_ids: Array = BlackMarket.penjual_ids()
	_cek(penjual_ids.size() == 4, "semua 4 penjual terdaftar", "(%s)" % str(penjual_ids))
	for pid in penjual_ids:
		var p := BlackMarket.penjual(String(pid))
		var terbuka := BlackMarket.penjual_terbuka(String(pid), sesi.reputation)
		var dipilih := await _pilih_penjual(pasar, String(pid))
		_cek(dipilih, "penjual %s: tombol penjual ada" % pid)
		if not dipilih:
			continue
		if not terbuka:
			# Penjual terkunci: label syarat reputasi tampil dan tidak ada item yang bisa dibeli.
			var syarat := int(p.get("syarat_rep", 0))
			_cek(_teks_node(pasar).contains(str(syarat)), "penjual %s terkunci: label syarat reputasi %d tampil" % [pid, syarat])
			var ada_beli := false
			for it in p.get("item", []):
				if _tombol_terikat(pasar, "_beli", String(it["id"])) != null:
					ada_beli = true
			_cek(not ada_beli, "penjual %s terkunci: tidak ada tombol Beli" % pid)
			continue
		for it in p.get("item", []):
			var iid := String(it["id"])
			var tool := String(it["tool"])
			var tingkat := int(it["tingkat"])
			var harga := ToolDefs.harga(tool, tingkat)
			var tombol := _tombol_terikat(pasar, "_beli", iid)
			_cek(tombol != null, "item %s: tombol Beli ada" % iid)
			if tombol == null:
				continue
			var saldo_awal: int = sesi.economy.saldo
			var stok_awal: int = sesi.market.sisa(iid)
			tombol.pressed.emit()
			await _secs(0.3)
			if terbuka:
				_cek(sesi.inventory.tingkat(tool) == tingkat, "item %s (%s tingkat %d): dibeli" % [iid, tool, tingkat], "(saldo %d -> %d, harga %d)" % [saldo_awal, sesi.economy.saldo, harga])
				_cek(sesi.economy.saldo == saldo_awal - harga, "item %s: saldo berkurang tepat %d" % [iid, harga])
				_cek(sesi.market.sisa(iid) == stok_awal - 1, "item %s: stok berkurang 1" % iid, "(%d -> %d)" % [stok_awal, sesi.market.sisa(iid)])
			else:
				_cek(sesi.economy.saldo == saldo_awal and sesi.inventory.tingkat(tool) < tingkat, "item %s: penjual terkunci menolak, saldo tidak berubah" % iid)
				_cek(_teks_node(pasar).contains("belum mau bertransaksi") or _teks_node(pasar).contains("not trading yet"), "item %s: pesan syarat reputasi tampil" % iid)
	await _tutup(pasar)
	_selesai()

func _selesai() -> void:
	_catat("== HASIL (sinyal layar, bukan input OS): %d PASS, %d FAIL ==" % [lulus, gagal])
	var f := FileAccess.open(LOG, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
	quit(0 if gagal == 0 else 1)
