extends KinematicBody

export(int) var max_speed = 10
export(int) var acceleration = 50
export(int) var friction = 200
export(int) var air_friction = 100
export(int) var gravity = -40
export(int) var jump_impulse = 20
export(float) var mouse_sensitivity = 0.1
export(int) var controller_sensitivity = 3
export(int) var rot_speed = 5
export(int, 0, 10) var push = 1

var velocity : Vector3
var snap_vector : Vector3
var items_in_hand : Array
var time_pressed_jump : float
var is_grounded := false
const JUMP_BUFFER : float = 0.3

export(NodePath) onready var spring_arm = get_node(spring_arm) as SpringArm
export(NodePath) onready var pivot = get_node(pivot) as Position3D
export(NodePath) onready var pickup_spot = get_node(pickup_spot) as Position3D
export(NodePath) onready var camera = get_node(camera) as Camera
export(NodePath) onready var ray = get_node(ray) as RayCast
export(NodePath) onready var anim_player = get_node(anim_player) as AnimationPlayer


func _ready():
	Global.player = self

func _physics_process(delta: float) -> void:
	var input_vector = get_input_vector()
	var direction = get_direction(input_vector)
	apply_movement(input_vector, direction, delta)
	apply_friction(direction, delta)
	update_snap_vector()
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	jump()
	
	apply_gravity(is_grounded, delta)
	apply_controller_rotation()
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg2rad(-60), deg2rad(15))
	
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, PI / 4, false)
	
	
	check_animations(is_grounded, was_grounded)
	
	
	if ray.get_collider() != null: if Input.is_action_just_pressed("interact"): pick_up(ray.get_collider())
	if items_in_hand != []: if Input.is_action_just_released("interact"): drop()
	for idx in get_slide_count():
		var collision = get_slide_collision(idx)
		if collision.collider.is_in_group("moveable"):
			collision.collider.apply_central_impulse(-collision.normal * velocity.length() * push)
func jump():
	var was_jump_pressed = Input.is_action_just_pressed("jump")
	var was_jump_released = Input.is_action_just_released("jump")
	if was_jump_pressed: time_pressed_jump = get_curr_time()

	if Input.is_action_just_pressed("jump"):
		print("jump")
		snap_vector = Vector3.ZERO
		velocity.y = jump_impulse
	if was_jump_released and velocity.y > jump_impulse / 2:
		velocity.y = jump_impulse / 5

func check_animations(is_grounded: bool, was_grounded: bool):
	if !is_grounded and was_grounded: play_anim("jump")
	if is_grounded:
		if velocity.x == 0 and velocity.z == 0:
			play_anim("idle")
		else:
			play_anim("walk")


func get_curr_time() -> float:
	return OS.get_ticks_msec() / 1000.0
	
		
func pick_up(item: RigidBody) -> void:
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
	item.translation.z += pickup_spot.translation.z
	item.translation.y += pickup_spot.translation.y
	item.enable()
	
	
func get_input_vector() -> Vector3:
	var input_vector = Vector3.ZERO
	#input_vector.x = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	input_vector.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector
	
	
func get_direction(input_vector: Vector3) -> Vector3:
	var direction = (input_vector.x * transform.basis.x) + (input_vector.z * transform.basis.z)
	return direction
	
	
func apply_movement(input_vector: Vector3, direction: Vector3, delta: float) -> void:
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, acceleration * delta).z
#		pivot.look_at(global_transform.origin + direction, Vector3.UP)
		if input_vector.z <= 0: input_vector.z = 0
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-input_vector.x, input_vector.z), rot_speed * delta)


func apply_friction(direction: Vector3, delta: float) -> void:
	if direction == Vector3.ZERO:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		else:
			velocity.x = velocity.move_toward(Vector3.ZERO, air_friction * delta).x
			velocity.z = velocity.move_toward(Vector3.ZERO, air_friction * delta).z


func apply_gravity(is_grounded: bool, delta: float) -> void:
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jump_impulse)
	#if is_grounded:
	#	velocity.y = -0.1

func update_snap_vector() -> void:
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN



func apply_controller_rotation() -> void:
	var axis_vector = Vector2.ZERO
	var turn = Vector2.ZERO
	axis_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	turn.x = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	axis_vector.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	if InputEventJoypadMotion:
		if Global.external_camera == null: pivot.set_as_toplevel(true)
		rotate_y(deg2rad(-axis_vector.x) * controller_sensitivity)
		spring_arm.rotate_x(deg2rad(-axis_vector.y) * controller_sensitivity)
		if Global.external_camera == null: pivot.set_as_toplevel(false)
		rotate_y(deg2rad(-turn.x) * controller_sensitivity)


func play_anim(anim) -> void:
	if anim == anim_player.current_animation: return
	anim_player.play(anim)

func _on_fov_updated(value):
	camera.fov = value


func _on_mouse_sens_updated(value):
	mouse_sensitivity = value
