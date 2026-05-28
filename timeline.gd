class_name Timeline
extends Node

enum State { IDLE, ADVANCING, REWINDING, DRAGGING, LOCKED, GAME_OVER }

const REWIND_WINDOW := 3.0

@export var total_duration: float = 10.0
# 时间速率：1.0=正常，0.3=慢动作，2.0=加速，0=冻结。
# 影响 advance(delta) 的有效推进步长，不影响 step_backward（rewind 操作独立）
@export var timescale: float = 1.0

signal state_pushed(current: float, grey_water: float, max_time: float, locked: bool)
signal drag_state_changed(dragging: bool)

var current_time: float = 0.0
var max_time: float = 0.0
var grey_water: float = 0.0
var rewind_held: bool = false
var dragging: bool = false
var game_over: bool = false

var subscribers: Array = []

func subscribe(s: Object) -> void:
	if not subscribers.has(s):
		subscribers.append(s)

func unsubscribe(s: Object) -> void:
	subscribers.erase(s)

func get_game_state(input_active: bool) -> State:
	if game_over:
		return State.GAME_OVER
	if dragging:
		return State.DRAGGING
	if is_locked():
		return State.LOCKED
	if rewind_held and current_time > 0.0:
		return State.REWINDING
	if input_active:
		return State.ADVANCING
	return State.IDLE

func is_locked() -> bool:
	return grey_water > 0.0 and current_time < grey_water

func advance(delta: float) -> bool:
	if current_time >= total_duration:
		return false
	var effective := delta * timescale
	if effective <= 0.0:
		return false  # timescale 0 或负 → 时间冻结
	var new_time := minf(current_time + effective, total_duration)
	if new_time == current_time:
		return false
	if current_time < max_time:
		_dispatch_discard_future(current_time)
		max_time = current_time
	current_time = new_time
	if current_time > max_time:
		max_time = current_time
	_update_grey_water()
	_dispatch_set_recording_at(current_time)
	return true

func step_backward(delta: float) -> void:
	var new_time := maxf(0.0, current_time - delta)
	if new_time == current_time:
		return
	current_time = new_time
	_dispatch_restore()

func seek(t: float) -> void:
	var clamped := clampf(t, 0.0, max_time)
	if clamped == current_time:
		return
	current_time = clamped
	_dispatch_restore()

func set_dragging(d: bool) -> void:
	if dragging == d:
		return
	dragging = d
	drag_state_changed.emit(d)
	if d:
		_dispatch_restore()

func mark_game_over() -> void:
	game_over = true

func push_visuals() -> void:
	_update_grey_water()
	var locked := is_locked()
	state_pushed.emit(current_time, grey_water, max_time, locked)
	for s in subscribers:
		if s.has_method("update_visuals"):
			s.update_visuals(current_time, grey_water)

func disable_recording() -> void:
	for s in subscribers:
		if s.has_method("disable_recording"):
			s.disable_recording()

func _update_grey_water() -> void:
	grey_water = maxf(grey_water, max_time - REWIND_WINDOW)

func _dispatch_restore() -> void:
	for s in subscribers:
		if s.has_method("restore"):
			s.restore(current_time)

func _dispatch_discard_future(t: float) -> void:
	for s in subscribers:
		if s.has_method("discard_future"):
			s.discard_future(t)

func _dispatch_set_recording_at(t: float) -> void:
	for s in subscribers:
		if s.has_method("set_recording_at"):
			s.set_recording_at(t)
