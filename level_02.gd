extends BaseLevel

@onready var _actor_timeline: Timeline = $ActorTimeline
@onready var _box_timeline: Timeline = $BoxTimeline
@onready var _pushbox: RigidBody3D = $PushBox
@onready var _camera: Camera3D = $Camera3D
@onready var _observer_camera: Camera3D = $ObserverCamera
@onready var _hud_joystick: Control = $HUD/Joystick
@onready var _hud_jump: Button = $HUD/JumpButton
@onready var _hud_actor_rewind: Button = $HUD/ActorRewindButton
@onready var _hud_box_rewind: Button = $HUD/BoxRewindButton
@onready var _hud_eye: Button = $HUD/EyeButton
@onready var _hud_timer: Label = $HUD/TimerLabel
@onready var _hud_tips: Label = $HUD/TipsLabel
@onready var _hud_dialog: AcceptDialog = $HUD/GameOverDialog
@onready var _hud_actor_timeline: Control = $HUD/ActorTimelineBar
@onready var _hud_box_timeline: Control = $HUD/BoxTimelineBar
@onready var _hud_key_status: Label = $HUD/KeyStatusLabel
@onready var _hud_door_locked: Label = $HUD/DoorLockedLabel
@onready var _actor_recorder: Recorder = $Actor/Recorder
@onready var _actor_ghost_trail: GhostTrail = $Actor/GhostTrail
@onready var _actor_trail: MultiMeshInstance3D = $ActorTrail
@onready var _box_recorder: Recorder = $PushBox/Recorder
@onready var _box_ghost_trail: GhostTrail = $PushBox/GhostTrail
@onready var _box_trail: MultiMeshInstance3D = $BoxTrail
@onready var _key: Area3D = $Key
@onready var _key_mesh: MeshInstance3D = $Key/MeshInstance3D

var _actor_rewind_held: bool = false
var _box_rewind_held: bool = false
var _actor_waiting_for_input: bool = true
var _box_waiting_for_input: bool = true
var _has_key: bool = false
var _key_base_y: float = -5.0
var _key_time: float = 0.0
var _door_locked_tween: Tween = null

func _ready() -> void:
	super._ready()
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_actor_recorder.target = _actor
	_actor_ghost_trail.target = _actor
	_actor_ghost_trail.trail_renderer = _actor_trail
	_actor_ghost_trail.trail_color = Color(0.4, 0.7, 1.0, 1.0)
	_box_recorder.target = _pushbox
	_box_ghost_trail.target = _pushbox
	_box_ghost_trail.trail_renderer = _box_trail
	_box_ghost_trail.trail_color = Color(1.0, 0.7, 0.4, 1.0)
	_box_ghost_trail.enabled = GameSettings.ITEM_GHOST_TRAIL_ENABLED
	_camera.target = _actor
	_observer_camera.target = _actor
	_actor_timeline.subscribe(_actor_recorder)
	_actor_timeline.subscribe(_actor_ghost_trail)
	_actor_timeline.subscribe(_camera)
	_box_timeline.subscribe(_box_recorder)
	_box_timeline.subscribe(_box_ghost_trail)
	_hud_jump.pressed.connect(_actor.queue_jump)
	_hud_actor_rewind.hold_started.connect(_on_actor_rewind_started)
	_hud_actor_rewind.hold_ended.connect(_on_actor_rewind_ended)
	_hud_box_rewind.hold_started.connect(_on_box_rewind_started)
	_hud_box_rewind.hold_ended.connect(_on_box_rewind_ended)
	_hud_eye.hold_started.connect(_on_eye_started)
	_hud_eye.hold_ended.connect(_on_eye_ended)
	_hud_dialog.confirmed.connect(_on_restart)
	_key.body_entered.connect(_on_key_entered)
	_actor_timeline.drag_state_changed.connect(_on_actor_drag_state_changed)
	_box_timeline.drag_state_changed.connect(_on_box_drag_state_changed)
	_hud_actor_timeline.bind_timeline(_actor_timeline)
	_hud_box_timeline.bind_timeline(_box_timeline)
	_hud_tips.visible = false
	_hud_key_status.visible = false
	_hud_door_locked.visible = false
	_key_base_y = _key.position.y
	_actor_timeline.push_visuals()
	_box_timeline.push_visuals()

func _physics_process(delta: float) -> void:
	_camera.tick_yaw(delta)
	_actor_timeline.rewind_held = _actor_rewind_held
	_box_timeline.rewind_held = _box_rewind_held
	_tick_actor_timeline(delta)
	_tick_box_timeline(delta)

func _tick_actor_timeline(delta: float) -> void:
	var input_active := _is_actor_inputting()
	var state := _actor_timeline.get_game_state(input_active)
	match state:
		Timeline.State.GAME_OVER, Timeline.State.DRAGGING, Timeline.State.LOCKED:
			_apply_actor_freeze(true)
			_actor_timeline.disable_recording()
		Timeline.State.REWINDING:
			_apply_actor_freeze(true)
			_actor_timeline.disable_recording()
			_actor_timeline.step_backward(delta)
		Timeline.State.ADVANCING:
			_actor_waiting_for_input = false
			_apply_actor_freeze(false)
			_actor_timeline.advance(delta)
			if _actor_timeline.current_time >= _actor_timeline.total_duration:
				_trigger_game_over()
		Timeline.State.IDLE:
			if _actor_waiting_for_input:
				_apply_actor_freeze(true)
			else:
				_apply_actor_freeze(false)
			_actor_timeline.disable_recording()

func _tick_box_timeline(delta: float) -> void:
	var input_active := _is_box_inputting()
	var state := _box_timeline.get_game_state(input_active)
	match state:
		Timeline.State.GAME_OVER, Timeline.State.DRAGGING, Timeline.State.LOCKED:
			_apply_box_freeze(true)
			_box_timeline.disable_recording()
		Timeline.State.REWINDING:
			_apply_box_freeze(true)
			_box_timeline.disable_recording()
			_box_timeline.step_backward(delta)
		Timeline.State.ADVANCING:
			_box_waiting_for_input = false
			_apply_box_freeze(false)
			_box_timeline.advance(delta)
		Timeline.State.IDLE:
			if _box_waiting_for_input:
				_apply_box_freeze(true)
			else:
				_apply_box_freeze(false)
			_box_timeline.disable_recording()

func _process(delta: float) -> void:
	_actor_timeline.push_visuals()
	_box_timeline.push_visuals()
	var locked := _actor_timeline.is_locked() or _box_timeline.is_locked()
	_hud_tips.visible = locked and not _actor_timeline.dragging and not _box_timeline.dragging
	if locked:
		_hud_timer.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		_hud_timer.add_theme_color_override("font_color", Color(0.2, 1, 0.4, 1))
	# Animate key (rotation + float)
	if is_instance_valid(_key) and not _has_key:
		_key_time += delta
		_key.rotate_y(delta * 2.0)
		_key.position.y = _key_base_y + sin(_key_time * 3.0) * 0.2

func _apply_actor_freeze(freeze: bool) -> void:
	_actor.time_controlled = freeze
	_camera.frozen = freeze

func _apply_box_freeze(freeze: bool) -> void:
	_pushbox.freeze = freeze

func _is_actor_inputting() -> bool:
	if _has_direct_input():
		return true
	if _actor_waiting_for_input:
		return false
	if _actor.has_activity():
		return true
	return false

func _is_box_inputting() -> bool:
	if _box_waiting_for_input:
		return false
	if _pushbox.has_activity():
		return true
	return false

func _has_direct_input() -> bool:
	if _hud_joystick.value.length() > 0.0:
		return true
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D):
		return true
	if Input.is_key_pressed(KEY_SPACE):
		return true
	if _camera.has_method("is_dragging") and _camera.is_dragging():
		return true
	if _actor.has_method("has_pending_jump") and _actor.has_pending_jump():
		return true
	return false

func _on_actor_drag_state_changed(dragging: bool) -> void:
	if not dragging:
		_actor_waiting_for_input = true

func _on_box_drag_state_changed(dragging: bool) -> void:
	if not dragging:
		_box_waiting_for_input = true

func _trigger_game_over() -> void:
	_actor_timeline.mark_game_over()
	_box_timeline.mark_game_over()
	get_tree().paused = true
	_hud_dialog.popup_centered()

func _can_pass_door() -> bool:
	return _has_key

func _on_door_blocked() -> void:
	_show_door_locked()

func _on_door_passed() -> void:
	get_tree().change_scene_to_file("res://level_03.tscn")

func _on_key_entered(body: Node3D) -> void:
	if body != _actor:
		return
	if _has_key:
		return
	_has_key = true
	_hud_key_status.visible = true
	_hud_key_status.modulate = Color(1, 1, 1, 1)
	if is_instance_valid(_key):
		_key.queue_free()

func _show_door_locked() -> void:
	if _door_locked_tween and _door_locked_tween.is_valid():
		_door_locked_tween.kill()
	_hud_door_locked.visible = true
	_hud_door_locked.modulate = Color(1, 1, 1, 1)
	_door_locked_tween = create_tween()
	_door_locked_tween.tween_interval(1.0)
	_door_locked_tween.tween_property(_hud_door_locked, "modulate:a", 0.0, 0.5)
	_door_locked_tween.tween_callback(func(): _hud_door_locked.visible = false)

func _on_actor_rewind_started() -> void:
	_actor_rewind_held = true

func _on_actor_rewind_ended() -> void:
	_actor_rewind_held = false

func _on_box_rewind_started() -> void:
	_box_rewind_held = true

func _on_box_rewind_ended() -> void:
	_box_rewind_held = false

func _on_eye_started() -> void:
	_observer_camera.sync_from(_camera.yaw_deg, 45.0)
	_observer_camera.current = true

func _on_eye_ended() -> void:
	_camera.current = true

func _dump_state() -> Dictionary:
	var actor_state := _actor_timeline.get_game_state(_is_actor_inputting())
	var box_state := _box_timeline.get_game_state(_is_box_inputting())
	return {
		"actor_timeline": {
			"state": _state_name(actor_state),
			"current": _actor_timeline.current_time,
			"total": _actor_timeline.total_duration,
			"max": _actor_timeline.max_time,
			"grey": _actor_timeline.grey_water,
			"locked": _actor_timeline.is_locked(),
			"dragging": _actor_timeline.dragging,
			"rewind": _actor_timeline.rewind_held,
		},
		"box_timeline": {
			"state": _state_name(box_state),
			"current": _box_timeline.current_time,
			"total": _box_timeline.total_duration,
			"max": _box_timeline.max_time,
			"grey": _box_timeline.grey_water,
			"locked": _box_timeline.is_locked(),
			"dragging": _box_timeline.dragging,
			"rewind": _box_timeline.rewind_held,
		},
		"actor": {
			"pos": _actor.global_position,
			"vel": _actor.velocity,
			"on_floor": _actor.is_on_floor(),
			"time_controlled": _actor.time_controlled,
		},
		"pushbox": {
			"pos": _pushbox.global_position,
			"vel": _pushbox.linear_velocity,
			"freeze": _pushbox.freeze,
		},
		"camera": {
			"yaw": _camera.yaw_deg,
			"target_yaw": _camera.target_yaw_deg,
			"frozen": _camera.frozen,
			"is_current": _camera.current,
		},
		"observer": {
			"yaw": _observer_camera.yaw_deg,
			"pitch": _observer_camera.pitch_deg,
			"is_current": _observer_camera.current,
		},
		"flags": {
			"actor_rewind": _actor_rewind_held,
			"box_rewind": _box_rewind_held,
			"actor_waiting": _actor_waiting_for_input,
			"box_waiting": _box_waiting_for_input,
			"has_key": _has_key,
			"door_triggered": _door_triggered,
		},
	}
