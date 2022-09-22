extends RigidBody

onready var shape = $CollisionShape

func _ready():
	add_to_group("moveable")

func disable():
	print("disabled")
	set_mode(RigidBody.MODE_STATIC)
	shape.set_disabled(true)

func enable():
	print("enabled")
	set_mode(RigidBody.MODE_RIGID)
	shape.set_disabled(false)
