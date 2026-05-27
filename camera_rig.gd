extends Camera3D

var target: Node3D = null

const DISTANCE := 12.0
const PITCH_DEG := 45.0
const YAW_SENSITIVITY := 0.4

var yaw_deg := 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		yaw_deg -= event.relative.x * YAW_SENSITIVITY
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw_deg -= event.relative.x * YAW_SENSITIVITY

func _process(_delta: float) -> void:
	if not target:
		return
	var pitch := deg_to_rad(PITCH_DEG)
	var yaw := deg_to_rad(yaw_deg)
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * DISTANCE
	global_position = target.global_position + offset
	look_at(target.global_position, Vector3.UP)
