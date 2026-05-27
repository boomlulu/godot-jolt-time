class_name Recorder
extends Node

const MOTION_EPSILON := 0.05

var target: Node3D = null
var record_enabled: bool = false
var current_time: float = 0.0

var _entries: Array = []

func _physics_process(_delta: float) -> void:
	if record_enabled and target and Rewindable.has_motion(target, MOTION_EPSILON):
		_record_now()

func _record_now() -> void:
	while not _entries.is_empty():
		var last: StateFrame = _entries.back()
		if last.time >= current_time:
			_entries.pop_back()
		else:
			break
	_entries.append(Rewindable.capture(target, current_time))

func set_recording_at(t: float) -> void:
	current_time = t
	record_enabled = true

func disable_recording() -> void:
	record_enabled = false

func restore(t: float) -> void:
	current_time = t
	if not target or _entries.is_empty():
		return
	var idx := _binary_search(t)
	if idx < 0:
		return
	Rewindable.apply(target, _entries[idx])

func discard_future(t: float) -> void:
	while not _entries.is_empty():
		var last: StateFrame = _entries.back()
		if last.time > t:
			_entries.pop_back()
		else:
			break

func update_visuals(_t: float, _grey: float) -> void:
	pass

func _binary_search(time: float) -> int:
	if _entries.is_empty():
		return -1
	var first: StateFrame = _entries[0]
	if first.time > time:
		return -1
	var lo := 0
	var hi := _entries.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		var entry: StateFrame = _entries[mid]
		if entry.time <= time:
			lo = mid
		else:
			hi = mid - 1
	return lo
