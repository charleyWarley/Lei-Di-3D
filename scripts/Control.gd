extends Control

export(NodePath) onready var world = get_node(world)
export(NodePath) onready var full_view = get_node(full_view)
export(NodePath) onready var left_view = get_node(left_view)
export(NodePath) onready var right_view = get_node(right_view)
export(NodePath) onready var split = get_node(split)

func _input(_event):
	if Input.is_action_just_pressed("change_view"): 
		if Global.player.view_mode == "third follow":
			if Global.player_camera.is_current():  
				Global.player.first_person()
				Global.camera_spring.spring_length = -1
			else: Global.player_camera.make_current()
		else: 
			Global.camera_spring.spring_length = 6
			Global.player.third_follow()
			if Global.external_camera != null: Global.external_camera.make_current()
		print("camera view changed")
	if Input.is_action_just_pressed("move_world"):
		var viewport = world.get_parent()
		move_world(viewport)


func move_world(current_viewport: Viewport):
	var new_viewport : Viewport = null
	match current_viewport:
		full_view:
			full_view.get_parent().set_visible(false)
			split.set_visible(true)
			new_viewport = left_view
			Global.player.fov = 56
		left_view: 
			new_viewport = right_view
			Global.player.fov = 56
		right_view:
			full_view.get_parent().set_visible(true)
			split.set_visible(false)
			new_viewport = full_view
			Global.player.fov = 45
	current_viewport.remove_child(world)
	new_viewport.add_child(world)
