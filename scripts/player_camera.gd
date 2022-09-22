extends Camera


func _ready():
	Global.player_camera = self
	Global.camera_spring = get_parent()
