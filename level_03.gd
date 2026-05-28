extends Node3D

const _TOUCH_BUTTON_SCRIPT := preload("res://touch_button.gd")

const LEVELS := [
	{"name": "新手引导", "scene": "res://world.tscn"},
	{"name": "第二关·钥匙", "scene": "res://level_02.tscn"},
	{"name": "第三关", "scene": "res://level_03.tscn"},
]

const TIMER_START := 15.0

@onready var _item_timeline: Timeline = $ItemTimeline
@onready var _actor: CharacterBody3D = $Actor
@onready var _camera: Camera3D = $Camera3D
@onready var _hud_joystick: Control = $HUD/Joystick
@onready var _hud_exit: Button = $HUD/ExitButton
@onready var _hud_rewind: Button = $HUD/RewindButton
@onready var _hud_timer: Label = $HUD/TimerLabel
@onready var _hud_tips: Label = $HUD/TipsLabel
@onready var _hud_dialog: AcceptDialog = $HUD/GameOverDialog
@onready var _hud_win: AcceptDialog = $HUD/WinDialog
@onready var _hud_timeline: Control = $HUD/TimelineBar
@onready var _hud_gm_button: Button = $HUD/GMButton
@onready var _hud_gm_panel: Control = $HUD/GMPanel
@onready var _hud_gm_close: Button = $HUD/GMPanel/CenterBox/VBox/CloseButton
@onready var _hud_level_buttons: VBoxContainer = $HUD/GMPanel/CenterBox/VBox/LevelButtons
@onready var _door: Area3D = $Door

@onready var _item1: RigidBody3D = $Item1
@onready var _item2: RigidBody3D = $Item2
@onready var _item3: RigidBody3D = $Item3
@onready var _item1_recorder: Recorder = $Item1/Recorder
@onready var _item2_recorder: Recorder = $Item2/Recorder
@onready var _item3_recorder: Recorder = $Item3/Recorder
@onready var _item1_ghost_trail: GhostTrail = $Item1/GhostTrail
@onready var _item2_ghost_trail: GhostTrail = $Item2/GhostTrail
@onready var _item3_ghost_trail: GhostTrail = $Item3/GhostTrail
@onready var _item1_trail: MultiMeshInstance3D = $ItemTrail1
@onready var _item2_trail: MultiMeshInstance3D = $ItemTrail2
@onready var _item3_trail: MultiMeshInstance3D = $ItemTrail3
@onready var _item1_hit: Area3D = $Item1/HitBox
@onready var _item2_hit: Area3D = $Item2/HitBox
@onready var _item3_hit: Area3D = $Item3/HitBox

var _rewind_held: bool = false
var _door_triggered: bool = false
var _item_waiting_for_input: bool = true
var _countdown: float = TIMER_START
var _game_over: bool = false
var _won: bool = false

func _ready() -> void:
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_camera.target = _actor

	# items setup
	var trail_color := Color(1.0, 0.7, 0.3, 1.0)
	for entry in [
		{"rec": _item1_recorder, "gt": _item1_ghost_trail, "rb": _item1, "tr": _item1_trail},
		{"rec": _item2_recorder, "gt": _item2_ghost_trail, "rb": _item2, "tr": _item2_trail},
		{"rec": _item3_recorder, "gt": _item3_ghost_trail, "rb": _item3, "tr": _item3_trail},
	]:
		entry.rec.target = entry.rb
		entry.gt.target = entry.rb
		entry.gt.trail_renderer = entry.tr
		entry.gt.trail_color = trail_color
		_item_timeline.subscribe(entry.rec)
		_item_timeline.subscribe(entry.gt)

	_hud_exit.pressed.connect(_on_exit_pressed)
	_hud_rewind.hold_started.connect(_on_rewind_started)
	_hud_rewind.hold_ended.connect(_on_rewind_ended)
	_hud_dialog.confirmed.connect(_on_restart)
	_hud_win.confirmed.connect(_on_win_confirmed)
	_hud_gm_button.pressed.connect(_on_gm_open)
	_hud_gm_close.pressed.connect(_on_gm_close)
	_door.body_entered.connect(_on_door_entered)
	_item1_hit.body_entered.connect(_on_item_hit)
	_item2_hit.body_entered.connect(_on_item_hit)
	_item3_hit.body_entered.connect(_on_item_hit)
	_item_timeline.drag_state_changed.connect(_on_item_drag_state_changed)
	_hud_timeline.bind_timeline(_item_timeline)
	_hud_tips.visible = false
	_populate_levels()
	_update_timer_label()
	_item_timeline.push_visuals()

func _physics_process(delta: float) -> void:
	if _game_over or _won:
		return
	_camera.tick_yaw(delta)
	_item_timeline.rewind_held = _rewind_held
	_tick_item_timeline(delta)

func _tick_item_timeline(delta: float) -> void:
	var input_active := _is_item_inputting()
	var state := _item_timeline.get_game_state(input_active)
	match state:
		Timeline.State.GAME_OVER, Timeline.State.DRAGGING, Timeline.State.LOCKED:
			_apply_item_freeze(true)
			_item_timeline.disable_recording()
		Timeline.State.REWINDING:
			_apply_item_freeze(true)
			_item_timeline.disable_recording()
			_item_timeline.step_backward(delta)
		Timeline.State.ADVANCING:
			_item_waiting_for_input = false
			_apply_item_freeze(false)
			_item_timeline.advance(delta)
		Timeline.State.IDLE:
			if _item_waiting_for_input:
				_apply_item_freeze(true)
			else:
				_apply_item_freeze(false)
			_item_timeline.disable_recording()

func _process(delta: float) -> void:
	if not _game_over and not _won:
		_countdown -= delta
		if _countdown <= 0.0:
			_countdown = 0.0
			_trigger_game_over("时间到，游戏结束")
	_item_timeline.push_visuals()
	_update_timer_label()
	var locked := _item_timeline.is_locked()
	_hud_tips.visible = locked and not _item_timeline.dragging
	if locked or _countdown < 5.0:
		_hud_timer.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		_hud_timer.add_theme_color_override("font_color", Color(0.2, 1, 0.4, 1))

func _apply_item_freeze(freeze: bool) -> void:
	_item1.freeze = freeze
	_item2.freeze = freeze
	_item3.freeze = freeze

func _is_item_inputting() -> bool:
	if _item_waiting_for_input:
		# 第一次需要等 item 有运动才开始记录
		if Rewindable.has_motion(_item1) or Rewindable.has_motion(_item2) or Rewindable.has_motion(_item3):
			return true
		return false
	if Rewindable.has_motion(_item1) or Rewindable.has_motion(_item2) or Rewindable.has_motion(_item3):
		return true
	return false

func _on_item_drag_state_changed(dragging: bool) -> void:
	if not dragging:
		_item_waiting_for_input = true

func _update_timer_label() -> void:
	var remaining := maxf(0.0, _countdown)
	var total_ms := int(remaining * 1000.0)
	var m := total_ms / 60000
	var s := (total_ms / 1000) % 60
	var ms := total_ms % 1000
	_hud_timer.text = "%02d:%02d:%03d" % [m, s, ms]

func _trigger_game_over(msg: String) -> void:
	if _game_over or _won:
		return
	_game_over = true
	_item_timeline.mark_game_over()
	get_tree().paused = true
	_hud_dialog.dialog_text = msg
	_hud_dialog.popup_centered()

func _trigger_win() -> void:
	if _game_over or _won:
		return
	_won = true
	_item_timeline.mark_game_over()
	get_tree().paused = true
	_hud_win.popup_centered()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_win_confirmed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://world.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
	OS.kill(OS.get_process_id())

func _on_door_entered(body: Node3D) -> void:
	if _door_triggered:
		return
	if body != _actor:
		return
	_door_triggered = true
	_trigger_win()

func _on_item_hit(body: Node3D) -> void:
	if body != _actor:
		return
	_trigger_game_over("撞到道具了！")

func _on_rewind_started() -> void:
	_rewind_held = true

func _on_rewind_ended() -> void:
	_rewind_held = false

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
