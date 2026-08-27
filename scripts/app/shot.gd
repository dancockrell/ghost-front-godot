extends Node
func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("GF_SHOT"))
	print("shot saved: ", OS.get_environment("GF_SHOT"))
	get_tree().quit(0)
