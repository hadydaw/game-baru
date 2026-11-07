class_name ShellComplete
extends RefCounted

# Autocomplete Tab di Terminal, seperti bash-completion. Semua sumber diambil dari kondisi sistem pemain:
#   - nama perintah: Teks.MAN yang lolos CommandRegistry (sama dengan daftar di help)
#   - berkas dan direktori: Vfs pemain, ditambah sampel Wireshark di /usr/share/wireshark/samples/
#   - paket apt: Repositori (katalog) dengan status terpasang dari sesi pemain
# Hanya opsi dan subperintah yang sudah diimplementasikan yang ditawarkan.
# Mengembalikan {teks: teks baru, pilihan: daftar kecocokan bila lebih dari satu}.

# Perintah yang kata pertamanya (setelah opsi) adalah subperintah.
const SUBPERINTAH := {
	"ip": ["addr", "route"],
	"apt": ["install", "remove", "purge", "autoremove", "update", "upgrade", "list", "search", "show"],
	"airmon-ng": ["start", "stop"],
	"network-analyzer": ["analyze", "verify", "report"],
	"password-auditor": ["auth", "run"],
}

# Opsi yang benar-benar dibaca oleh perintahnya.
const OPSI := {
	"nmap": ["-sn", "-p", "-sV", "-oN"],
	"ping": ["-c"],
	"netdiscover": ["-r"],
	"wireshark": ["-r", "-i", "-v", "--version"],
	"tshark": ["-r", "-i", "-Y", "-c", "-z", "-q", "-D", "-v", "--version"],
	"airodump-ng": ["--bssid", "--channel", "--encrypt", "--essid", "--update", "--write"],
	"apt": ["-y"],
}

# Perintah yang membaca sampel Wireshark dari jalur simulasi.
const PERINTAH_SAMPEL := ["wireshark", "tshark"]

# Anak virtual untuk jalur sampel. /usr tidak ada di filesystem pemain, jadi hanya dikenali di sini.
const DIR_VIRTUAL := {
	"/usr": ["share"],
	"/usr/share": ["wireshark"],
	"/usr/share/wireshark": ["samples"],
}

static func lengkapi(s: ShellSession, teks: String) -> Dictionary:
	var mulai := _mulai_token(teks)
	if mulai == 0:
		return _hasil(teks, "", "", "", teks, _nama_perintah(s, teks))
	var awal := teks.substr(0, mulai)
	var token := teks.substr(mulai)
	var kutip := ""
	if token.length() > 0 and (token[0] == "\"" or token[0] == "'"):
		kutip = token[0]
		token = token.substr(1)
	var sudah := ShellParser.tokenkan(awal)
	if sudah.is_empty():
		return {"teks": teks, "pilihan": []}
	var perintah := String(sudah[0])
	# Perintah yang belum tersedia (mis. nmap sebelum apt install) tidak punya argumen yang ditawarkan.
	if not CommandRegistry.tersedia(s, perintah):
		return {"teks": teks, "pilihan": []}
	var posisi := _posisi(sudah)

	if token.begins_with("-"):
		return _hasil(teks, awal, kutip, "", token, _cocok(_opsi_untuk(s, perintah), token))

	if SUBPERINTAH.has(perintah) and posisi.is_empty():
		return _hasil(teks, awal, kutip, "", token, _cocok(SUBPERINTAH[perintah], token))

	if perintah == "apt" and posisi.size() >= 1:
		var sub := String(posisi[0])
		if sub == "install" or sub == "remove" or sub == "purge":
			return _hasil(teks, awal, kutip, "", token, _paket(s, sub, token))

	return _lengkapi_jalur(s, teks, awal, kutip, token, perintah)

# Indeks awal token yang sedang diketik. Spasi di dalam kutip tidak memisahkan token.
static func _mulai_token(teks: String) -> int:
	var kutip := ""
	var mulai := 0
	for i in range(teks.length()):
		var c := teks[i]
		if kutip != "":
			if c == kutip:
				kutip = ""
		elif c == "\"" or c == "'":
			kutip = c
		elif c == " ":
			mulai = i + 1
	return mulai

# Opsi yang bisa dipakai sekarang. -sV nmap hanya dengan Network Scanner tingkat 2 ke atas, sama seperti saat dijalankan.
static func _opsi_untuk(s: ShellSession, perintah: String) -> Array:
	var opsi: Array = OPSI.get(perintah, []).duplicate()
	if perintah == "nmap" and s.inventory.tingkat("network_scanner") < 2:
		opsi.erase("-sV")
	return opsi

# Argumen setelah nama perintah yang bukan opsi, mis. "install" pada "apt -y install".
static func _posisi(sudah: Array) -> Array:
	var hasil: Array = []
	for i in range(1, sudah.size()):
		var t := String(sudah[i])
		if not t.begins_with("-"):
			hasil.append(t)
	return hasil

static func _cocok(daftar: Array, prefix: String) -> Array:
	var hasil: Array = []
	for d in daftar:
		if String(d).begins_with(prefix):
			hasil.append(String(d))
	return hasil

# Nama perintah yang bisa dijalankan sekarang. Perintah yang butuh alat atau aplikasi yang belum
# terpasang tidak muncul, sama seperti saat dijalankan.
static func _nama_perintah(s: ShellSession, prefix: String) -> Array:
	var hasil: Array = []
	for nama in Teks.MAN.keys():
		var n := String(nama)
		if not n.begins_with(prefix):
			continue
		if ShellCommands.PERINTAH_LAMA.has(n) or AlatCommands.NAMA.has(n):
			continue
		if CommandRegistry.tersedia(s, n):
			hasil.append(n)
	return hasil

# apt install: paket katalog yang belum terpasang. apt remove/purge: paket yang terpasang.
static func _paket(s: ShellSession, sub: String, prefix: String) -> Array:
	var hasil: Array = []
	for id in Repositori.semua_id():
		var n := String(id)
		if not n.begins_with(prefix):
			continue
		var terpasang := s.repositori.punya(n)
		if (sub == "install" and not terpasang) or (sub != "install" and terpasang):
			hasil.append(n)
	return hasil

static func _lengkapi_jalur(s: ShellSession, teks: String, awal: String, kutip: String, token: String, perintah: String) -> Dictionary:
	var garis := token.rfind("/")
	var dir_teks := token.substr(0, garis + 1) if garis >= 0 else ""
	var prefix := token.substr(garis + 1)
	var abs := Vfs.normalisasi(s.cwd, dir_teks if dir_teks != "" else ".", s.home)
	var kandidat: Array = []
	for pasangan in _anak_direktori(s, abs, perintah):
		var nama := String(pasangan[0])
		var dir := bool(pasangan[1])
		if nama.begins_with(".") and not prefix.begins_with("."):
			continue
		if not nama.begins_with(prefix):
			continue
		if perintah == "cd" and not dir:
			continue
		kandidat.append(nama + ("/" if dir else ""))
	return _hasil(teks, awal, kutip, dir_teks, prefix, kandidat)

# Isi direktori sebagai pasangan [nama, adalah_direktori]. Kosong bila jalur bukan direktori.
static func _anak_direktori(s: ShellSession, abs: String, perintah: String) -> Array:
	var hasil: Array = []
	var node := s.fs.ambil(abs)
	if not node.is_empty():
		if String(node.get("tipe", "")) != "dir":
			return hasil
		var isi: Dictionary = node.get("isi", {})
		for nama in isi.keys():
			var anak: Dictionary = isi[nama]
			hasil.append([String(nama), String(anak.get("tipe", "")) == "dir"])
		return hasil
	if not PERINTAH_SAMPEL.has(perintah):
		return hasil
	var sampel := WiresharkData.DIR_SAMPEL.rstrip("/")
	if abs == sampel:
		for id in WiresharkData.CONTOH:
			hasil.append([String(id) + WiresharkData.EKSTENSI, false])
		return hasil
	if DIR_VIRTUAL.has(abs):
		for nama in DIR_VIRTUAL[abs]:
			hasil.append([String(nama), true])
	return hasil

# Menyusun teks hasil. Satu kecocokan dilengkapi penuh; banyak kecocokan dilengkapi sampai awalan bersama.
static func _hasil(teks: String, awal: String, kutip: String, dir_teks: String, prefix: String, kandidat: Array) -> Dictionary:
	kandidat.sort()
	if kandidat.is_empty():
		return {"teks": teks, "pilihan": []}
	if kandidat.size() == 1:
		var nama := String(kandidat[0])
		var selesai := not nama.ends_with("/")
		var hasil := awal + _bentuk(dir_teks + nama, kutip, selesai)
		if selesai:
			hasil += " "
		return {"teks": hasil, "pilihan": []}
	var bersama := _awalan_bersama(kandidat)
	var baru := teks
	if bersama.length() > prefix.length():
		baru = awal + _bentuk(dir_teks + bersama, kutip, false)
	return {"teks": baru, "pilihan": kandidat}

# Nama dengan spasi, atau token yang sudah dibuka kutipnya, ditulis di dalam kutip.
static func _bentuk(token: String, kutip: String, selesai: bool) -> String:
	if kutip == "" and token.find(" ") < 0:
		return token
	var q := kutip if kutip != "" else "\""
	return q + token + (q if selesai else "")

static func _awalan_bersama(daftar: Array) -> String:
	var pertama := String(daftar[0])
	var panjang := pertama.length()
	for d in daftar:
		var s := String(d)
		while panjang > 0 and not s.begins_with(pertama.substr(0, panjang)):
			panjang -= 1
	return pertama.substr(0, panjang)
