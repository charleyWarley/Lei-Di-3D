extends Area



func _on_camera_area_body_entered(body):
	if body.name != "player": return
	print("camera area entered")
	if has_node("external_camera"):
		var camera = $external_camera
		camera.make_current()
		Global.external_camera = camera
		if camera.has_method("set_target"):
			camera.set_target(body)


func _on_camera_area_body_exited(body):
	if body.name != "player": return
	print("camera area left")
	Global.player_camera.make_current()
	Global.external_camera = null
