class_name GhostTrail
extends Node

const HISTORY_DURATION := 3.0
const GHOST_COUNT := 6
const GHOST_INTERVAL := HISTORY_DURATION / float(GHOST_COUNT)

var target: Node3D = null
var trail_renderer: MultiMeshInstance3D = null
var trail_color: Color = Color.WHITE
var record_enabled: bool = false
var current_time: float = 0.0

var _ghosts: Array = []
var _next_spawn_time: float = 0.0

func _physics_process(_delta: float) -> void:
	if not record_enabled or not target:
		return
	if current_time < _next_spawn_time:
		return
	if not Rewindable.has_motion(target):
		return
	_ghosts.append({"spawn": current_time, "xf": target.global_transform})
	_next_spawn_time = current_time + GHOST_INTERVAL

func set_recording_at(t: float) -> void:
	current_time = t
	record_enabled = true

func disable_recording() -> void:
	record_enabled = false

func restore(t: float) -> void:
	current_time = t

func discard_future(t: float) -> void:
	while not _ghosts.is_empty() and float(_ghosts.back().spawn) > t:
		_ghosts.pop_back()
	if _next_spawn_time > t + GHOST_INTERVAL:
		_next_spawn_time = t + GHOST_INTERVAL

func update_visuals(t: float, grey: float) -> void:
	current_time = t
	if not trail_renderer or not trail_renderer.multimesh:
		return
	var mm := trail_renderer.multimesh
	var visible := 0
	for g in _ghosts:
		if visible >= GHOST_COUNT:
			break
		if float(g.spawn) < grey:
			continue
		var age: float = current_time - float(g.spawn)
		if age < 0.0 or age >= HISTORY_DURATION:
			continue
		var alpha := clampf(1.0 - age / HISTORY_DURATION, 0.0, 1.0)
		mm.set_instance_transform(visible, g.xf as Transform3D)
		mm.set_instance_color(visible, Color(trail_color.r, trail_color.g, trail_color.b, alpha))
		visible += 1
	mm.visible_instance_count = visible
