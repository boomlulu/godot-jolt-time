extends Button

var _armed := false

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
			pressed.emit()
		else:
			_armed = true
	elif is_release:
		accept_event()
		if action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE and _armed:
			pressed.emit()
		_armed = false
