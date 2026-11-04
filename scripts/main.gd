extends Node2D

# Scene uji: hanya memastikan APK terbuka dan Godot berjalan native di HP.
# Belum ada gameplay, karakter, peta, atau UI utama.

func _ready() -> void:
	print("Game Baru: scene uji dimuat, Godot ", Engine.get_version_info().string)
