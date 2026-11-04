extends SceneTree

# Smoke test layar terminal: membuka layar, memastikan output awal tampil,
# lalu mengirim perintah lewat jalur yang sama dengan tombol Enter.
# Dijalankan headless di CI. Keluar dengan kode 1 bila ada yang gagal.

func _initialize() -> void:
    var layar: Control = TerminalScreen.new()
    root.add_child(layar)
    await process_frame
    await process_frame

    var keluaran: RichTextLabel = layar.get("_keluaran")
    var gagal: Array = []
    if keluaran == null:
        print("SMOKE GAGAL: RichTextLabel tidak ditemukan")
        quit(1)
        return

    var awal := keluaran.get_parsed_text()
    if not awal.contains("Terminal siap"):
        gagal.append("output awal tidak tampil")
    if not awal.contains("/home/operator"):
        gagal.append("pwd awal tidak tampil")

    layar.call("_kirim", "ls")
    layar.call("_kirim", "xyz")
    var teks := keluaran.get_parsed_text()
    if not teks.contains("Documents"):
        gagal.append("ls tidak menampilkan isi home")
    if not teks.contains("bash: xyz: perintah tidak ditemukan"):
        gagal.append("galat perintah tidak tampil")

    if gagal.is_empty():
        print("SMOKE LULUS: layar terminal menampilkan output dan memproses perintah")
        quit(0)
    else:
        for g in gagal:
            print("SMOKE GAGAL: " + String(g))
        quit(1)
