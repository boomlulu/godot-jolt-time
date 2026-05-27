extends Control

const RADIUS := 80.0

var value := Vector2.ZERO
var _drag_id := -1

@onready var _thumb: Control = $Thumb

func _ready() -> void:
	_reset_thumb()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_id == -1:
				_drag_id = event.index
				_update_from_pos(event.position)
		elif event.index == _drag_id:
			_release()
	elif event is InputEventScreenDrag and event.index == _drag_id:
		_update_from_pos(event.position)

func _update_from_pos(pos: Vector2) -> void:
	var center := size * 0.5
	var offset := pos - center
	if offset.length() > RADIUS:
		offset = offset.normalized() * RADIUS
	_thumb.position = center + offset - _thumb.size * 0.5
	value = offset / RADIUS

func _release() -> void:
	_drag_id = -1
	value = Vector2.ZERO
	_reset_thumb()

func _reset_thumb() -> void:
	_thumb.position = size * 0.5 - _thumb.size * 0.5
