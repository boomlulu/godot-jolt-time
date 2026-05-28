extends Node3D

const LEVELS := [
	{"name": "新手引导", "scene": "res://world.tscn"},
	{"name": "第二关·钥匙", "scene": "res://level_02.tscn"},
	{"name": "第三关", "scene": "res://level_03.tscn"},
]

const _TOUCH_BUTTON_SCRIPT := preload("res://touch_button.gd")
const GameSettings := preload("res://game_settings.gd")

@onready var _timeline: Timeline = $Timeline
@onready var _actor: CharacterBody3D = $Actor
@onready var _pushbox: RigidBody3D = $PushBox
@onready var _camera: Camera3D = $Camera3D
@onready var _observer_camera: Camera3D = $ObserverCamera
@onready var _hud_joystick: Control = $HUD/Joystick
@onready var _hud_jump: Button = $HUD/JumpButton
@onready var _hud_exit: Button = $HUD/ExitButton
@onready var _hud_rewind: Button = $HUD/RewindButton
@onready var _hud_eye: Button = $HUD/EyeButton
@onready var _hud_timer: Label = $HUD/TimerLabel
@onready var _hud_tips: Label = $HUD/TipsLabel
@onready var _hud_dialog: AcceptDialog = $HUD/GameOverDialog
@onready var _hud_timeline: Control = $HUD/TimelineBar
@onready var _hud_gm_button: Button = $HUD/GMButton
@onready var _hud_gm_panel: Control = $HUD/GMPanel
@onready var _hud_gm_close: Button = $HUD/GMPanel/CenterBox/VBox/CloseButton
@onready var _hud_level_buttons: VBoxContainer = $HUD/GMPanel/CenterBox/VBox/LevelButtons
@onready var _actor_recorder: Recorder = $Actor/Recorder
@onready var _box_recorder: Recorder = $PushBox/Recorder
@onready var _actor_ghost_trail: GhostTrail = $Actor/GhostTrail
@onready var _box_ghost_trail: GhostTrail = $PushBox/GhostTrail
@onready var _actor_trail: MultiMeshInstance3D = $ActorTrail
@onready var _box_trail: MultiMeshInstance3D = $BoxTrail
@onready var _door: Area3D = $Door

var _rewind_held: bool = false
var _door_triggered: bool = false
var _waiting_for_input: bool = true

func _ready() -> void:
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_actor_recorder.target = _actor
	_box_recorder.target = _pushbox
	_actor_ghost_trail.target = _actor
	_actor_ghost_trail.trail_renderer = _actor_trail
	_actor_ghost_trail.trail_color = Color(0.4, 0.7, 1.0, 1.0)
	_box_ghost_trail.target = _pushbox
	_box_ghost_trail.trail_renderer = _box_trail
	_box_ghost_trail.trail_color = Color(1.0, 0.7, 0.4, 1.0)
	_box_ghost_trail.enabled = GameSettings.ITEM_GHOST_TRAIL_ENABLED
	_camera.target = _actor
	_observer_camera.target = _actor
	_timeline.subscribe(_actor_recorder)
	_timeline.subscribe(_box_recorder)
	_timeline.subscribe(_actor_ghost_trail)
	_timeline.subscribe(_box_ghost_trail)
	_timeline.subscribe(_camera)
	_hud_jump.pressed.connect(_actor.queue_jump)
	_hud_exit.pressed.connect(_on_exit_pressed)
	_hud_rewind.hold_started.connect(_on_rewind_started)
	_hud_rewind.hold_ended.connect(_on_rewind_ended)
	_hud_eye.hold_started.connect(_on_eye_started)
	_hud_eye.hold_ended.connect(_on_eye_ended)
	_hud_dialog.confirmed.connect(_on_restart)
	_hud_gm_button.pressed.connect(_on_gm_open)
	_hud_gm_close.pressed.connect(_on_gm_close)
	_door.body_entered.connect(_on_door_entered)
	_timeline.drag_state_changed.connect(_on_drag_state_changed)
	_hud_timeline.bind_timeline(_timeline)
	_hud_tips.visible = false
	_populate_levels()
	_update_timer_label()
	_timeline.push_visuals()

func _physics_process(delta: float) -> void:
	_camera.tick_yaw(delta)
	_timeline.rewind_held = _rewind_held
	var input_active := _is_player_inputting()
	var state := _timeline.get_game_state(input_active)
	match state:
		Timeline.State.GAME_OVER, Timeline.State.DRAGGING, Timeline.State.LOCKED:
			_apply_freeze(true)
			_timeline.disable_recording()
		Timeline.State.REWINDING:
			_apply_freeze(true)
			_timeline.disable_recording()
			_timeline.step_backward(delta)
		Timeline.State.ADVANCING:
			_waiting_for_input = false
			_apply_freeze(false)
			_timeline.advance(delta)
			if _timeline.current_time >= _timeline.total_duration:
				_trigger_game_over()
		Timeline.State.IDLE:
			if _waiting_for_input:
				_apply_freeze(true)
			else:
				_apply_freeze(false)
			_timeline.disable_recording()

func _process(_delta: float) -> void:
	_timeline.push_visuals()
	_update_timer_label()
	var locked := _timeline.is_locked()
	_hud_tips.visible = locked and not _timeline.dragging
	if locked:
		_hud_timer.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		_hud_timer.add_theme_color_override("font_color", Color(0.2, 1, 0.4, 1))

func _apply_freeze(freeze: bool) -> void:
	_actor.time_controlled = freeze
	_pushbox.freeze = freeze
	_camera.frozen = freeze

func _is_player_inputting() -> bool:
	if _has_direct_input():
		return true
	if _waiting_for_input:
		return false
	if not _actor.is_on_floor():
		return true
	if Rewindable.has_motion(_actor):
		return true
	if Rewindable.has_motion(_pushbox):
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

func _on_drag_state_changed(dragging: bool) -> void:
	if not dragging:
		_waiting_for_input = true

func _update_timer_label() -> void:
	var remaining := maxf(0.0, _timeline.total_duration - _timeline.current_time)
	var total_ms := int(remaining * 1000.0)
	var m := total_ms / 60000
	var s := (total_ms / 1000) % 60
	var ms := total_ms % 1000
	_hud_timer.text = "%02d:%02d:%03d" % [m, s, ms]

func _trigger_game_over() -> void:
	_timeline.mark_game_over()
	get_tree().paused = true
	_hud_dialog.popup_centered()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	get_tree().quit()
	OS.kill(OS.get_process_id())

func _on_door_entered(body: Node3D) -> void:
	if _door_triggered:
		return
	if body == _actor:
		_door_triggered = true
		get_tree().change_scene_to_file("res://level_02.tscn")

func _on_rewind_started() -> void:
	_rewind_held = true

func _on_rewind_ended() -> void:
	_rewind_held = false

func _on_eye_started() -> void:
	_observer_camera.sync_from(_camera.yaw_deg, 45.0)
	_observer_camera.current = true

func _on_eye_ended() -> void:
	_camera.current = true

func _populate_levels() -> void:
	for level in LEVELS:
		var btn := Button.new()
		btn.set_script(_TOUCH_BUTTON_SCRIPT)
		btn.text = level.name
		btn.custom_minimum_size = Vector2(0, 60)
		btn.pressed.connect(_on_level_pressed.bind(level.scene))
		_hud_level_buttons.add_child(btn)

func _on_gm_open() -> void:
	_hud_gm_panel.visible = true

func _on_gm_close() -> void:
	_hud_gm_panel.visible = false

func _on_level_pressed(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
