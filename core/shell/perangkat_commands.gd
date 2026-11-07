class_name PerangkatCommands
extends RefCounted

# Menghubungkan perangkat untuk Device Manager (tombol Hubungkan) dan tes. Perubahan dilakukan oleh Perangkat dan Economy.

# Menghubungkan perangkat dengan driver yang terpasang. Dipakai terminal dan Device Manager.
static func hubungkan(s: ShellSession) -> Dictionary:
	var p := s.perangkat
	var chipset := ""
	var didukung: Array = []
	var driver := ""
	if p.sudah_dirakit():
		chipset = Perangkat.chipset_adapter(p.adapter())
		driver = s.repositori.driver_untuk(chipset)
		if driver != "":
			didukung = Array(Repositori.item(driver).get("chipset", []))
	var h := p.hubungkan(driver, didukung)
	if bool(h["ok"]):
		s.jaringan.buka("device:terhubung")
	return h
