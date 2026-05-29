extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 6.0
const PUSH_FORCE := 15.0
const ACCEL := 28.0
const DECEL := 32.0

var joystick: Node = null
var camera: Camera3D = null
var time_controlled: bool = false
var _jump_queued := false

func _should_accept_input() -> bool:
	return not time_controlled

func queue_jump() -> void:
	if not is_on_floor():
		return
	_jump_queued = true

func has_pending_jump() -> bool:
	return _jump_queued

func has_activity() -> bool:
	if velocity.length() > Rewindable.MOTION_EPSILON:
		return true
	if not is_on_floor():
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not _should_accept_input():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		queue_jump()

func _physics_process(delta: float) -> void:
	if not _should_accept_input():
		return

	if not is_on_floor():
		var g: Vector3 = GravityManager.resolve_gravity(global_position)
		velocity += g * delta

	if _jump_queued and is_on_floor():
		velocity.y = JUMP_VELOCITY
	_jump_queued = false

	var input := Vector2.ZERO
	if joystick:
		input = joystick.value

	var kb := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		kb.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		kb.y += 1.0
	if Input.is_key_pressed(KEY_A):
		kb.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		kb.x += 1.0
	if kb != Vector2.ZERO:
		input = kb.normalized()

	var dir := Vector3.ZERO
	if camera:
		var basis := camera.global_basis
		var cam_forward := Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		var cam_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
		dir = cam_right * input.x + cam_forward * input.y
	else:
		dir = Vector3(input.x, 0.0, input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	var target_v := dir * SPEED
	var current_v := Vector3(velocity.x, 0.0, velocity.z)
	var rate := ACCEL if input != Vector2.ZERO else DECEL
	current_v = current_v.move_toward(target_v, rate * delta)
	velocity.x = current_v.x
	velocity.z = current_v.z

	move_and_slide()

	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var other := c.get_collider()
		if other is RigidBody3D:
			(other as RigidBody3D).apply_central_force(-c.get_normal() * PUSH_FORCE)

	if camera and "yaw_deg" in camera:
		rotation.y = deg_to_rad(camera.yaw_deg)
