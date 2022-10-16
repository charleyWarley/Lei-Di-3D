extends Camera

export var turn_speed := 80
export var follow_distance := 6
export var is_following := true
export var follow_speed := 2

var target = null setget set_target

func _process(delta):
	if target == null: return
	var to_target = target.global_transform.origin - global_transform.origin
	var distance = to_target.length()
	var move = to_target
	move.y = 0
	to_target = to_target.normalized()
	if is_following:
		var acceleration = distance - follow_distance
		global_transform.origin += acceleration * move  * delta
	var up = global_transform.basis.y
	var right = global_transform.basis.x
	var r_dot = to_target.dot(right)
	var u_dot = to_target.dot(up)
	if !is_following: 
		if abs(r_dot) > 0.1: turn_speed = lerp(turn_speed, 150, delta)
	elif turn_speed != 80: lerp(turn_speed, 80, delta)
	rotation_degrees.y += turn_speed * -r_dot * delta
	rotation_degrees.x += turn_speed * u_dot * delta


func set_target(t):
	target = t
