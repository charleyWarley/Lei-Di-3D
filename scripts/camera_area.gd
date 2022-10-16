extends Area

var previous_view

func _on_camera_area_body_entered(body):
	if body.name != "player": return
	previous_view = body.view_mode
	print(previous_view)
	print("camera area entered")
	if has_node("external_camera"):
		var camera = $external_camera
		camera.make_current()
		Global.external_camera = camera
		if camera.has_method("set_target"):
			camera.set_target(body)
	body.view_mode = "third watch"


func _on_camera_area_body_exited(body):
	if body.name != "player": return
	print("camera area left")
	Global.player_camera.make_current()
	Global.set_deferred("external_camera", null)
	if previous_view == "first person": 
		print("return to first person")
		body.first_person()
	else: 
		print("return to third follow")
		body.third_follow()
