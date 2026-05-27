extends Node

const HISTORY_DURATION := 3.0
const GHOST_COUNT := 6
const GHOST_INTERVAL := HISTORY_DURATION / float(GHOST_COUNT)
const MOTION_EPSILON := 0.05

var target: Node3D = null
var is_rewinding := false
var trail: MultiMeshInstance3D = null
var trail_color := Color(1.0, 1.0, 1.0, 1.0)

var _buffer: Array = []
var _max_size := 180
var _rewind_start_size := 0
var _ghosts: Array = []
var _game_time := 0.0
var _next_spawn_time := 0.0

func _ready() -> void:
	var fps := float(Engine.physics_ticks_per_second)
	_max_size = int(HISTORY_DURATION * fps)
	if not target:
		target = get_parent()

func _physics_process(delta: float) -> void:
	if not target:
		return
	if is_rewinding:
		if not _buffer.is_empty():
			var frame: Dictionary = _buffer.pop_back()
			target.global_transform = frame.t
			if target is RigidBody3D:
				(target as RigidBody3D).linear_velocity = frame.lv
				(target as RigidBody3D).angular_velocity = frame.av
			elif target is CharacterBody3D:
				(target as CharacterBody3D).velocity = frame.lv
			if _buffer.is_empty():
				if target is RigidBody3D:
					(target as RigidBody3D).linear_velocity = Vector3.ZERO
					(target as RigidBody3D).angular_velocity = Vector3.ZERO
				elif target is CharacterBody3D:
					(target as CharacterBody3D).velocity = Vector3.ZERO
	else:
		var lv := Vector3.ZERO
		var av := Vector3.ZERO
		if target is RigidBody3D:
			lv = (target as RigidBody3D).linear_velocity
			av = (target as RigidBody3D).angular_velocity
		elif target is CharacterBody3D:
			lv = (target as CharacterBody3D).velocity
		var has_motion := lv.length() > MOTION_EPSILON or av.length() > MOTION_EPSILON
		if has_motion:
			_buffer.append({"t": target.global_transform, "lv": lv, "av": av})
			if _buffer.size() > _max_size:
				_buffer.pop_front()

		_game_time += delta
		if has_motion and _game_time >= _next_spawn_time:
			_ghosts.append({"xf": target.global_transform, "spawn": _game_time})
			_next_spawn_time = _game_time + GHOST_INTERVAL
			if _ghosts.size() > GHOST_COUNT:
				_ghosts.pop_front()

	_update_trail()

func _update_trail() -> void:
	if not trail or not trail.multimesh:
		return
	var mm := trail.multimesh
	while not _ghosts.is_empty():
		var oldest: Dictionary = _ghosts[0]
		if _game_time - float(oldest.spawn) >= HISTORY_DURATION:
			_ghosts.pop_front()
		else:
			break
	var n := _ghosts.size()
	for i in n:
		var g: Dictionary = _ghosts[i]
		mm.set_instance_transform(i, g.xf as Transform3D)
		var age: float = _game_time - float(g.spawn)
		var alpha := clampf(1.0 - age / HISTORY_DURATION, 0.0, 1.0)
		mm.set_instance_color(i, Color(trail_color.r, trail_color.g, trail_color.b, alpha))
	mm.visible_instance_count = n

func start_rewind() -> void:
	if is_rewinding:
		return
	is_rewinding = true
	_rewind_start_size = _buffer.size()
	if target is RigidBody3D:
		(target as RigidBody3D).freeze = true

func stop_rewind() -> void:
	if not is_rewinding:
		return
	is_rewinding = false
	if target is RigidBody3D:
		(target as RigidBody3D).freeze = false

func get_progress() -> float:
	if _rewind_start_size == 0:
		return 0.0
	var consumed := _rewind_start_size - _buffer.size()
	return clampf(float(consumed) / float(_rewind_start_size), 0.0, 1.0)

func is_actively_rewinding() -> bool:
	return is_rewinding and not _buffer.is_empty()
