extends BaseLevel

const FALL_DEATH_Y := -5.0

@onready var _item_timeline: Timeline = $ItemTimeline
@onready var _camera: Camera3D = $Camera3D
@onready var _hud_joystick: Control = $HUD/HUDBase/Joystick
@onready var _hud_rewind: Button = $HUD/RewindButton
@onready var _hud_pause: Button = $HUD/PauseButton
@onready var _hud_timer: Label = $HUD/HUDBase/TimerLabel
@onready var _hud_tips: Label = $HUD/HUDBase/TipsLabel
@onready var _hud_dialog: AcceptDialog = $HUD/HUDBase/GameOverDialog
@onready var _hud_win: AcceptDialog = $HUD/WinDialog
@onready var _hud_timeline: Control = $HUD/TimelineBar

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
var _game_over: bool = false
var _won: bool = false

var _items: Array = []
var _carry: CarryRelation = null

func _ready() -> void:
	super._ready()
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

	_hud_rewind.hold_started.connect(_on_rewind_started)
	_hud_rewind.hold_ended.connect(_on_rewind_ended)
	_hud_pause.pressed.connect(_on_pause_toggled)
	_hud_pause.text = "暂停道具"
	_hud_dialog.confirmed.connect(_on_restart)
	_hud_win.confirmed.connect(_on_win_confirmed)
	_hud_timeline.bind_timeline(_item_timeline)
	_hud_timer.bind_timeline(_item_timeline)
	_hud_tips.visible = false
	_item_timeline.push_visuals()

func _physics_process(delta: float) -> void:
	if _game_over or _won:
		return
	_camera.tick_yaw(delta)
	_item_timeline.rewind_held = _rewind_held
	_tick_timeline(
		_item_timeline, delta, _is_input_active(),
		func(_f): pass,
		func(): pass,
		func(): return false,
		func(): pass,
	)
	_carry_actor_on_platform()

func _carry_actor_on_platform() -> void:
	# delta-based carry: 玩家踩 platform 上时跟随其平移
	# 时机：root _physics_process 内调用（树序早于 Item，故 ~1 帧滞后，平台慢可忽略）
	var current_ride := _detect_ride()
	if current_ride == null:
		_carry = null
		return
	if _carry == null or _carry.platform != current_ride:
		_carry = CarryRelation.new(_actor, current_ride)
		return  # 新踩上：先锚定，本帧不搬
	_carry.update()

func _detect_ride() -> Node3D:
	# actor 脚底向下射线，命中体在 "platform" 组则可搭乘
	# 注：actor 盒高 1.6（脚底 origin -0.8），射线须到 -0.9 才够得着脚下平台
	var space := _actor.get_world_3d().direct_space_state
	var from := _actor.global_position + Vector3(0, 0.1, 0)
	var to := _actor.global_position + Vector3(0, -0.9, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_actor.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	var body = hit.collider
	if body is Node3D and (body as Node3D).is_in_group("platform"):
		return body
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
	if _actor.has_activity():
		return true
	if not _item_paused:
		return true
	for item in _items:
		if item.has_activity():
			return true
	return false

func _process(_delta: float) -> void:
	if not _game_over and not _won:
		_check_fall_off()
		if _item_timeline.current_time >= _item_timeline.total_duration:
			_trigger_game_over("时间到，游戏结束")
	_item_timeline.push_visuals()
	var locked := _item_timeline.is_locked()
	_hud_tips.visible = locked and not _item_timeline.dragging
	var remaining := _item_timeline.total_duration - _item_timeline.current_time
	if locked or remaining < 5.0:
		_hud_timer.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		_hud_timer.add_theme_color_override("font_color", Color(0.2, 1, 0.4, 1))

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

func _on_win_confirmed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://world.tscn")

func _on_door_passed() -> void:
	_trigger_win()

func _on_rewind_started() -> void:
	_rewind_held = true

func _on_rewind_ended() -> void:
	_rewind_held = false

func _on_pause_toggled() -> void:
	_item_paused = not _item_paused
	_hud_pause.text = "恢复道具" if _item_paused else "暂停道具"

func _item_dict(label: String, item: RigidBody3D) -> Dictionary:
	return {
		"name": label,
		"pos": item.global_position,
		"vel": item.linear_velocity,
		"freeze": item.freeze,
		"home_x": item.home_x,
		"home_y": item.home_y,
		"home_z": item.home_z,
		"amp": item.amplitude,
		"freq": item.frequency_hz,
		"phase": item.phase,
	}

func _dump_state() -> Dictionary:
	var state := _item_timeline.get_game_state(_is_input_active())
	var riding_name: String = "null" if _carry == null else String(_carry.platform.name)
	return {
		"item_timeline": {
			"state": _state_name(state),
			"current": _item_timeline.current_time,
			"total": _item_timeline.total_duration,
			"max": _item_timeline.max_time,
			"grey": _item_timeline.grey_water,
			"locked": _item_timeline.is_locked(),
			"dragging": _item_timeline.dragging,
			"rewind": _item_timeline.rewind_held,
		},
		"actor": {
			"pos": _actor.global_position,
			"vel": _actor.velocity,
			"on_floor": _actor.is_on_floor(),
		},
		"items": [
			_item_dict("Item1", _item1),
			_item_dict("Item2", _item2),
			_item_dict("Item3", _item3),
		],
		"camera": {
			"yaw": _camera.yaw_deg,
			"target_yaw": _camera.target_yaw_deg,
		},
		"flags": {
			"item_paused": _item_paused,
			"rewind_held": _rewind_held,
			"riding": riding_name,
			"riding_x": 0.0 if _carry == null else _carry.platform.global_position.x,
			"door_triggered": _door_triggered,
			"input_active": _is_input_active(),
		},
	}
