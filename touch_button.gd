extends Button

var _armed := false

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS:
				pressed.emit()
			else:
				_armed = true
			accept_event()
		else:
			if action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE and _armed:
				pressed.emit()
			_armed = false
			accept_event()
