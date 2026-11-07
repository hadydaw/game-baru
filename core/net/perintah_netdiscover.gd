class_name PerintahNetdiscover
extends RefCounted

# Netdiscover: menemukan perangkat di subnet lewat permintaan ARP. Mode aktif dengan -r <rentang>.
# Keluaran mengikuti tabel netdiscover asli. Hanya subnet /24 yang didukung di laboratorium ini.

static func netdiscover(s: ShellSession, p: Dictionary) -> Array:
	if not ShellParser.punya_huruf(p["opsi"], "r"):
		return [s.galat("netdiscover", "Usage: netdiscover [-i device] [-r range] [-s time]")]
	var args: Array = p["argumen"]
	if args.is_empty():
		return [s.galat("netdiscover", "Usage: netdiscover [-i device] [-r range] [-s time]")]
	var rentang := String(args[0])
	var prefiks := _prefiks_24(rentang)
	if prefiks == "":
		return [s.galat("netdiscover", "Invalid range: %s (hanya /24 yang didukung)" % rentang)]
	var j := s.jaringan
	var ids := j.host_di_subnet(prefiks)
	var hasil: Array = [
		s.baris("info", " Currently scanning: Finished!   |   Screen View: Unique Hosts"),
		s.baris("info", ""),
		s.baris("info", " %d Captured ARP Req/Rep packets, from %d hosts.   Total size: %d" % [ids.size() * 2, ids.size(), ids.size() * 120]),
		s.baris("info", " _____________________________________________________________________________"),
		s.baris("info", "   IP            At MAC Address     Count     Len  MAC Vendor / Hostname"),
		s.baris("info", " -----------------------------------------------------------------------------"),
	]
	for id in ids:
		j.tandai_ditemukan(id)
		var mac := String(j.data[id].get("mac", "00:00:00:00:00:00"))
		var vendor := String(j.data[id].get("vendor", "Unknown vendor"))
		hasil.append(s.baris("info", " %-15s %-18s %5d %8d  %s" % [j.ip(id), mac, 1, 60, vendor]))
	j.buka("netdiscover:pindai")
	return hasil

# "10.8.1.0/24" -> "10.8.1." ; kosong bila bukan /24 yang valid.
static func _prefiks_24(rentang: String) -> String:
	var re := RegEx.new()
	re.compile("^(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})\\.0/24$")
	var m := re.search(rentang)
	if m == null:
		return ""
	return m.get_string(1) + "."
