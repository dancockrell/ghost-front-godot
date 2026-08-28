extends Node

## Renders the game at a forced attenuation, so the honest channel can be seen
## rather than assumed.
##
## Exists because "the shader is correctly invisible at 0%" and "the shader is
## not running" produce an identical screenshot. The only way to tell is to
## drive it to a value where it must be obvious and look again.
##
## GF_FADE sets the true attenuation; GF_SHOT is the output path.

func _ready() -> void:
	await get_tree().create_timer(0.9).timeout
	var lvl := get_parent()
	var fade := float(OS.get_environment("GF_FADE"))
	var p: Player = lvl.get("_player")
	if p != null:
		p.phase.attenuation = fade
	# let the runner push it into the material
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("GF_SHOT"))
	print("fade shot saved at attenuation %.2f" % fade)
	get_tree().quit(0)
