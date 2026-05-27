extends Camera3D

var target: Node3D = null

const DISTANCE := 12.0
const PITCH_DEG := 45.0
const YAW_SENSITIVITY := 0.4
const YAW_SMOOTH := 12.0

var target_yaw_deg := 0.0
var yaw_deg := 0.0
var frozen: bool = false

var _drag_touch_id: int = -1

# Timeline subscriber state
var current_time: float = 0.0
var record_enabled: bool = false
var _yaw_entries: Array = []

func _unhandled_input(event: InputEvent) -> void:
	if not is_current():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _drag_touch_id == -1:
			_drag_touch_id = event.index
		elif not event.pressed and event.index == _drag_touch_id:
			_drag_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _drag_touch_id:
		target_yaw_deg -= event.relative.x * YAW_SENSITIVITY
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		target_yaw_deg -= event.relative.x * YAW_SENSITIVITY

func is_dragging() -> bool:
	if not is_current():
		return false
	return _drag_touch_id != -1 or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func tick_yaw(delta: float) -> void:
	if frozen:
		return
	var smoothing := 1.0 - exp(-YAW_SMOOTH * delta)
	var yaw_rad := deg_to_rad(yaw_deg)
	var target_rad := deg_to_rad(target_yaw_deg)
	yaw_rad = lerp_angle(yaw_rad, target_rad, smoothing)
	yaw_deg = rad_to_deg(yaw_rad)

func _physics_process(_delta: float) -> void:
	if record_enabled:
		_record_yaw()

func _record_yaw() -> void:
	while not _yaw_entries.is_empty() and float(_yaw_entries.back().time) >= current_time:
		_yaw_entries.pop_back()
	_yaw_entries.append({"time": current_time, "yaw": yaw_deg, "target_yaw": target_yaw_deg})

func set_recording_at(t: float) -> void:
	current_time = t
	record_enabled = true

func disable_recording() -> void:
	record_enabled = false

func restore(t: float) -> void:
	current_time = t
	if _yaw_entries.is_empty():
		return
	var idx := _binary_search(t)
	if idx < 0:
		return
	var entry: Dictionary = _yaw_entries[idx]
	yaw_deg = float(entry.yaw)
	target_yaw_deg = float(entry.target_yaw)

func discard_future(t: float) -> void:
	while not _yaw_entries.is_empty() and float(_yaw_entries.back().time) > t:
		_yaw_entries.pop_back()

func update_visuals(_t: float, _grey: float) -> void:
	pass

func _binary_search(time: float) -> int:
	if _yaw_entries.is_empty() or float(_yaw_entries[0].time) > time:
		return -1
	var lo := 0
	var hi := _yaw_entries.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if float(_yaw_entries[mid].time) <= time:
			lo = mid
		else:
			hi = mid - 1
	return lo

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
