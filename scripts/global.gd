extends Node

var player_camera : Camera
var player : KinematicBody
var camera_spring : SpringArm
var external_camera : Camera
var full_view: Viewport
var split
var right_view: Viewport
var left_view: Viewport
var world: Viewport



func move_world(current_viewport: Viewport):
	var new_viewport : Viewport = null
	match current_viewport:
		full_view: 
			full_view.get_parent().set_visible(false)
			split.set_visible(true)
			new_viewport = left_view
		left_view: new_viewport = right_view
		right_view: 
			full_view.get_parent().set_visible(true)
			split.set_visible(false)
			new_viewport = full_view
	current_viewport.remove_child(world)
	new_viewport.add_child(world)
