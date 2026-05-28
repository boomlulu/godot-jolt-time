extends Node3D

const _TOUCH_BUTTON_SCRIPT := preload("res://touch_button.gd")
const GameSettings := preload("res://game_settings.gd")
const BugReport := preload("res://bug_report.gd")

const LEVELS := [
	{"name": "新手引导", "scene": "res://world.tscn"},
	{"name": "第二关·钥匙", "scene": "res://level_02.tscn"},
	{"name": "第三关", "scene": "res://level_03.tscn"},
]

const FALL_DEATH_Y := -5.0

@onready var _item_timeline: Timeline = $ItemTimeline
@onready var _actor: CharacterBody3D = $Actor
@onready var _camera: Camera3D = $Camera3D
@onready var _hud_joystick: Control = $HUD/Joystick
@onready var _hud_exit: Button = $HUD/ExitButton
@onready var _hud_bug: Button = $HUD/BugReportButton
@onready var _hud_rewind: Button = $HUD/RewindButton
@onready var _hud_pause: Button = $HUD/PauseButton
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

var _rewind_held: bool = false
var _item_paused: bool = false
var _door_triggered: bool = false
var _game_over: bool = false
var _won: bool = false

var _items: Array = []
var _riding_platform: RigidBody3D = null
var _riding_last_x: float = 0.0
var _pause_click_count: int = 0
var _bug_click_count: int = 0
var _rewind_press_count: int = 0

func _ready() -> void:
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_camera.target = _actor

	# items setup
	_items = [_item1, _item2, _item3]
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
		entry.gt.enabled = GameSettings.ITEM_GHOST_TRAIL_ENABLED
		entry.rb.timeline = _item_timeline
		_item_timeline.subscribe(entry.rec)
		_item_timeline.subscribe(entry.gt)

	_hud_exit.pressed.connect(_on_exit_pressed)
	_hud_bug.pressed.connect(_on_bug_report)
	_hud_rewind.hold_started.connect(_on_rewind_started)
	_hud_rewind.hold_ended.connect(_on_rewind_ended)
	_hud_pause.pressed.connect(_on_pause_toggled)
	_hud_pause.text = "暂停道具"
	_hud_dialog.confirmed.connect(_on_restart)
	_hud_win.confirmed.connect(_on_win_confirmed)
	_hud_gm_button.pressed.connect(_on_gm_open)
	_hud_gm_close.pressed.connect(_on_gm_close)
	_door.body_entered.connect(_on_door_entered)
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
	_carry_actor_on_platform()

func _carry_actor_on_platform() -> void:
	# delta-based carry: 玩家踩在 platform 上时跟随 platform 的 x 平移
	# 时机：在 platform _physics_process 推进之后调用，此时 platform 已到新位置
	var current_ride := _detect_ride()
	if current_ride != null and current_ride == _riding_platform:
		var dx: float = current_ride.global_position.x - _riding_last_x
		if absf(dx) > 0.0:
			_actor.global_position.x += dx
	_riding_platform = current_ride
	if current_ride != null:
		_riding_last_x = current_ride.global_position.x

func _detect_ride() -> RigidBody3D:
	# 从 actor 脚底向下射线检测，命中的若是已知 platform 则返回
	var space := _actor.get_world_3d().direct_space_state
	var from := _actor.global_position + Vector3(0, 0.1, 0)
	var to := _actor.global_position + Vector3(0, -0.6, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_actor.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	var body = hit.collider
	for item in _items:
		if item == body:
			return item
	return null

func _check_fall_off() -> void:
	if _game_over or _won:
		return
	if _actor.global_position.y < FALL_DEATH_Y:
		_trigger_game_over("掉下深坑，游戏结束")


func _is_input_active() -> bool:
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
	if not _actor.is_on_floor():
		return true
	if Rewindable.has_motion(_actor):
		return true
	if not _item_paused:
		return true
	for item in _items:
		if Rewindable.has_motion(item):
			return true
	return false

func _tick_item_timeline(delta: float) -> void:
	var state := _item_timeline.get_game_state(_is_input_active())
	match state:
		Timeline.State.GAME_OVER, Timeline.State.DRAGGING, Timeline.State.LOCKED:
			_item_timeline.disable_recording()
		Timeline.State.REWINDING:
			_item_timeline.disable_recording()
			_item_timeline.step_backward(delta)
		Timeline.State.ADVANCING:
			_item_timeline.advance(delta)
		Timeline.State.IDLE:
			_item_timeline.disable_recording()

func _process(_delta: float) -> void:
	if not _game_over and not _won:
		_check_fall_off()
		if _item_timeline.current_time >= _item_timeline.total_duration:
			_trigger_game_over("时间到，游戏结束")
	_item_timeline.push_visuals()
	_update_timer_label()
	var locked := _item_timeline.is_locked()
	_hud_tips.visible = locked and not _item_timeline.dragging
	var remaining := _item_timeline.total_duration - _item_timeline.current_time
	if locked or remaining < 5.0:
		_hud_timer.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		_hud_timer.add_theme_color_override("font_color", Color(0.2, 1, 0.4, 1))

func _update_timer_label() -> void:
	var remaining := maxf(0.0, _item_timeline.total_duration - _item_timeline.current_time)
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

func _on_rewind_started() -> void:
	_rewind_press_count += 1
	_rewind_held = true

func _on_rewind_ended() -> void:
	_rewind_held = false

func _on_pause_toggled() -> void:
	_pause_click_count += 1
	_item_paused = not _item_paused
	_hud_pause.text = "恢复道具" if _item_paused else "暂停道具"

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

func _state_name(s: int) -> String:
	match s:
		Timeline.State.IDLE: return "IDLE"
		Timeline.State.ADVANCING: return "ADVANCING"
		Timeline.State.REWINDING: return "REWINDING"
		Timeline.State.DRAGGING: return "DRAGGING"
		Timeline.State.LOCKED: return "LOCKED"
		Timeline.State.GAME_OVER: return "GAME_OVER"
	return "?"

func _item_line(label: String, item: RigidBody3D) -> String:
	return "%s: pos=%s vel=%s freeze=%s home=(%.2f,%.2f,%.2f) amp=%.2f freq=%.2f phase=%.3f\n" % [
		label, str(item.global_position), str(item.linear_velocity), str(item.freeze),
		item.home_x, item.home_y, item.home_z, item.amplitude, item.frequency_hz, item.phase,
	]

func _on_bug_report() -> void:
	_bug_click_count += 1
	var state := _item_timeline.get_game_state(_is_input_active())
	var body := "clicks: bug=%d pause=%d rewind=%d  btn_text=%s\n" % [
		_bug_click_count, _pause_click_count, _rewind_press_count, _hud_pause.text,
	]
	body += "item_timeline: state=%s current=%.3f total=%.3f max=%.3f grey=%.3f locked=%s dragging=%s rewind=%s\n" % [
		_state_name(state), _item_timeline.current_time, _item_timeline.total_duration,
		_item_timeline.max_time, _item_timeline.grey_water, str(_item_timeline.is_locked()),
		str(_item_timeline.dragging), str(_item_timeline.rewind_held),
	]
	body += "actor: pos=%s vel=%s on_floor=%s\n" % [
		str(_actor.global_position), str(_actor.velocity), str(_actor.is_on_floor()),
	]
	body += _item_line("item1", _item1)
	body += _item_line("item2", _item2)
	body += _item_line("item3", _item3)
	body += "camera: yaw=%.2f target_yaw=%.2f\n" % [_camera.yaw_deg, _camera.target_yaw_deg]
	var riding_name: String = "null" if _riding_platform == null else String(_riding_platform.name)
	body += "flags: item_paused=%s rewind_held=%s riding=%s riding_last_x=%.3f door_triggered=%s input_active=%s" % [
		str(_item_paused), str(_rewind_held), riding_name, _riding_last_x,
		str(_door_triggered), str(_is_input_active()),
	]
	await BugReport.copy(_hud_bug, self, body)
