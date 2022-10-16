extends Area

export(NodePath) onready var output = get_node(output) as Position3D

func _on_right_hall_exit_body_entered(body):
	if body.name != "player": return
	var y_translation = body.translation.y
	output.global_translation.y = y_translation
	body.translation = output.global_translation
	body.rotation = output.global_rotation
