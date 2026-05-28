extends Button

var _armed := false
var _last_emit_frame: int = -1

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var is_press := false
	var is_release := false
	if event is InputEventScreenTouch:
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = event.pressed
		is_release = not event.pressed
	else:
		return
	if is_press:
		accept_event()
		if action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS:
			_emit_once()
		else:
			_armed = true
	elif is_release:
		accept_event()
		if action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE and _armed:
			_emit_once()
		_armed = false

func _emit_once() -> void:
	var f := Engine.get_physics_frames()
	if f == _last_emit_frame:
		return
	_last_emit_frame = f
	pressed.emit()
