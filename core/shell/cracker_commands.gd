class_name CrackerCommands
extends RefCounted

# Pemulih kata sandi Kali: aircrack-ng, hashcat, dan john. Ketiganya menguji daftar kata pada data
# handshake yang sudah ditangkap (state yang sama dengan password-auditor). Keluaran mengikuti format
# masing-masing tool. Wordlist hanya tersedia sebagai kamus lab; path lain ditolak dengan galat.

const KAMUS_PATH := "/usr/share/wordlists/rockyou.txt"
const TARGET_SIMULASI := "LAB-WIFI-01"

static func aircrack(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	var opsi: Array = p["opsi"]
	if not opsi.has("-w"):
		return [_galat("Please specify a dictionary (option -w).")]
	if args.size() < 2:
		return [_galat("No valid WPA handshakes found.")]
	var kamus := String(args[0])
	var target := String(args[args.size() - 1])
	var hasil: Array = [_info("Aircrack-ng 1.7")]
	if kamus != KAMUS_PATH:
		return hasil + [_galat("Opening %s failed" % kamus)]
	if not s.wifi.handshake.has(target):
		return hasil + [_galat("No valid WPA handshakes found.")]
	hasil.append(_info("Opening %s" % kamus))
	hasil.append(_info("Read %d keys" % WifiLab.kamus().size()))
	var kata := String(WifiLab.jaringan(target).get("kata_sandi", ""))
	if WifiLab.kamus().has(kata):
		s.wifi.kata_sandi_ditemukan[target] = kata
		s.jaringan.buka("crack:aircrack-ng")
		hasil.append(_info("KEY FOUND! [ %s ]" % kata))
	else:
		hasil.append(_info("Passphrase not in dictionary"))
	return hasil

static func hashcat(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"].duplicate()
	var opsi: Array = p["opsi"]
	if not opsi.has("-m") and not opsi.has("--hash-type"):
		return [_galat("Hash mode is not specified.")]
	# Nilai -m (mode hash) ikut tercatat sebagai argumen pertama; buang sebelum membaca target dan kamus.
	if opsi.has("-m") and not args.is_empty() and String(args[0]).is_valid_int():
		args.pop_front()
	if args.size() < 2:
		return [_galat("No hashes loaded.")]
	var target := String(args[0])
	var kamus := String(args[1])
	var hasil: Array = [_info("hashcat (v6.2.6) starting"), _info("")]
	if not s.wifi.handshake.has(target):
		return hasil + [_galat("No hashes loaded.")]
	if kamus != KAMUS_PATH:
		return hasil + [_galat("Error: %s: No such file or directory" % kamus)]
	# Label dan urutan mengikuti sesi hashcat resmi (hashcat.net/wiki). Waktu dan kecepatan tidak disimulasikan.
	var kata := String(WifiLab.jaringan(target).get("kata_sandi", ""))
	var ditemukan := WifiLab.kamus().has(kata)
	hasil.append(_info("Session..........: hashcat"))
	hasil.append(_info("Status...........: %s" % ("Cracked" if ditemukan else "Exhausted")))
	hasil.append(_info("Hash.Mode........: 2500 (WPA-EAPOL-PBKDF2)"))
	hasil.append(_info("Hash.Target......: %s" % target))
	hasil.append(_info("Recovered........: %s" % ("1/1 (100.00%) Digests" if ditemukan else "0/1 (0.00%) Digests")))
	var n := WifiLab.kamus().size()
	hasil.append(_info("Progress.........: %d/%d (100.00%%)" % [n, n]))
	if ditemukan:
		s.wifi.kata_sandi_ditemukan[target] = kata
		s.jaringan.buka("crack:hashcat")
		hasil.append(_info("%s:%s" % [target, kata]))
	return hasil

static func john(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	var opsi: Array = p["opsi"]
	var kamus := ""
	for o in opsi:
		if String(o).begins_with("--wordlist="):
			kamus = String(o).substr("--wordlist=".length())
	if args.is_empty():
		return [_info("Usage: john [OPTIONS] [PASSWORD-FILES]")]
	var target := String(args[0])
	if kamus == "":
		return [_galat("No password files specified or wordlist option missing.")]
	if kamus != KAMUS_PATH:
		return [_galat("No password hashes loaded (see FAQ)")]
	if not s.wifi.handshake.has(target):
		return [_galat("No password hashes loaded (see FAQ)")]
	var hasil: Array = [_info("Loaded 1 password hash (wpapsk, WPA/WPA2 PSK)")]
	var kata := String(WifiLab.jaringan(target).get("kata_sandi", ""))
	if WifiLab.kamus().has(kata):
		s.wifi.kata_sandi_ditemukan[target] = kata
		s.jaringan.buka("crack:john")
		hasil.append(_info("%-18s (%s)" % [kata, target]))
		hasil.append(_info("1g 0:00:00:00 DONE"))
	else:
		hasil.append(_info("0g 0:00:00:00 DONE"))
	return hasil


static func _info(teks: String) -> Dictionary:
	return {"tipe": "info", "teks": teks}

static func _galat(teks: String) -> Dictionary:
	return {"tipe": "error", "teks": teks}
