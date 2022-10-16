extends KinematicBody

enum frictions {
	AIR = 20,
	BASIC = 40
}

enum speeds {
	WALK = 10,
	RUN = 17
}

enum fovs {
	WALK = 45
	RUN = 50
}

const ACCELERATION : int = 50
const GRAVITY : int = -40
const JUMP_BUFFER := 0.3
const JUMP_IMPULSE := 20.0

var rot_speed : int = 9
var push_power : int = 1
var max_speed : int = 10
var controller_sensitivity := 1.4
var time_pressed_jump := 0.0
var velocity := Vector3.ZERO
var snap_vector := Vector3.ZERO
var items_in_hand := []
var is_grounded := false
var view_mode := "third follow"

export(NodePath) onready var spring_arm = get_node(spring_arm) as SpringArm
export(NodePath) onready var pivot = get_node(pivot) as Position3D
export(NodePath) onready var pickup_spot = get_node(pickup_spot) as Position3D
export(NodePath) onready var camera = get_node(camera) as ClippedCamera
export(NodePath) onready var ray = get_node(ray) as RayCast
export(NodePath) onready var anim_player = get_node(anim_player) as AnimationPlayer


func _input(_event):
	if Input.is_action_pressed("run"): 
		max_speed = speeds.RUN
		Global.player_camera.fov = fovs.RUN
	elif Input.is_action_just_released("run"): 
		max_speed = speeds.WALK
		Global.player_camera.fov = fovs.WALK


func _ready():
	Global.player = self


func _physics_process(delta: float) -> void:
	var input_vector = get_input_vector()
	var direction = get_direction(input_vector)
	if Global.player_camera.fov != fovs.WALK and max_speed != speeds.WALK: Global.player_camera.fov = fovs.WALK
	apply_friction(direction, delta)
	update_snap_vector()
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	jump()
	apply_gravity(delta)
	apply_controller_rotation()
	apply_movement(input_vector, direction, delta)
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, PI/4, false)
	check_animations(was_grounded)
	check_ray()
	check_collisions()


func check_collisions():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group("moveable"):
			collision.collider.apply_central_impulse(-collision.normal * velocity.length() * push_power)


func check_ray():
	if ray.get_collider() != null: if Input.is_action_just_pressed("interact"): pick_up(ray.get_collider())
	if items_in_hand != []: if Input.is_action_just_released("interact"): drop()


func jump():
	if Global.external_camera != null: if Global.external_camera.is_following == true: return
	var was_jump_pressed = Input.is_action_just_pressed("jump")
	var was_jump_released = Input.is_action_just_released("jump")
	if was_jump_pressed: time_pressed_jump = get_curr_time()
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap_vector = Vector3.ZERO
		velocity.y = JUMP_IMPULSE
	if was_jump_released and velocity.y > JUMP_IMPULSE / 2:
		velocity.y = JUMP_IMPULSE / 5


func check_animations(was_grounded: bool):
	if !is_grounded and was_grounded: play_anim("jump")
	if is_grounded:
		if velocity.x == 0 and velocity.z == 0: play_anim("idle")
		else: play_anim("walk")


func get_curr_time() -> float:
	return OS.get_ticks_msec() / 1000.0


func pick_up(item: RigidBody) -> void:
	if item == null: return
	if items_in_hand != []: 
		print("hands are full")
		return
	print(item.name)
	item.disable()
	item.get_parent().remove_child(item)
	pickup_spot.add_child(item)
	item.translation = pickup_spot.translation
	items_in_hand.append(item)


func drop() -> void:
	var item = items_in_hand[0]
	item.get_parent().remove_child(item)
	get_parent().add_child(item)
	items_in_hand.remove(0)
	item.translation = translation
	item.translation.z += pickup_spot.translation.z * 1.5
	item.translation.y += pickup_spot.translation.y
	item.enable()


func get_input_vector() -> Vector3:
	var input_vector := Vector3.ZERO
	input_vector.x = Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left")
	input_vector.y = Input.get_action_strength("look_left") - Input.get_action_strength("look_right")
	input_vector.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector


func get_direction(input_vector: Vector3) -> Vector3:
	var direction = (input_vector.x * transform.basis.x) + (input_vector.z * transform.basis.z)
	return direction


func apply_movement(input_vector: Vector3, direction: Vector3, delta: float) -> void:
	if view_mode == "first person": return
	if direction.x or direction.z != 0:
		velocity.x = velocity.move_toward(direction * max_speed, ACCELERATION * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, ACCELERATION * delta).z
		if input_vector.z <= 0: input_vector.z = 0
		if input_vector.x != 0: return
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-input_vector.x, input_vector.z), rot_speed * delta)
	if input_vector.y == 0:
		spring_arm.set_as_toplevel(true)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-input_vector.x, input_vector.z), rot_speed * delta)
		spring_arm.set_as_toplevel(false)


func apply_friction(direction: Vector3, delta: float) -> void:
	if direction == Vector3.ZERO:
		if is_grounded: velocity = velocity.move_toward(Vector3.ZERO, frictions.BASIC * delta)
		else: 
			velocity.x = velocity.move_toward(Vector3.ZERO, frictions.AIR * delta).x
			velocity.z = velocity.move_toward(Vector3.ZERO, frictions.AIR * delta).z


func apply_gravity(delta: float) -> void:
	velocity.y += GRAVITY * delta
	velocity.y = clamp(velocity.y, GRAVITY, JUMP_IMPULSE)


func apply_controller_rotation() -> void:
	var camera_rot_vector := Vector2.ZERO
	var player_rot_vector := Vector2.ZERO
	player_rot_vector.x =  Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	camera_rot_vector.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	camera_rot_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	if InputEventJoypadMotion:
		if view_mode != "first person": 
			spring_arm.set_as_toplevel(true)
		else:
			camera_rot_vector.y = clamp(camera_rot_vector.y, -60, 60)
			spring_arm.rotate_x(deg2rad(-camera_rot_vector.y) * controller_sensitivity)
		rotate_y(deg2rad(-player_rot_vector.x) * controller_sensitivity)
		if view_mode != "first person": 
			spring_arm.set_as_toplevel(false)
		rotate_y(deg2rad(-camera_rot_vector.x) * controller_sensitivity)
		if view_mode == "third follow":
			pivot.set_as_toplevel(true)
			rotate_y(deg2rad(-camera_rot_vector.x) * controller_sensitivity)
			pivot.set_as_toplevel(false)


func update_snap_vector() -> void:
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN



		

func first_person():
	view_mode = "first person"
	pivot.remove_child(ray)
	spring_arm.add_child(ray)
	ray.translation = spring_arm.translation
	spring_arm.rotation.y = pivot.rotation.y
	

func third_follow():
	view_mode = "third follow"
	if ray.get_parent() == spring_arm:
		spring_arm.remove_child(ray)
		pivot.add_child(ray)
		ray.translation = Vector3(0, 1.821, -0.833)
		
	

func play_anim(anim) -> void:
	if anim == anim_player.current_animation: return
	anim_player.play(anim)


func _on_fov_updated(value):
	camera.fov = value
