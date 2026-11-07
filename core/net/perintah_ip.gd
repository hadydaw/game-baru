class_name PerintahIp
extends RefCounted

# Perintah ip (iproute2): menampilkan alamat dan rute jaringan perangkat pemain.
# Format keluaran mengikuti 'ip addr' dan 'ip route' pada Linux. Alamat diambil dari Jaringan.

static func ip(s: ShellSession, p: Dictionary) -> Array:
	var args: Array = p["argumen"]
	if args.is_empty():
		return [s.galat("ip", "Usage: ip [ OPTIONS ] OBJECT { COMMAND | help }")]
	var objek := String(args[0])
	match objek:
		"addr", "address", "a", "ad", "addr-show":
			s.jaringan.buka("ip:addr")
			return _addr(s)
		"route", "r":
			s.jaringan.buka("ip:route")
			return _route(s)
		_:
			return [s.galat("ip", "Object \"%s\" is unknown, try \"ip help\"." % objek)]

static func _addr(s: ShellSession) -> Array:
	var ip_saya := Jaringan.PEMAIN_IP
	var mac := Jaringan.PEMAIN_MAC
	return [
		s.baris("info", "1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000"),
		s.baris("info", "    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00"),
		s.baris("info", "    inet 127.0.0.1/8 scope host lo"),
		s.baris("info", "       valid_lft forever preferred_lft forever"),
		s.baris("info", "2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000"),
		s.baris("info", "    link/ether %s brd ff:ff:ff:ff:ff:ff" % mac),
		s.baris("info", "    inet %s/24 brd %s255 scope global eth0" % [ip_saya, Jaringan.SUBNET_LAB2]),
		s.baris("info", "       valid_lft forever preferred_lft forever"),
	]

static func _route(s: ShellSession) -> Array:
	var ip_saya := Jaringan.PEMAIN_IP
	var gerbang := String(s.jaringan.ip("lab2-gerbang"))
	return [
		s.baris("info", "default via %s dev eth0 proto dhcp src %s metric 100" % [gerbang, ip_saya]),
		s.baris("info", "%s0/24 dev eth0 proto kernel scope link src %s metric 100" % [Jaringan.SUBNET_LAB2, ip_saya]),
	]
