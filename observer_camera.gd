extends Camera3D

const DISTANCE := 12.0
const YAW_SENSITIVITY := 0.4
const PITCH_SENSITIVITY := 0.3
const PITCH_MIN := 10.0
const PITCH_MAX := 80.0

var target: Node3D = null
var yaw_deg := 0.0
var pitch_deg := 45.0

func sync_from(yaw_init: float, pitch_init: float = 45.0) -> void:
	yaw_deg = yaw_init
	pitch_deg = pitch_init

func _unhandled_input(event: InputEvent) -> void:
	if not is_current():
		return
	if event is InputEventScreenDrag:
		_apply_drag(event.relative.x, event.relative.y)
	elif event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		_apply_drag(event.relative.x, event.relative.y)

func _apply_drag(dx: float, dy: float) -> void:
	yaw_deg -= dx * YAW_SENSITIVITY
	pitch_deg = clampf(pitch_deg + dy * PITCH_SENSITIVITY, PITCH_MIN, PITCH_MAX)

func _process(_delta: float) -> void:
	if not target:
		return
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * DISTANCE
	global_position = target.global_position + offset
	look_at(target.global_position, Vector3.UP)
