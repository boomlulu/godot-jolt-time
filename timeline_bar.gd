extends Control

const COLOR_GREEN := Color(0.2, 0.85, 0.35, 1.0)
const COLOR_GREY := Color(0.35, 0.35, 0.35, 1.0)
const COLOR_FUTURE := Color(0.12, 0.12, 0.16, 0.5)
const COLOR_BORDER := Color(0.1, 0.1, 0.1, 0.8)
const COLOR_CURSOR := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_CURSOR_LOCKED := Color(1.0, 0.3, 0.3, 1.0)

var _timeline: Timeline = null
var _drag_id: int = -1

func bind_timeline(t: Timeline) -> void:
	if _timeline:
		_timeline.state_pushed.disconnect(_on_state_pushed)
	_timeline = t
	if _timeline:
		_timeline.state_pushed.connect(_on_state_pushed)
	queue_redraw()

func _on_state_pushed(_current, _grey, _max_t, _locked) -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not _timeline:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_id == -1:
				_drag_id = event.index
				_emit_drag(event.position.x)
				_timeline.set_dragging(true)
		elif event.index == _drag_id:
			_drag_id = -1
			_timeline.set_dragging(false)
	elif event is InputEventScreenDrag and event.index == _drag_id:
		_emit_drag(event.position.x)

func _emit_drag(x: float) -> void:
	if not _timeline or _timeline.total_duration <= 0.0 or size.x <= 0.0:
		return
	var frac := clampf(x / size.x, 0.0, 1.0)
	var t := frac * _timeline.total_duration
	_timeline.seek(t)

func _draw() -> void:
	if not _timeline:
		return
	var w := size.x
	var h := size.y
	if _timeline.total_duration <= 0.0 or w <= 0.0 or h <= 0.0:
		return
	var future_frac := clampf(_timeline.max_time / _timeline.total_duration, 0.0, 1.0)
	var grey_frac := clampf(_timeline.grey_water / _timeline.total_duration, 0.0, 1.0)
	if grey_frac > 0.0:
		draw_rect(Rect2(0.0, 0.0, w * grey_frac, h), COLOR_GREY, true)
	if future_frac > grey_frac:
		draw_rect(Rect2(w * grey_frac, 0.0, w * (future_frac - grey_frac), h), COLOR_GREEN, true)
	if future_frac < 1.0:
		draw_rect(Rect2(w * future_frac, 0.0, w * (1.0 - future_frac), h), COLOR_FUTURE, true)
	var cursor_frac := clampf(_timeline.current_time / _timeline.total_duration, 0.0, 1.0)
	var cursor_x := w * cursor_frac
	var cursor_color := COLOR_CURSOR_LOCKED if _timeline.is_locked() else COLOR_CURSOR
	draw_line(Vector2(cursor_x, 0.0), Vector2(cursor_x, h), cursor_color, 3.0)
	draw_rect(Rect2(0.0, 0.0, w, h), COLOR_BORDER, false, 1.0)
