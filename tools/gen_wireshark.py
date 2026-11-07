#!/usr/bin/env python3
# Generator data capture simulasi untuk Wireshark di game. Byte paket dibangun sungguhan
# (Ethernet, ARP, IPv4, TCP, UDP, DNS, HTTP, ICMP, 802.11, LLC, EAPOL) dengan checksum benar.
# Offset setiap bidang dihitung dari byte paket, sehingga hex dan rincian selalu cocok.
# Keluaran: data/wireshark/<id>.json. Jalankan ulang setelah mengubah generator ini.
import json, struct, os, sys

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "wireshark")
BC = "ff:ff:ff:ff:ff:ff"
ETYPE = {0x0800: "IPv4", 0x0806: "ARP"}
ABBR = [("Radiotap", "radiotap"), ("IEEE 802.11", "wlan"), ("Logical-Link", "llc"), ("802.1X", "eapol"),
        ("Ethernet", "eth"), ("Internet Protocol", "ip"), ("Internet Control", "icmp"),
        ("Transmission Control", "tcp"), ("User Datagram", "udp"), ("Hypertext", "http"),
        ("Domain Name", "dns"), ("Address Resolution", "arp")]

def mac(s): return bytes(int(x, 16) for x in s.split(":"))
def ipb(s): return bytes(int(x) for x in s.split("."))

def csum(data):
    if len(data) % 2: data += b"\x00"
    s = sum(struct.unpack("!%dH" % (len(data) // 2), data))
    while s >> 16: s = (s & 0xffff) + (s >> 16)
    return (~s) & 0xffff

def pseudo(src, dst, proto, ln): return ipb(src) + ipb(dst) + struct.pack("!BBH", 0, proto, ln)

def singkat(judul):
    for k, v in ABBR:
        if k in judul: return v
    return "data"

# ---------------------------------------------------------------- penyusun frame
class Builder:
    def __init__(self, iface):
        self.iface = iface; self.paket = []; self.no = 0

    def tambah(self, t, layers, info, protokol, sumber, tujuan, fitur, pad=True):
        # layers[0] = lapisan terluar berisi seluruh frame. Lapisan lain berupa ekor (suffix) byte frame,
        # sehingga offset awalnya = panjang frame tanpa padding - panjang lapisan itu.
        raw0 = layers[0][1]
        L = len(raw0)
        raw = raw0 + (b"\x00" * (60 - L) if pad and L < 60 else b"")
        n = len(raw)
        self.no += 1
        lap = [singkat(l[0]) for l in layers]
        rinci = [{"judul": "Frame %d: %d bytes on wire (%d bits), %d bytes captured (%d bits) on interface %s, id 0"
                            % (self.no, n, n * 8, n, n * 8, self.iface),
                  "mulai": 0, "panjang": n,
                  "bidang": [{"teks": "Arrival Time: %.6f seconds" % t, "mulai": 0, "panjang": 0},
                             {"teks": "Frame Length: %d bytes (%d bits)" % (n, n * 8), "mulai": 0, "panjang": 0},
                             {"teks": "Protocols in frame: %s" % ":".join(lap), "mulai": 0, "panjang": 0}]}]
        for judul, data, bid in layers:
            st = L - len(data)
            rinci.append({"judul": judul, "mulai": st, "panjang": len(data),
                          "bidang": [{"teks": b[0], "mulai": st + b[1], "panjang": b[2]} for b in bid]})
        if n > L:
            rinci.append({"judul": "Padding", "mulai": L, "panjang": n - L,
                          "bidang": [{"teks": "Padding: %s" % ("00" * (n - L)), "mulai": L, "panjang": n - L}]})
        self.paket.append({"no": self.no, "waktu": round(t, 6), "sumber": sumber, "tujuan": tujuan,
                           "protokol": protokol, "panjang": n, "info": info, "lapisan": lap,
                           "fitur": fitur, "hex": raw.hex(), "rincian": rinci})

# ---------------------------------------------------------------- lapisan (judul, byte, bidang)
def eth(src, dst, etype, payload):
    hdr = mac(dst) + mac(src) + struct.pack("!H", etype)
    bid = [("Destination: %s" % dst, 0, 6), ("Source: %s" % src, 6, 6),
           ("Type: %s (0x%04x)" % (ETYPE[etype], etype), 12, 2)]
    return ("Ethernet II, Src: %s, Dst: %s" % (src, dst), hdr + payload, bid)

def ipv4(src, dst, proto, payload, ident, ttl=64):
    tot = 20 + len(payload)
    h = struct.pack("!BBHHHBBH4s4s", 0x45, 0, tot, ident, 0x4000, ttl, proto, 0, ipb(src), ipb(dst))
    c = csum(h)
    h = h[:10] + struct.pack("!H", c) + h[12:]
    pn = {1: "ICMP", 6: "TCP", 17: "UDP"}[proto]
    bid = [("0100 .... = Version: 4", 0, 1), (".... 0101 = Header Length: 20 bytes (5)", 0, 1),
           ("Differentiated Services Field: 0x00", 1, 1), ("Total Length: %d" % tot, 2, 2),
           ("Identification: 0x%04x (%d)" % (ident, ident), 4, 2), ("Flags: 0x2 (Don't Fragment)", 6, 2),
           ("Time to Live: %d" % ttl, 8, 1), ("Protocol: %s (%d)" % (pn, proto), 9, 1),
           ("Header Checksum: 0x%04x [correct]" % c, 10, 2), ("Source Address: %s" % src, 12, 4),
           ("Destination Address: %s" % dst, 16, 4)]
    return ("Internet Protocol Version 4, Src: %s, Dst: %s" % (src, dst), h + payload, bid)

def tcp(src, dst, sport, dport, seq, ack, flags, win, payload=b"", mss=None):
    opts = struct.pack("!BBH", 2, 4, mss) if mss else b""
    off = (20 + len(opts)) // 4
    bits = {"FIN": 1, "SYN": 2, "RST": 4, "PSH": 8, "ACK": 16}
    fb = sum(bits[f] for f in flags)
    hdr = struct.pack("!HHIIBBHHH", sport, dport, seq, ack, off << 4, fb, win, 0, 0) + opts
    c = csum(pseudo(src, dst, 6, len(hdr) + len(payload)) + hdr + payload)
    hdr = hdr[:16] + struct.pack("!H", c) + hdr[18:]
    bid = [("Source Port: %d" % sport, 0, 2), ("Destination Port: %d" % dport, 2, 2),
           ("Sequence Number: %d" % seq, 4, 4), ("Acknowledgment Number: %d" % ack, 8, 4),
           ("{:04b} .... = Header Length: {} bytes ({})".format(off, off * 4, off), 12, 1),
           ("Flags: 0x%03x (%s)" % (fb, ", ".join(flags)), 13, 1),
           ("Window: %d" % win, 14, 2), ("Checksum: 0x%04x [correct]" % c, 16, 2),
           ("Urgent Pointer: 0", 18, 2)]
    if mss: bid.append(("Maximum segment size: %d bytes" % mss, 20, 4))
    return ("Transmission Control Protocol, Src Port: %d, Dst Port: %d, Seq: %d, Len: %d"
            % (sport, dport, seq, len(payload)), hdr + payload, bid)

def udp(src, dst, sport, dport, payload):
    ln = 8 + len(payload)
    hdr = struct.pack("!HHHH", sport, dport, ln, 0)
    c = csum(pseudo(src, dst, 17, ln) + hdr + payload) or 0xffff
    hdr = hdr[:6] + struct.pack("!H", c)
    bid = [("Source Port: %d" % sport, 0, 2), ("Destination Port: %d" % dport, 2, 2),
           ("Length: %d" % ln, 4, 2), ("Checksum: 0x%04x [correct]" % c, 6, 2)]
    return ("User Datagram Protocol, Src Port: %d, Dst Port: %d" % (sport, dport), hdr + payload, bid)

def dname(name): return b"".join(bytes([len(p)]) + p.encode() for p in name.split(".")) + b"\x00"

def dns_q(ident, name):
    nm = dname(name)
    body = struct.pack("!HHHHHH", ident, 0x0100, 1, 0, 0, 0) + nm + struct.pack("!HH", 1, 1)
    q = 12 + len(nm)
    bid = [("Transaction ID: 0x%04x" % ident, 0, 2), ("Flags: 0x0100 Standard query", 2, 2),
           ("Questions: 1", 4, 2), ("Name: %s" % name, 12, len(nm)),
           ("Type: A (Host Address) (1)", q, 2), ("Class: IN (0x0001)", q + 2, 2)]
    return ("Domain Name System (query)", body, bid)

def dns_r(ident, name, addr):
    nm = dname(name)
    q = 12 + len(nm)
    body = (struct.pack("!HHHHHH", ident, 0x8180, 1, 1, 0, 0) + nm + struct.pack("!HH", 1, 1)
            + struct.pack("!HHHIH", 0xc00c, 1, 1, 300, 4) + ipb(addr))
    bid = [("Transaction ID: 0x%04x" % ident, 0, 2), ("Flags: 0x8180 Standard query response, No error", 2, 2),
           ("Questions: 1", 4, 2), ("Answer RRs: 1", 6, 2), ("Name: %s" % name, 12, len(nm)),
           ("Type: A (Host Address) (1)", q, 2), ("Class: IN (0x0001)", q + 2, 2),
           ("Name: %s (pointer to offset 12)" % name, q + 4, 2), ("Type: A (1)", q + 6, 2),
           ("Class: IN (1)", q + 8, 2), ("Time to live: 300", q + 10, 4), ("Data length: 4", q + 14, 2),
           ("Address: %s" % addr, q + 16, 4)]
    return ("Domain Name System (response)", body, bid)

def http_req(data):
    s1 = data.index(b" "); method = data[:s1]
    s2 = data.index(b" ", s1 + 1); uri = data[s1 + 1:s2]
    e = data.index(b"\r\n"); ver = data[s2 + 1:e]
    hi = data.index(b"Host: "); he = data.index(b"\r\n", hi)
    bid = [("Request Method: %s" % method.decode(), 0, len(method)),
           ("Request URI: %s" % uri.decode(), s1 + 1, len(uri)),
           ("Request Version: %s" % ver.decode(), s2 + 1, len(ver)),
           ("Host: %s" % data[hi + 6:he].decode(), hi, he - hi)]
    return ("Hypertext Transfer Protocol", data, bid)

def http_resp(data):
    v = data.index(b" ")
    c1 = v + 1; c2 = data.index(b" ", c1)
    pe = data.index(b"\r\n")
    ct = data.index(b"Content-Type:"); cte = data.index(b"\r\n", ct)
    bid = [("Response Version: %s" % data[:v].decode(), 0, v),
           ("Status Code: %s" % data[c1:c2].decode(), c1, c2 - c1),
           ("Response Phrase: %s" % data[c2 + 1:pe].decode(), c2 + 1, pe - c2 - 1),
           ("%s" % data[ct:cte].decode(), ct, cte - ct)]
    return ("Hypertext Transfer Protocol", data, bid)

def http_post(data):
    s1 = data.index(b" "); s2 = data.index(b" ", s1 + 1)
    ct = data.index(b"Content-Type:"); cte = data.index(b"\r\n", ct)
    bs = data.index(b"\r\n\r\n") + 4
    form = data[bs:]
    amp = form.index(b"&")
    bid = [("Request Method: POST", 0, s1), ("Request URI: %s" % data[s1 + 1:s2].decode(), s1 + 1, s2 - s1 - 1),
           ("%s" % data[ct:cte].decode(), ct, cte - ct),
           ("Form item: \"%s\" = \"%s\"" % tuple(form[:amp].decode().split("=")), bs, amp),
           ("Form item: \"%s\" = \"%s\"" % tuple(form[amp + 1:].decode().split("=")), bs + amp + 1, len(form) - amp - 1)]
    return ("Hypertext Transfer Protocol", data, bid)

def tcp_frame(sm, dm, sip, dip, sport, dport, seq, ack, flags, win, ident, mss=None, app=None):
    t = tcp(sip, dip, sport, dport, seq, ack, flags, win, app[1] if app else b"", mss)
    ip = ipv4(sip, dip, 6, t[1], ident)
    out = [eth(sm, dm, 0x0800, ip[1]), ip, t]
    if app: out.append(app)
    return out

def udp_frame(sm, dm, sip, dip, sport, dport, ident, app):
    u = udp(sip, dip, sport, dport, app[1])
    ip = ipv4(sip, dip, 17, u[1], ident)
    return [eth(sm, dm, 0x0800, ip[1]), ip, u, app]

def icmp_frame(sm, dm, sip, dip, typ, seq, ident):
    data = bytes(range(0x30, 0x50))
    ic = struct.pack("!BBHHH", typ, 0, 0, 1, seq) + data
    c = csum(ic)
    ic = ic[:2] + struct.pack("!H", c) + ic[4:]
    ip = ipv4(sip, dip, 1, ic, ident)
    nm = "Echo (ping) request" if typ == 8 else "Echo (ping) reply"
    bid = [("Type: %d (%s)" % (typ, nm), 0, 1), ("Code: 0", 1, 1), ("Checksum: 0x%04x [correct]" % c, 2, 2),
           ("Identifier (BE): 1 (0x0001)", 4, 2), ("Sequence Number (BE): %d (0x%04x)" % (seq, seq), 6, 2),
           ("Data (32 bytes)", 8, 32)]
    return [eth(sm, dm, 0x0800, ip[1]), ip, ("Internet Control Message Protocol", ic, bid)]

def arp_bid(op, smac, sip, tmac, tip):
    return [("Hardware type: Ethernet (1)", 0, 2), ("Protocol type: IPv4 (0x0800)", 2, 2),
            ("Hardware size: 6", 4, 1), ("Protocol size: 4", 5, 1),
            ("Opcode: %s (%d)" % ("request" if op == 1 else "reply", op), 6, 2),
            ("Sender MAC address: %s" % smac, 8, 6), ("Sender IP address: %s" % sip, 14, 4),
            ("Target MAC address: %s" % tmac, 18, 6), ("Target IP address: %s" % tip, 24, 4)]

def tcp_info(sp, dp, flags, seq, ack, win, plen=0, mss=None):
    s = "%d → %d [%s] Seq=%d" % (sp, dp, ", ".join(flags), seq)
    if "ACK" in flags: s += " Ack=%d" % ack
    s += " Win=%d Len=%d" % (win, plen)
    if mss: s += " MSS=%d" % mss
    return s

def f_ip(a, b): return {"ip.src": a, "ip.dst": b, "ip.addr": [a, b]}
def f_tcp(sp, dp, flags):
    return {"tcp.srcport": sp, "tcp.dstport": dp, "tcp.port": [sp, dp],
            "tcp.flags.syn": int("SYN" in flags), "tcp.flags.ack": int("ACK" in flags),
            "tcp.flags.fin": int("FIN" in flags), "tcp.flags.rst": int("RST" in flags),
            "tcp.flags.psh": int("PSH" in flags)}
def f_udp(sp, dp): return {"udp.srcport": sp, "udp.dstport": dp, "udp.port": [sp, dp]}

RT = struct.pack("<BBHI", 0, 0, 8, 0)
RT_BID = [("Header revision: 0", 0, 1), ("Header length: 8 bytes", 2, 2), ("Present flags: 0x00000000", 4, 4)]
RATES = bytes([0x82, 0x84, 0x8b, 0x96, 0x0c, 0x12, 0x18, 0x24])

def ie(i, d): return bytes([i, len(d)]) + d

# ---------------------------------------------------------------- skenario 1: LAN
def scen_lan():
    B = Builder("eth0")
    CM, CI = "3c:52:82:11:7a:08", "10.7.0.8"
    GM, GI = "00:0c:42:aa:01:01", "10.7.0.1"
    WM, WI = "52:54:00:12:34:80", "10.7.0.80"
    QN = "portal.lab.jtn.test"
    arq = struct.pack("!HHBBH6s4s6s4s", 1, 0x0800, 6, 4, 1, mac(CM), ipb(CI), b"\0" * 6, ipb(GI))
    B.tambah(0.0, [eth(CM, BC, 0x0806, arq), ("Address Resolution Protocol (request)", arq,
             arp_bid(1, CM, CI, "00:00:00:00:00:00", GI))],
             "Who has %s? Tell %s" % (GI, CI), "ARP", CM, BC,
             {"arp.opcode": 1, "arp.src.proto_ipv4": CI, "arp.dst.proto_ipv4": GI, "eth.addr": [CM, BC]})
    arr = struct.pack("!HHBBH6s4s6s4s", 1, 0x0800, 6, 4, 2, mac(GM), ipb(GI), mac(CM), ipb(CI))
    B.tambah(0.000412, [eth(GM, CM, 0x0806, arr), ("Address Resolution Protocol (reply)", arr,
             arp_bid(2, GM, GI, CM, CI))],
             "%s is at %s" % (GI, GM), "ARP", GM, CM,
             {"arp.opcode": 2, "arp.src.proto_ipv4": GI, "eth.addr": [GM, CM]})
    B.tambah(1.204118, udp_frame(CM, GM, CI, GI, 52114, 53, 0x2110, dns_q(0x6a1f, QN)),
             "Standard query 0x6a1f A %s" % QN, "DNS", CI, GI,
             {**f_ip(CI, GI), **f_udp(52114, 53), "dns.qry.name": QN, "dns.flags.response": 0})
    B.tambah(1.209733, udp_frame(GM, CM, GI, CI, 53, 52114, 0x77b2, dns_r(0x6a1f, QN, WI)),
             "Standard query response 0x6a1f A %s A %s" % (QN, WI), "DNS", GI, CI,
             {**f_ip(GI, CI), **f_udp(53, 52114), "dns.qry.name": QN, "dns.flags.response": 1})
    cs, ss = 40512, 80
    s1 = tcp_frame(CM, WM, CI, WI, cs, ss, 0x1a2b3c4d, 0, ["SYN"], 64240, 0x2201, mss=1460)
    B.tambah(1.231900, s1, tcp_info(cs, ss, ["SYN"], 0x1a2b3c4d, 0, 64240, 0, 1460), "TCP", CI, WI,
             {**f_ip(CI, WI), **f_tcp(cs, ss, ["SYN"])})
    s2 = tcp_frame(WM, CM, WI, CI, ss, cs, 0x5e6f7a8b, 0x1a2b3c4e, ["SYN", "ACK"], 65160, 0x3310, mss=1460)
    B.tambah(1.233771, s2, tcp_info(ss, cs, ["SYN", "ACK"], 0x5e6f7a8b, 0x1a2b3c4e, 65160, 0, 1460), "TCP", WI, CI,
             {**f_ip(WI, CI), **f_tcp(ss, cs, ["SYN", "ACK"])})
    s3 = tcp_frame(CM, WM, CI, WI, cs, ss, 0x1a2b3c4e, 0x5e6f7a8c, ["ACK"], 502, 0x2202)
    B.tambah(1.233905, s3, tcp_info(cs, ss, ["ACK"], 0x1a2b3c4e, 0x5e6f7a8c, 502), "TCP", CI, WI,
             {**f_ip(CI, WI), **f_tcp(cs, ss, ["ACK"])})
    req = (b"GET /login HTTP/1.1\r\nHost: portal.lab.jtn.test\r\n"
           b"User-Agent: Mozilla/5.0 (X11; Linux x86_64) Firefox/128.0\r\nAccept: text/html\r\n"
           b"Connection: keep-alive\r\n\r\n")
    B.tambah(1.234010, tcp_frame(CM, WM, CI, WI, cs, ss, 0x1a2b3c4e, 0x5e6f7a8c, ["PSH", "ACK"], 502, 0x2203,
             app=http_req(req)), "GET /login HTTP/1.1", "HTTP", CI, WI,
             {**f_ip(CI, WI), **f_tcp(cs, ss, ["PSH", "ACK"]), "http.request.method": "GET",
              "http.request.uri": "/login", "http.host": QN})
    body = b"<html><head><title>Portal Lab JTN</title></head><body><h1>Masuk</h1></body></html>"
    resp = (b"HTTP/1.1 200 OK\r\nServer: nginx/1.24.0\r\nContent-Type: text/html\r\nContent-Length: %d\r\n"
            b"Connection: keep-alive\r\n\r\n" % len(body)) + body
    B.tambah(1.251644, tcp_frame(WM, CM, WI, CI, ss, cs, 0x5e6f7a8c, 0x1a2b3c4e + len(req), ["PSH", "ACK"], 65160,
             0x3311, app=http_resp(resp)), "HTTP/1.1 200 OK  (text/html)", "HTTP", WI, CI,
             {**f_ip(WI, CI), **f_tcp(ss, cs, ["PSH", "ACK"]), "http.response.code": 200,
              "http.content_type": "text/html"})
    form = b"username=pemain&password=senja1234"
    post = (b"POST /login HTTP/1.1\r\nHost: portal.lab.jtn.test\r\n"
            b"Content-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n" % len(form)) + form
    B.tambah(3.072188, tcp_frame(CM, WM, CI, WI, cs, ss, 0x1a2b3c4e + len(req), 0x5e6f7a8c + len(resp),
             ["PSH", "ACK"], 502, 0x2204, app=http_post(post)),
             "POST /login HTTP/1.1  (application/x-www-form-urlencoded)", "HTTP", CI, WI,
             {**f_ip(CI, WI), **f_tcp(cs, ss, ["PSH", "ACK"]), "http.request.method": "POST",
              "http.request.uri": "/login", "http.host": QN, "http.form.password": "senja1234"})
    for k, (tt, seq) in enumerate([(4.105, 1), (5.107, 2)]):
        B.tambah(tt, icmp_frame(CM, GM, CI, GI, 8, seq, 0x2300 + seq),
                 "Echo (ping) request  id=0x0001, seq=%d/%d, ttl=64" % (seq, seq * 256), "ICMP", CI, GI,
                 {**f_ip(CI, GI), "icmp.type": 8})
        B.tambah(tt + 0.0061, icmp_frame(GM, CM, GI, CI, 0, seq, 0x7700 + seq),
                 "Echo (ping) reply    id=0x0001, seq=%d/%d, ttl=64" % (seq, seq * 256), "ICMP", GI, CI,
                 {**f_ip(GI, CI), "icmp.type": 0})
    s7 = tcp_frame(CM, WM, CI, WI, cs, ss, 0x1a2b3c4e + len(req) + len(post), 0x5e6f7a8c + len(resp),
                   ["FIN", "ACK"], 502, 0x2205)
    B.tambah(6.430812, s7, tcp_info(cs, ss, ["FIN", "ACK"], 0x1a2b3c4e + len(req) + len(post), 0x5e6f7a8c + len(resp), 502),
             "TCP", CI, WI, {**f_ip(CI, WI), **f_tcp(cs, ss, ["FIN", "ACK"])})
    return B.paket

# ---------------------------------------------------------------- skenario 2: pindai port SYN
def scen_scan():
    B = Builder("eth0")
    CM, CI = "3c:52:82:11:7a:08", "10.7.0.8"
    WM, WI = "52:54:00:12:34:80", "10.7.0.80"
    t = 0.0
    for i, (dp, terbuka) in enumerate([(21, False), (22, True), (23, False), (80, True), (443, False),
                                       (3306, False), (8080, False)]):
        sp = 47000 + i
        seq = 0x3f00 + i * 17
        B.tambah(t, tcp_frame(CM, WM, CI, WI, sp, dp, seq, 0, ["SYN"], 1024, 0x4100 + i, mss=1460),
                 tcp_info(sp, dp, ["SYN"], seq, 0, 1024, 0, 1460), "TCP", CI, WI, {**f_ip(CI, WI), **f_tcp(sp, dp, ["SYN"])})
        t += 0.00042
        if terbuka:
            B.tambah(t, tcp_frame(WM, CM, WI, CI, dp, sp, 0x9d10 + i, seq + 1, ["SYN", "ACK"], 64240, 0x5200 + i, mss=1460),
                     tcp_info(dp, sp, ["SYN", "ACK"], 0x9d10 + i, seq + 1, 64240, 0, 1460), "TCP", WI, CI,
                     {**f_ip(WI, CI), **f_tcp(dp, sp, ["SYN", "ACK"])})
            t += 0.00031
            B.tambah(t, tcp_frame(CM, WM, CI, WI, sp, dp, seq + 1, 0, ["RST"], 0, 0x4120 + i),
                     tcp_info(sp, dp, ["RST"], seq + 1, 0, 0), "TCP", CI, WI, {**f_ip(CI, WI), **f_tcp(sp, dp, ["RST"])})
        else:
            B.tambah(t, tcp_frame(WM, CM, WI, CI, dp, sp, 0, seq + 1, ["RST", "ACK"], 0, 0x5200 + i),
                     tcp_info(dp, sp, ["RST", "ACK"], 0, seq + 1, 0), "TCP", WI, CI,
                     {**f_ip(WI, CI), **f_tcp(dp, sp, ["RST", "ACK"])})
        t += 0.4132
    return B.paket

# ---------------------------------------------------------------- skenario 4: jejak jaringan internal (Tutorial 2)
def scen_jejak():
    # Subnet laboratorium 10.8.1.0/24 (IP tetap, sama dengan data/jaringan/jaringan.json).
    B = Builder("eth0")
    PM, PI = "02:4a:1c:10:00:42", "10.8.1.42"
    hosts = [("02:4a:1c:10:00:01", "10.8.1.1"), ("02:4a:1c:10:00:08", "10.8.1.8"),
             ("02:4a:1c:10:00:50", "10.8.1.50"), ("02:4a:1c:10:00:77", "10.8.1.77")]
    BM, BI = "02:4a:1c:10:00:08", "10.8.1.8"
    t = 0.0
    # Netdiscover: permintaan ARP ke setiap alamat di subnet, lalu host yang aktif menjawab.
    for hm, hi in hosts:
        arq = struct.pack("!HHBBH6s4s6s4s", 1, 0x0800, 6, 4, 1, mac(PM), ipb(PI), b"\0" * 6, ipb(hi))
        B.tambah(t, [eth(PM, BC, 0x0806, arq), ("Address Resolution Protocol (request)", arq,
                 arp_bid(1, PM, PI, "00:00:00:00:00:00", hi))],
                 "Who has %s? Tell %s" % (hi, PI), "ARP", PM, BC,
                 {"arp.opcode": 1, "arp.src.proto_ipv4": PI, "arp.dst.proto_ipv4": hi, "eth.addr": [PM, BC]})
        arr = struct.pack("!HHBBH6s4s6s4s", 1, 0x0800, 6, 4, 2, mac(hm), ipb(hi), mac(PM), ipb(PI))
        B.tambah(t + 0.000388, [eth(hm, PM, 0x0806, arr), ("Address Resolution Protocol (reply)", arr,
                 arp_bid(2, hm, hi, PM, PI))],
                 "%s is at %s" % (hi, hm), "ARP", hm, PM,
                 {"arp.opcode": 2, "arp.src.proto_ipv4": hi, "eth.addr": [hm, PM]})
        t += 0.0912
    # Pemindaian port SYN ke berkas (22 terbuka, 445 tertutup), lalu HTTP plaintext ke /login.
    for i, (dp, terbuka) in enumerate([(22, True), (445, False)]):
        sp = 48100 + i
        seq = 0x4a10 + i * 31
        B.tambah(t, tcp_frame(PM, BM, PI, BI, sp, dp, seq, 0, ["SYN"], 1024, 0x6100 + i, mss=1460),
                 tcp_info(sp, dp, ["SYN"], seq, 0, 1024, 0, 1460), "TCP", PI, BI, {**f_ip(PI, BI), **f_tcp(sp, dp, ["SYN"])})
        t += 0.00042
        if terbuka:
            B.tambah(t, tcp_frame(BM, PM, BI, PI, dp, sp, 0x9b20 + i, seq + 1, ["SYN", "ACK"], 64240, 0x6200 + i, mss=1460),
                     tcp_info(dp, sp, ["SYN", "ACK"], 0x9b20 + i, seq + 1, 64240, 0, 1460), "TCP", BI, PI,
                     {**f_ip(BI, PI), **f_tcp(dp, sp, ["SYN", "ACK"])})
            t += 0.00031
            B.tambah(t, tcp_frame(PM, BM, PI, BI, sp, dp, seq + 1, 0, ["RST"], 0, 0x6120 + i),
                     tcp_info(sp, dp, ["RST"], seq + 1, 0, 0), "TCP", PI, BI, {**f_ip(PI, BI), **f_tcp(sp, dp, ["RST"])})
        else:
            B.tambah(t, tcp_frame(BM, PM, BI, PI, dp, sp, 0, seq + 1, ["RST", "ACK"], 0, 0x6300 + i),
                     tcp_info(dp, sp, ["RST", "ACK"], 0, seq + 1, 0), "TCP", BI, PI,
                     {**f_ip(BI, PI), **f_tcp(dp, sp, ["RST", "ACK"])})
        t += 0.4132
    cs, ss = 49010, 80
    s1 = tcp_frame(PM, BM, PI, BI, cs, ss, 0x7c1d0a01, 0, ["SYN"], 64240, 0x6401, mss=1460)
    B.tambah(t, s1, tcp_info(cs, ss, ["SYN"], 0x7c1d0a01, 0, 64240, 0, 1460), "TCP", PI, BI,
             {**f_ip(PI, BI), **f_tcp(cs, ss, ["SYN"])})
    s2 = tcp_frame(BM, PM, BI, PI, ss, cs, 0x3e8f2b02, 0x7c1d0a02, ["SYN", "ACK"], 65160, 0x6402, mss=1460)
    B.tambah(t + 0.0018, s2, tcp_info(ss, cs, ["SYN", "ACK"], 0x3e8f2b02, 0x7c1d0a02, 65160, 0, 1460), "TCP", BI, PI,
             {**f_ip(BI, PI), **f_tcp(ss, cs, ["SYN", "ACK"])})
    s3 = tcp_frame(PM, BM, PI, BI, cs, ss, 0x7c1d0a02, 0x3e8f2b03, ["ACK"], 502, 0x6403)
    B.tambah(t + 0.0019, s3, tcp_info(cs, ss, ["ACK"], 0x7c1d0a02, 0x3e8f2b03, 502), "TCP", PI, BI,
             {**f_ip(PI, BI), **f_tcp(cs, ss, ["ACK"])})
    req = (b"GET /login HTTP/1.1\r\nHost: berkas.lab.jtn.test\r\n"
           b"User-Agent: Mozilla/5.0 (X11; Linux x86_64) Firefox/128.0\r\nAccept: text/html\r\n"
           b"Connection: keep-alive\r\n\r\n")
    B.tambah(t + 0.0021, tcp_frame(PM, BM, PI, BI, cs, ss, 0x7c1d0a02, 0x3e8f2b03, ["PSH", "ACK"], 502, 0x6404,
             app=http_req(req)), "GET /login HTTP/1.1", "HTTP", PI, BI,
             {**f_ip(PI, BI), **f_tcp(cs, ss, ["PSH", "ACK"]), "http.request.method": "GET",
              "http.request.uri": "/login", "http.host": "berkas.lab.jtn.test"})
    body = b"<html><head><title>Arsip Laboratorium</title></head><body><h1>Masuk</h1></body></html>"
    resp = (b"HTTP/1.1 200 OK\r\nServer: JTN-HTTP/1.4\r\nContent-Type: text/html\r\nContent-Length: %d\r\n"
            b"Connection: keep-alive\r\n\r\n" % len(body)) + body
    B.tambah(t + 0.0042, tcp_frame(BM, PM, BI, PI, ss, cs, 0x3e8f2b03, 0x7c1d0a02 + len(req), ["PSH", "ACK"], 65160,
             0x6405, app=http_resp(resp)), "HTTP/1.1 200 OK  (text/html)", "HTTP", BI, PI,
             {**f_ip(BI, PI), **f_tcp(ss, cs, ["PSH", "ACK"]), "http.response.code": 200,
              "http.content_type": "text/html"})
    form = b"username=operator&password=Arsip2026"
    post = (b"POST /login HTTP/1.1\r\nHost: berkas.lab.jtn.test\r\n"
            b"Content-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n" % len(form)) + form
    B.tambah(t + 2.318, tcp_frame(PM, BM, PI, BI, cs, ss, 0x7c1d0a02 + len(req), 0x3e8f2b03 + len(resp),
             ["PSH", "ACK"], 502, 0x6406, app=http_post(post)),
             "POST /login HTTP/1.1  (application/x-www-form-urlencoded)", "HTTP", PI, BI,
             {**f_ip(PI, BI), **f_tcp(cs, ss, ["PSH", "ACK"]), "http.request.method": "POST",
              "http.request.uri": "/login", "http.host": "berkas.lab.jtn.test", "http.form.password": "Arsip2026"})
    s7 = tcp_frame(PM, BM, PI, BI, cs, ss, 0x7c1d0a02 + len(req) + len(post), 0x3e8f2b03 + len(resp),
                   ["FIN", "ACK"], 502, 0x6407)
    B.tambah(t + 2.402, s7, tcp_info(cs, ss, ["FIN", "ACK"], 0x7c1d0a02 + len(req) + len(post), 0x3e8f2b03 + len(resp), 502),
             "TCP", PI, BI, {**f_ip(PI, BI), **f_tcp(cs, ss, ["FIN", "ACK"])})
    return B.paket

# ---------------------------------------------------------------- skenario 3: 802.11 + WPA2
def mgmt(fcv, a1, a2, a3, seq, body):
    return struct.pack("<H", fcv) + b"\x00\x00" + mac(a1) + mac(a2) + mac(a3) + struct.pack("<H", (seq & 0xfff) << 4) + body

def mgmt_bid(fcv, nama, a1, a2, a3, seq):
    return [("Frame Control: 0x%04x (%s)" % (fcv, nama), 0, 2), ("Duration: 0 microseconds", 2, 2),
            ("Destination address: %s" % a1, 4, 6), ("Source address: %s" % a2, 10, 6),
            ("BSS Id: %s" % a3, 16, 6), ("Sequence number: %d" % seq, 22, 2)]

def wifi_pkt(B, t, fcv, nama, a1, a2, a3, seq, body, body_bid, info, fitur):
    full = RT + mgmt(fcv, a1, a2, a3, seq, body)
    bid = mgmt_bid(fcv, nama, a1, a2, a3, seq) + body_bid
    B.tambah(t, [("Radiotap Header v0, Length 8", full, RT_BID), ("IEEE 802.11 %s" % nama, full[8:], bid)],
             info, "802.11", a2, a1, fitur, pad=False)

def scen_wifi():
    B = Builder("wlan0mon")
    AP = "02:4a:1c:00:01:01"
    AP2 = "02:4a:1c:00:02:02"
    CL = "3c:52:82:11:7a:08"
    t = 0.0
    for i in range(3):
        for bssid, ssid, ch in [(AP, "LAB-WIFI-01", 6), (AP2, "LAB-WIFI-02", 11)]:
            sb = ssid.encode()
            ts = 1234567890 + int(t * 1e6)
            body = struct.pack("<QHH", ts, 100, 0x0411) + ie(0, sb) + ie(1, RATES) + ie(3, bytes([ch]))
            se = 38 + len(sb)
            bid = [("Timestamp: %d" % ts, 24, 8), ("Beacon Interval: 0.102400 [Seconds]", 32, 2),
                   ("Capability Information: 0x0411", 34, 2), ("Tag: SSID parameter set: \"%s\"" % ssid, 36, 2 + len(sb)),
                   ("Tag: Supported Rates 1(B), 2(B), 5.5(B), 11(B), 6, 9, 12, 18 Mbps", se, 10),
                   ("Tag: DS Parameter set: Current Channel: %d" % ch, se + 10, 3)]
            wifi_pkt(B, t, 0x0080, "Beacon frame", BC, bssid, bssid, 2100 + i, body, bid,
                     "Beacon frame, SN=%d, FN=0, Flags=........, BI=100, SSID=%s" % (2100 + i, ssid),
                     {"wlan.fc.type_subtype": 8, "wlan.bssid": bssid, "wlan.ssid": ssid, "wlan.channel": ch,
                      "wlan.sa": bssid, "wlan.da": BC})
            t += 0.102
    body = ie(0, b"") + ie(1, bytes([0x82, 0x84, 0x8b, 0x96]))
    wifi_pkt(B, 0.512, 0x0040, "Probe Request", BC, CL, BC, 311, body,
             [("Tag: SSID parameter set: Broadcast", 24, 2), ("Tag: Supported Rates 1(B), 2(B), 5.5(B), 11(B)", 26, 6)],
             "Probe Request, SN=311, FN=0, Flags=........, SSID=Broadcast",
             {"wlan.fc.type_subtype": 4, "wlan.sa": CL, "wlan.da": BC, "wlan.bssid": BC, "wlan.ssid": ""})
    sb = b"LAB-WIFI-01"
    body = struct.pack("<QHH", 1234567890 + 512000, 100, 0x0411) + ie(0, sb) + ie(1, bytes([0x82, 0x84, 0x8b, 0x96])) + ie(3, bytes([6]))
    wifi_pkt(B, 0.518, 0x0050, "Probe Response", CL, AP, AP, 4011, body,
             [("Timestamp: %d" % (1234567890 + 512000), 24, 8), ("Beacon Interval: 0.102400 [Seconds]", 32, 2),
              ("Capability Information: 0x0411", 34, 2), ("Tag: SSID parameter set: \"LAB-WIFI-01\"", 36, 13),
              ("Tag: Supported Rates 1(B), 2(B), 5.5(B), 11(B)", 49, 6), ("Tag: DS Parameter set: Current Channel: 6", 55, 3)],
             "Probe Response, SN=4011, FN=0, Flags=........, BI=100, SSID=LAB-WIFI-01",
             {"wlan.fc.type_subtype": 5, "wlan.sa": AP, "wlan.da": CL, "wlan.bssid": AP, "wlan.ssid": "LAB-WIFI-01", "wlan.channel": 6})
    for src, dst, seq, algo, st, tt in [(CL, AP, 312, 1, 0, 0.602), (AP, CL, 4012, 2, 0, 0.605)]:
        body = struct.pack("<HHH", 0, algo, st)
        wifi_pkt(B, tt, 0x00b0, "Authentication", dst, src, AP, seq, body,
                 [("Authentication Algorithm: Open System (0)", 24, 2), ("Authentication SEQ: %d" % algo, 26, 2),
                  ("Status code: Successful (0x0000)", 28, 2)],
                 "Authentication, SN=%d, FN=0, Flags=........, Open System, %s" % (seq, "Request" if algo == 1 else "Response"),
                 {"wlan.fc.type_subtype": 11, "wlan.sa": src, "wlan.da": dst, "wlan.bssid": AP})
    body = struct.pack("<HH", 0x0411, 10) + ie(0, sb) + ie(1, bytes([0x82, 0x84]))
    wifi_pkt(B, 0.611, 0x0000, "Association Request", AP, CL, AP, 313, body,
             [("Capability Information: 0x0411", 24, 2), ("Listen Interval: 10", 26, 2),
              ("Tag: SSID parameter set: \"LAB-WIFI-01\"", 28, 13)],
             "Association Request, SN=313, FN=0, Flags=........, SSID=LAB-WIFI-01",
             {"wlan.fc.type_subtype": 0, "wlan.sa": CL, "wlan.da": AP, "wlan.bssid": AP, "wlan.ssid": "LAB-WIFI-01"})
    body = struct.pack("<HHH", 0x0411, 0, 0xc001) + ie(1, bytes([0x82, 0x84]))
    wifi_pkt(B, 0.614, 0x0010, "Association Response", CL, AP, AP, 4013, body,
             [("Capability Information: 0x0411", 24, 2), ("Status code: Successful (0x0000)", 26, 2),
              ("Association ID: 1 (0xc001)", 28, 2)],
             "Association Response, SN=4013, FN=0, Flags=........, Status: Successful",
             {"wlan.fc.type_subtype": 1, "wlan.sa": AP, "wlan.da": CL, "wlan.bssid": AP})
    RSN = bytes.fromhex("30140100000fac040100000fac040100000fac020c00")
    ANONCE = bytes(range(0x10, 0x30))
    SNONCE = bytes(range(0x50, 0x70))
    msgs = [
        (1, 0x008a, ANONCE, bytes(16), b"", 1, AP, CL, 0.802),
        (2, 0x010a, SNONCE, bytes.fromhex("8e2c51d7a0f3b9c64d1e27a58f09b3c2"), RSN, 1, CL, AP, 0.806),
        (3, 0x13ca, ANONCE, bytes.fromhex("1d7f03b6e925a41c8b3f6e02d9c74a58"), RSN, 2, AP, CL, 0.811),
        (4, 0x030a, bytes(32), bytes.fromhex("f40a2b93c17e58d02a6b9c4e31d7f805"), b"", 2, CL, AP, 0.815),
    ]
    for k, (num, ki, nonce, mic, kd, rep, src, dst, tt) in enumerate(msgs):
        key = (struct.pack("!BBHBHH", 2, 3, 95 + len(kd), 2, ki, 16) + struct.pack("!Q", rep)
               + nonce + bytes(16) + bytes(8) + bytes(8) + mic + struct.pack("!H", len(kd)) + kd)
        llc = bytes([0xaa, 0xaa, 0x03, 0, 0, 0, 0x88, 0x8e])
        seq = 4100 + k
        hdr = struct.pack("<H", 0x0208) + b"\x00\x00" + mac(dst) + mac(src) + mac(AP) + struct.pack("<H", (seq & 0xfff) << 4)
        full = RT + hdr + llc + key
        dot = [("Frame Control: 0x0208 (Data, From DS)", 0, 2), ("Duration: 0 microseconds", 2, 2),
               ("Receiver address: %s" % dst, 4, 6), ("Transmitter address: %s" % src, 10, 6),
               ("BSS Id: %s" % AP, 16, 6), ("Sequence number: %d" % seq, 22, 2)]
        llc_b = [("DSAP: SNAP (0xaa)", 0, 1), ("SSAP: SNAP (0xaa)", 1, 1), ("Control field: U, func=UI (0x03)", 2, 1),
                 ("Organization Code: Encapsulated Ethernet (0x000000)", 3, 3), ("Type: 802.1X Authentication (0x888e)", 6, 2)]
        kb = [("Version: 802.1X-2004 (2)", 0, 1), ("Type: Key (3)", 1, 1), ("Length: %d" % (95 + len(kd)), 2, 2),
              ("Descriptor Type: EAPOL RSN key (2)", 4, 1), ("Key Information: 0x%04x" % ki, 5, 2),
              ("Key Length: 16", 7, 2), ("Replay Counter: %d" % rep, 9, 8),
              ("Key Nonce: %s..." % nonce[:4].hex(), 17, 32), ("Key IV: 00000000...", 49, 16),
              ("Key MIC: %s" % mic.hex(), 81, 16), ("Key Data Length: %d" % len(kd), 97, 2)]
        if kd: kb.append(("Key Data: %d bytes" % len(kd), 99, len(kd)))
        B.tambah(tt, [("Radiotap Header v0, Length 8", full, RT_BID),
                      ("IEEE 802.11 Data, Flags: .....F.", full[8:], dot),
                      ("Logical-Link Control", llc + key, llc_b),
                      ("802.1X Authentication", key, kb)],
                 "Key (Message %d of 4)" % num, "EAPOL", src, dst,
                 {"wlan.fc.type_subtype": 8, "wlan.sa": src, "wlan.da": dst, "wlan.bssid": AP, "eapol.msg": num}, pad=False)
    return B.paket

# ---------------------------------------------------------------- keluaran & pemeriksaan
SKENARIO = [
    ("lab-wifi-01-handshake", "Handshake WPA2 LAB-WIFI-01", "wlan0mon",
     "Pemindaian beacon, autentikasi, asosiasi, dan empat pesan 4-way handshake WPA2 dari LAB-WIFI-01 (kanal 6). Data simulasi untuk pelatihan, bukan lalu lintas nyata.", scen_wifi),
    ("lab-jaringan-umum", "Lalu lintas Laboratorium Umum", "eth0",
     "Lalu lintas LAN laboratorium: ARP, DNS, TCP, HTTP dengan login plaintext, dan ping. Data simulasi untuk pelatihan, bukan lalu lintas nyata.", scen_lan),
    ("lab-pindai-port", "Pemindaian Port SYN", "eth0",
     "Pemindaian SYN dari 10.7.0.8 ke 10.7.0.80 pada tujuh port. Port 22 dan 80 terbuka, port lain menolak. Data simulasi untuk pelatihan, bukan lalu lintas nyata.", scen_scan),
    ("lab-jejak-internal", "Jejak Jaringan Internal", "eth0",
     "ARP dari 10.8.1.42 ke subnet laboratorium 10.8.1.0/24, pemindaian port ke berkas 10.8.1.8, dan login HTTP plaintext. Data simulasi untuk pelatihan, bukan lalu lintas nyata.", scen_jejak),
]

def cek(paket):
    # Pemeriksaan: checksum header IPv4 harus 0 saat dihitung ulang, dan semua bidang berada dalam frame.
    for p in paket:
        raw = bytes.fromhex(p["hex"]); n = len(raw)
        for lapis in p["rincian"]:
            assert lapis["mulai"] + lapis["panjang"] <= n, (p["no"], lapis["judul"])
            for b in lapis["bidang"]:
                assert b["mulai"] + b["panjang"] <= n, (p["no"], b["teks"])
            if lapis["judul"].startswith("Internet Protocol"):
                st = lapis["mulai"]
                assert csum(raw[st:st + 20]) == 0, ("checksum IPv4 salah", p["no"])

def main():
    os.makedirs(OUT, exist_ok=True)
    for sid, judul, iface, desk, fn in SKENARIO:
        paket = fn()
        cek(paket)
        data = {"id": sid, "judul": judul, "antarmuka": iface, "deskripsi": desk, "simulasi": True, "paket": paket}
        with open(os.path.join(OUT, sid + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        print(sid, len(paket), "paket", sum(p["panjang"] for p in paket), "byte")

if __name__ == "__main__":
    main()
