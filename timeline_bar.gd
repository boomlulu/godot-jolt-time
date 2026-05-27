extends Control

const COLOR_GREEN := Color(0.2, 0.85, 0.35, 1.0)
const COLOR_GREY := Color(0.35, 0.35, 0.35, 1.0)
const COLOR_BORDER := Color(0.1, 0.1, 0.1, 0.8)
const COLOR_CURSOR := Color(1.0, 1.0, 1.0, 1.0)

var total_duration: float = 30.0
var rewind_window: float = 3.0
var elapsed: float = 0.0

var _grey_end_frac: float = 0.0

func set_state(new_elapsed: float, is_rewinding: bool) -> void:
	elapsed = clampf(new_elapsed, 0.0, total_duration)
	if not is_rewinding and total_duration > 0.0:
		var natural := clampf((elapsed - rewind_window) / total_duration, 0.0, 1.0)
		_grey_end_frac = maxf(_grey_end_frac, natural)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if total_duration <= 0.0 or w <= 0.0 or h <= 0.0:
		return

	if _grey_end_frac > 0.0:
		draw_rect(Rect2(0.0, 0.0, w * _grey_end_frac, h), COLOR_GREY, true)

	draw_rect(Rect2(w * _grey_end_frac, 0.0, w * (1.0 - _grey_end_frac), h), COLOR_GREEN, true)

	var cursor_frac := clampf(elapsed / total_duration, 0.0, 1.0)
	var cursor_x := w * cursor_frac
	draw_line(Vector2(cursor_x, 0.0), Vector2(cursor_x, h), COLOR_CURSOR, 3.0)

	draw_rect(Rect2(0.0, 0.0, w, h), COLOR_BORDER, false, 1.0)
