extends Camera

export(NodePath) onready var exit = get_node(exit) as Position3D

func _ready():
	global_translation = exit.global_translation
	#Global.rotation = exit.global_rotation


func _process(delta):
	global_translation.y = Global.player.translation.y + 2
#	global_rotation.y = Global.player.rotation.y
