extends Control

onready var world = $ViewportContainer/full_view/World
onready var full_view = $ViewportContainer/full_view
onready var left_view = $split_view/ViewportContainer/left_view
onready var right_view = $split_view/ViewportContainer2/right_view
onready var split = $split_view

func _input(event):
	if Input.is_action_just_pressed("change_view"): 
		if Global.camera_spring.spring_length == 6:
			if Global.player_camera.is_current():  Global.camera_spring.spring_length = -1
			else: Global.player_camera.make_current()
		else: 
			Global.camera_spring.spring_length = 6
			if Global.external_camera != null: Global.external_camera.make_current()
		print("camera view changed")
	if Input.is_action_just_pressed("move_world"):
		Global.move_world(world.get_parent())

