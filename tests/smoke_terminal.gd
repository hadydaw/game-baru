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
    layar.call("_selesaikan_cepat")
    layar.call("_kirim", "xyz")
    layar.call("_selesaikan_cepat")
    var teks := keluaran.get_parsed_text()
    if not teks.contains("dokumen"):
        gagal.append("ls tidak menampilkan isi home")
    if not teks.contains("bash: xyz: perintah tidak ditemukan"):
        gagal.append("galat perintah tidak tampil")

    # Antrean: perintah yang dikirim saat animasi berjalan menunggu giliran.
    layar.call("_kirim", "nmap gerbang")
    layar.call("_kirim", "pwd")
    var antrean: Array = layar.get("_antrean")
    if antrean.size() != 1:
        gagal.append("perintah saat animasi tidak masuk antrean")
    layar.call("_selesaikan_cepat")
    if not keluaran.get_parsed_text().contains("Pemindaian selesai") or not (layar.get("_antrean") as Array).is_empty():
        gagal.append("antrean tidak dijalankan setelah animasi selesai")

    # Ctrl sebagai modifier: Ctrl lalu C membatalkan baris, Ctrl lalu L membersihkan layar.
    var masukan: LineEdit = layar.get("_masukan")
    layar.call("_set_teks", "tes")
    layar.call("_tekan_tombol", "Ctrl")
    layar.call("_tekan_tombol", "c")
    if masukan.text != "" or not keluaran.get_parsed_text().contains("tes^C"):
        gagal.append("Ctrl+C tidak membatalkan baris")
    layar.call("_set_teks", "abc")
    layar.call("_tekan_tombol", "Ctrl")
    layar.call("_tekan_tombol", "l")
    if keluaran.get_parsed_text().contains("tes^C") or masukan.text != "abc":
        gagal.append("Ctrl+L tidak membersihkan layar atau mengubah masukan")
    # Keyboard HP mengetik langsung ke LineEdit: Ctrl lalu U harus menghapus baris.
    layar.call("_set_teks", "hapus saya")
    layar.call("_tekan_tombol", "Ctrl")
    masukan.insert_text_at_caret("u")
    # Keyboard HP memicu text_changed; di headless insert_text_at_caret tidak memicunya, jadi disimulasikan.
    masukan.text_changed.emit(masukan.text)
    if masukan.text != "":
        gagal.append("Ctrl+U dari keyboard tidak menghapus baris")
    layar.call("_set_teks", "")

    if gagal.is_empty():
        print("SMOKE LULUS: layar terminal menampilkan output dan memproses perintah")
        quit(0)
    else:
        for g in gagal:
            print("SMOKE GAGAL: " + String(g))
        quit(1)
