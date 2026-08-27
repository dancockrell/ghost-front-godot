extends Node

## Renders the whole greybox course in one frame, so the level design can be
## judged as a shape rather than one screen at a time.

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var lvl := get_parent()
	var cam: Camera2D = lvl.get_node("Player/Cam")
	# find the extent of the built course
	var solids: Array = lvl.get("_solids")
	var minp := Vector2(1e9, 1e9)
	var maxp := Vector2(-1e9, -1e9)
	for r in solids:
		minp = minp.min(r.position)
		maxp = maxp.max(r.position + r.size)
	var span := maxp - minp
	var vp := Vector2(get_viewport().size)
	var z: float = minf(vp.x / (span.x * 1.06), vp.y / (span.y * 1.15))
	cam.position_smoothing_enabled = false
	cam.drag_horizontal_enabled = false
	cam.drag_vertical_enabled = false
	cam.top_level = true
	cam.zoom = Vector2(z, z)
	cam.global_position = minp + span * 0.5
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("GF_SHOT"))
	print("overview saved, span=", span, " zoom=", z)
	get_tree().quit(0)
