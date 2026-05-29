extends Control

const R_INNER := 20.0
const R_MIDDLE := 55.0
const R_OUTER := 80.0

var value := Vector2.ZERO
var _drag_id := -1
var _active := false
var _center := Vector2.ZERO
var _thumb_pos := Vector2.ZERO

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_id == -1 and _is_in_trigger_zone(event.position):
				_begin(event.index, event.position)
				get_viewport().set_input_as_handled()
		elif event.index == _drag_id:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _drag_id:
		_update(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _drag_id == -1 and _is_in_trigger_zone(event.position):
				_begin(-2, event.position)
				get_viewport().set_input_as_handled()
		elif _drag_id == -2:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _active and _drag_id == -2:
		_update(event.position)
		get_viewport().set_input_as_handled()

func _is_in_trigger_zone(pos: Vector2) -> bool:
	return pos.x < get_viewport().get_visible_rect().size.x / 3.0

func _begin(idx: int, pos: Vector2) -> void:
	_drag_id = idx
	_active = true
	_center = pos
	_thumb_pos = pos
	value = Vector2.ZERO
	queue_redraw()

func _update(pos: Vector2) -> void:
	var offset := pos - _center
	var distance := offset.length()
	if distance < R_INNER:
		value = Vector2.ZERO
	elif distance < R_MIDDLE:
		value = offset.normalized() * 0.4
	else:
		value = offset.normalized() * 1.0
	var clamped := minf(distance, R_OUTER)
	if distance > 0.0:
		_thumb_pos = _center + offset.normalized() * clamped
	else:
		_thumb_pos = _center
	queue_redraw()

func _release() -> void:
	_drag_id = -1
	_active = false
	value = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	draw_arc(_center, R_OUTER, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 2.0)
	draw_arc(_center, R_MIDDLE, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 2.0)
	draw_arc(_center, R_INNER, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
	draw_circle(_thumb_pos, 12.0, Color(0.9, 0.9, 0.9, 0.85))
