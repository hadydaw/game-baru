class_name ShellSession
extends RefCounted

# Sesi shell pemain: direktori kerja, pengguna, riwayat, filesystem aktif, dan jaringan.
# Keluaran setiap perintah berupa Array of {tipe, teks}. Tipe: info, error, clear.
# Saat SSH aktif, perintah diteruskan ke sesi jarak jauh (ssh_aktif) sampai pemain mengetik exit.

const HOME := "/home/operator"
const USER := "operator"
const GRUP := ["operator"]
const LOKAL := "jtn"

var fs: Vfs
# Identitas pemain per sesi. Sesi jarak jauh memakai akun "operator" milik server tersebut.
var user: String = USER
var home: String = HOME
var grup: Array = [USER]
var cwd: String = HOME
var riwayat: Array = []
var host: String = LOKAL
var jaringan: Jaringan
var economy: Economy
var inventory: Inventory
var market: BlackMarket
var hadiah_diambil: Array = []  # flag misi yang hadiahnya sudah diberikan
var reputation: Reputation
var ssh_aktif: ShellSession = null
var misi: Dictionary = {}       # id misi -> "aktif" | "selesai" (tidak ada = belum diterima)
var pesan_misi: Array = []      # pesan masuk dari pengirim misi, urutan kedatangan
var lokasi: Dictionary = {}     # lokasi pemain di peta dunia: {"negara": kode, "kota": kode}
var email: Dictionary = {}      # status E-Mail: status pesan, dibaca, dan sambutan sudah tampil
var perangkat: Perangkat = Perangkat.new()   # perangkat keras: komponen, perakitan, koneksi
var repositori: Repositori = Repositori.new() # Tools Repository: software yang terpasang
var wifi: WifiLab = WifiLab.new()             # keadaan pengujian Wi-Fi laboratorium
var xp: int = 0                               # pengalaman dari misi
var misi_tahap: Dictionary = {}               # id misi -> Array nomor tahap yang sudah diberi umpan balik

func _init(p_fs: Vfs, p_jaringan: Jaringan = null, p_pengguna: String = USER) -> void:
    fs = p_fs
    user = p_pengguna
    home = "/home/" + user
    grup = [user]
    cwd = home
    jaringan = p_jaringan if p_jaringan != null else Jaringan.muat()
    economy = Economy.baru()
    inventory = Inventory.baru()
    market = BlackMarket.baru()
    reputation = Reputation.baru()

# Seluruh keadaan sesi lokal yang perlu disimpan: filesystem, direktori aktif, riwayat, dan jaringan.
func to_dict() -> Dictionary:
    return {"misi": misi.duplicate(), "pesan_misi": pesan_misi.duplicate(true), "pengguna": user, "fs": fs.akar, "cwd": cwd, "riwayat": riwayat, "jaringan": jaringan.to_dict(), "ekonomi": economy.to_dict(), "reputasi": reputation.to_dict(), "inventaris": inventory.to_dict(), "pasar": market.to_dict(), "hadiah": hadiah_diambil.duplicate(), "lokasi": lokasi.duplicate(), "email": email.duplicate(true), "perangkat": perangkat.to_dict(), "repositori": repositori.to_dict(), "wifi": wifi.to_dict(), "xp": xp, "misi_tahap": misi_tahap.duplicate(true)}

static func dari_dict(d: Dictionary) -> ShellSession:
    var j := Jaringan.muat()
    if typeof(d.get("jaringan")) == TYPE_DICTIONARY:
        j.terapkan(d["jaringan"])
    var nama := nama_pengguna_aktif()
    var lama := String(d.get("pengguna", USER))
    var fs_dict: Dictionary = d.get("fs", {})
    var cwd_tersimpan := String(d.get("cwd", "/home/" + lama))
    if lama != nama:
        fs_dict = Vfs.ganti_pengguna(fs_dict, lama, nama)
        cwd_tersimpan = pindah_home(cwd_tersimpan, lama, nama)
    var s := ShellSession.new(Vfs.new(fs_dict), j, nama)
    s.cwd = cwd_tersimpan if s.fs.ada(cwd_tersimpan) else s.home
    s.riwayat = Array(d.get("riwayat", []))
    if typeof(d.get("ekonomi")) == TYPE_DICTIONARY:
        s.economy.terapkan(d["ekonomi"])
    if typeof(d.get("reputasi")) == TYPE_DICTIONARY:
        s.reputation.terapkan(d["reputasi"])
    if typeof(d.get("inventaris")) == TYPE_DICTIONARY:
        s.inventory.terapkan(d["inventaris"])
    if typeof(d.get("pasar")) == TYPE_DICTIONARY:
        s.market.terapkan(d["pasar"])
    s.hadiah_diambil = Array(d.get("hadiah", []))
    if typeof(d.get("misi")) == TYPE_DICTIONARY:
        s.misi = Dictionary(d["misi"]).duplicate()
    s.pesan_misi = Array(d.get("pesan_misi", [])).duplicate(true)
    if typeof(d.get("email")) == TYPE_DICTIONARY:
        s.email = Dictionary(d["email"]).duplicate(true)
    if typeof(d.get("lokasi")) == TYPE_DICTIONARY:
        s.lokasi = Dictionary(d["lokasi"]).duplicate()
    if typeof(d.get("perangkat")) == TYPE_DICTIONARY:
        s.perangkat.terapkan(d["perangkat"])
    if typeof(d.get("repositori")) == TYPE_DICTIONARY:
        s.repositori.terapkan(d["repositori"])
    if typeof(d.get("wifi")) == TYPE_DICTIONARY:
        s.wifi.terapkan(d["wifi"])
    s.xp = int(d.get("xp", 0))
    if typeof(d.get("misi_tahap")) == TYPE_DICTIONARY:
        s.misi_tahap = Dictionary(d["misi_tahap"]).duplicate(true)
    # Simpanan lama: node yang sudah terbuka lewat tetangga dianggap sudah dipindai.
    PerintahScan.migrasi(s)
    # Simpanan lama belum punya status misi; Misi.perbarui memberi status sesuai flag yang sudah ada.
    Misi.perbarui(s)
    return s

# Nama pengguna aktif dari Login. Bila belum pernah diisi, memakai akun bawaan.
static func nama_pengguna_aktif() -> String:
    var n := Pengaturan.nama_profil()
    return n if n != "" else USER

# Memindahkan awalan home lama ke home baru pada sebuah jalur. Jalur di luar home tidak berubah.
static func pindah_home(jalur: String, lama: String, baru: String) -> String:
    var rumah_lama := "/home/" + lama
    if jalur == rumah_lama or jalur.begins_with(rumah_lama + "/"):
        return "/home/" + baru + jalur.substr(rumah_lama.length())
    return jalur

# Mengganti identitas sesi yang sudah berjalan, misalnya setelah nama di Login diubah.
func sinkron_pengguna(nama: String) -> void:
    if nama == "" or nama == user:
        return
    fs.akar = Vfs.ganti_pengguna(fs.akar, user, nama)
    cwd = pindah_home(cwd, user, nama)
    user = nama
    home = "/home/" + nama
    grup = [nama]

func prompt() -> String:
    if ssh_aktif != null:
        return ssh_aktif.prompt()
    var tampil := cwd
    if cwd == home:
        tampil = "~"
    elif cwd.begins_with(home + "/"):
        tampil = "~" + cwd.substr(home.length())
    return "%s@%s:%s$" % [user, host, tampil]

# Menjalankan perintah lalu memperbarui misi bila ada flag baru. Keluaran perintah tidak diubah;
# pesan misi baru ditampilkan Terminal lewat notifikasi_misi(). Remote (SSH) tidak memperbarui misi.
func jalankan(masukan: String) -> Array:
    var sebelum := jaringan.progres.size()
    var keluaran := _jalankan_dasar(masukan)
    if host != LOKAL:
        return keluaran
    # Setiap perintah yang dijalankan di terminal lokal tercatat sebagai flag (dipakai misi tutorial).
    var t := ShellParser.tokenkan(masukan)
    if not t.is_empty():
        jaringan.buka("cmd:" + String(t[0]))
    if jaringan.progres.size() != sebelum:
        Misi.perbarui(self)
    return keluaran

# Pesan misi yang belum pernah ditampilkan di Terminal. Setiap pesan hanya dilaporkan sekali.
func notifikasi_misi() -> Array:
    var hasil: Array = []
    for p in pesan_misi:
        if not bool(p["dilaporkan"]):
            p["dilaporkan"] = true
            hasil.append(baris("info", Bahasa.dua("[Pusat Misi] Pesan baru dari %s: %s. Buka aplikasi Misi untuk membaca.", "[Mission Center] New message from %s: %s. Open the Missions app to read it.", [p["dari"], p["subjek"]])))
    return hasil

func _jalankan_dasar(masukan: String) -> Array:
    if ssh_aktif != null:
        var t := masukan.strip_edges()
        if t == "exit":
            riwayat.append(t)
            var tutup := ssh_aktif.host
            ssh_aktif = null
            return [baris("info", Bahasa.dua("Koneksi ke %s ditutup.", "Connection to %s closed.", [tutup]))]
        if t != "":
            riwayat.append(t)
        return ssh_aktif.jalankan(masukan)
    var p := ShellParser.parse(masukan)
    if bool(p["kosong"]):
        return []
    riwayat.append(String(p["mentah"]))
    var token := ShellParser.tokenkan(masukan)
    var idx := _cari_redirect(token)
    if idx == -1:
        return ShellCommands.jalankan(self, p)
    return _jalankan_redirect(token, idx, masukan)

# Teks satu baris untuk ditampilkan di luar Terminal: memakai kunci bahasa bila ada, lalu memilih bahasa aktif.
static func teks_baris(b: Dictionary) -> String:
    var kunci := String(b.get("kunci", ""))
    var teks := String(b.get("teks", ""))
    if kunci != "":
        var args: Array = b.get("args", [])
        teks = Bahasa.t(kunci) % args if not args.is_empty() else Bahasa.t(kunci)
        if String(b.get("perintah", "")) != "":
            teks = "bash: %s: %s" % [String(b["perintah"]), teks]
    return Bahasa.pilih(teks)

func baris(tipe: String, teks: String) -> Dictionary:
    return {"tipe": tipe, "teks": teks}

func galat(perintah: String, pesan: String) -> Dictionary:
    return baris("error", "bash: %s: %s" % [perintah, pesan])

# Baris yang teksnya diambil dari kunci bahasa. Terminal bisa merendernya ulang saat bahasa diganti.
func baris_kunci(tipe: String, kunci: String, args: Array = []) -> Dictionary:
    return {"tipe": tipe, "kunci": kunci, "args": args, "teks": Bahasa.t(kunci) % args if not args.is_empty() else Bahasa.t(kunci)}

func galat_kunci(perintah: String, kunci: String, args: Array = []) -> Dictionary:
    var b := baris_kunci("error", kunci, args)
    b["teks"] = "bash: %s: %s" % [perintah, b["teks"]]
    b["perintah"] = perintah
    return b

# Mengubah hasil {ok, kunci, args} dari perangkat atau repositori menjadi baris terminal.
func hasil_ke_baris(perintah: String, h: Dictionary) -> Dictionary:
    if bool(h.get("ok", false)):
        return baris_kunci("info", String(h["kunci"]), Array(h.get("args", [])))
    return galat_kunci(perintah, String(h["kunci"]), Array(h.get("args", [])))

# Mengembalikan indeks token yang berisi operator > atau >>, atau -1.
func _cari_redirect(token: Array) -> int:
    for i in range(token.size()):
        var t := String(token[i])
        if t.begins_with(">"):
            return i
    return -1

# Menjalankan perintah lalu menulis keluarannya ke berkas (> menimpa, >> menambah).
# Hanya keluaran info yang ditulis. Galat tetap tampil di layar, seperti di shell sungguhan.
func _jalankan_redirect(token: Array, idx: int, masukan: String) -> Array:
    var op := String(token[idx])
    var tambah := op.begins_with(">>")
    var tujuan := op.substr(2 if tambah else 1)
    var sisa := idx + 1
    if tujuan.is_empty():
        if sisa >= token.size():
            return [galat("bash", Teks.t("bash.sintaks"))]
        tujuan = String(token[sisa])
        sisa += 1
    if sisa < token.size():
        return [galat("bash", Teks.t("bash.redirect_banyak"))]
    if idx == 0:
        return [galat("bash", Teks.t("bash.kosong"))]
    var p := ShellParser.dari_token(token.slice(0, idx), masukan)
    var keluaran := ShellCommands.jalankan(self, p)
    var teks: Array = []
    for b in keluaran:
        if String(b["tipe"]) == "error":
            return keluaran
        teks.append(String(b["teks"]))
    return _tulis_berkas(tujuan, "\n".join(PackedStringArray(teks)), tambah)

func _tulis_berkas(tujuan: String, isi: String, tambah: bool) -> Array:
    var abs := Vfs.normalisasi(cwd, tujuan, home)
    var nama := fs.nama_terakhir(abs)
    var induk_path := fs.induk(abs)
    var induk_node := fs.ambil(induk_path)
    if induk_node.is_empty() or String(induk_node.get("tipe", "")) != "dir":
        return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.tidak_ada_induk")])]
    if not Permissions.boleh(induk_node, user, grup, "w"):
        return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.izin")])]
    var ada := fs.ambil(abs)
    if not ada.is_empty():
        if String(ada.get("tipe", "")) == "dir":
            return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.direktori")])]
        if not Permissions.boleh(ada, user, grup, "w"):
            return [galat("bash", "%s: %s" % [tujuan, Teks.t("err.izin")])]
        var lama := ShellCommands.isi_berkas(ada) if tambah else ""
        var gabung := isi
        if tambah and not lama.is_empty():
            gabung = lama + "\n" + isi
        ada["isi"] = gabung
        ada["ukuran"] = gabung.length()
        return []
    var baru := {"tipe": "file", "pemilik": user, "grup": user, "izin": "rw-r-----", "isi": isi, "ukuran": isi.length()}
    fs.tambah(induk_path, nama, baru)
    return []
