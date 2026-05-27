extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 6.0
const GRAVITY := 18.0
const PUSH_FORCE := 15.0
const ROT_SMOOTH := 12.0
const ACCEL := 28.0
const DECEL := 32.0
const DEADZONE := 0.15

var joystick: Node = null
var camera: Camera3D = null
var recorder: Node = null
var _jump_queued := false

func queue_jump() -> void:
	_jump_queued = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		queue_jump()

func _physics_process(delta: float) -> void:
	if recorder and recorder.is_rewinding:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

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

	var mag := input.length()
	if mag < DEADZONE:
		input = Vector2.ZERO
	else:
		var rescaled := (mag - DEADZONE) / (1.0 - DEADZONE)
		input = input.normalized() * minf(rescaled, 1.0)

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
		var target_yaw := deg_to_rad(camera.yaw_deg)
		var t := 1.0 - exp(-ROT_SMOOTH * delta)
		rotation.y = lerp_angle(rotation.y, target_yaw, t)
