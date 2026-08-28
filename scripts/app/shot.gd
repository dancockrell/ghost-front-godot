extends Node

## Renders one frame of a level to PNG. GF_LEVEL picks the chapter (0-based),
## GF_SHOT is the output path.

func _ready() -> void:
	var lvl := get_parent()
	var want := int(OS.get_environment("GF_LEVEL"))
	if want > 0:
		await get_tree().create_timer(0.4).timeout
		lvl.call("_load_level", want)
	await get_tree().create_timer(1.1).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("GF_SHOT"))
	print("shot saved: level %d -> %s" % [want, OS.get_environment("GF_SHOT")])
	get_tree().quit(0)
