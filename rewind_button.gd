extends Button

signal hold_started
signal hold_ended

var _holding := false

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var is_press := false
	var is_release := false
	if event is InputEventScreenTouch:
		if event.pressed:
			is_press = true
		else:
			is_release = true
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_press = true
		else:
			is_release = true
		accept_event()

	if is_press and not _holding:
		_holding = true
		hold_started.emit()
	elif is_release and _holding:
		_holding = false
		hold_ended.emit()
