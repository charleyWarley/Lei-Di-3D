extends SpringArm


onready var camera = $player_camera


func _ready():
	Global.player_camera = camera
	Global.camera_spring = self


