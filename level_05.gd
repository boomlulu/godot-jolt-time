extends BaseLevel

# 第五关·平台 + 时间轴。第四关移动平台改由 Timeline 驱动：自走 + 可回退。
# 平台位置 = pos_at_time(timeline.current_time) 纯时间函数 → 时间轴前进/回退/拖动/冻结天然驱动平台。
# 时间轴：每帧自走 advance；按"回退平台"键倒退最近 3s（REWIND_WINDOW）；拖时间轴条 seek 跳转。
# actor：玩家控制 + move_and_slide 原生 carry（不录制、不冻结）；回退时平台倒退、actor 被带着倒走
#        （拖条快跳一帧大位移可能甩飞 actor —— 已知取舍，按用户选"只回退平台"）。
#
# 数据化验证：每帧累计 carry 稳定性 + 时间轴状态 + 平台跟随误差，点 HUD"提交Bug"复制。判定见末尾 expectation_hint。

const FALL_RESET_Y := -8.0

@onready var _timeline: Timeline = $Timeline
@onready var _camera: Camera3D = $Camera3D
@onready var _platform = $MovingPlatform
@onready var _hud_joystick: Control = $HUD/HUDBase/Joystick
@onready var _hud_rewind: Button = $HUD/RewindButton
@onready var _hud_timer: Label = $HUD/HUDBase/TimerLabel
@onready var _hud_tips: Label = $HUD/HUDBase/TipsLabel
@onready var _hud_timeline: Control = $HUD/TimelineBar

var _actor_spawn: Vector3 = Vector3.ZERO
var _rewind_held: bool = false

# --- 累计指标 ---
var _elapsed: float = 0.0
var _rewind_frames: int = 0
var _landed: bool = false
var _ref_offset: Vector2 = Vector2.ZERO
var _frames_since_land: int = 0
var _on_floor_frames: int = 0
var _drift_max: float = 0.0
var _drift_sum: float = 0.0
var _drift_samples: int = 0
var _reset_count: int = 0

func _ready() -> void:
	super._ready()
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_camera.target = _actor
	_platform.timeline = _timeline   # 关键：平台挂时间轴
	_actor_spawn = _actor.global_position
	_hud_rewind.hold_started.connect(_on_rewind_started)
	_hud_rewind.hold_ended.connect(_on_rewind_ended)
	_hud_rewind.text = "回退平台"
	_hud_timeline.bind_timeline(_timeline)
	_hud_timer.bind_timeline(_timeline)
	_hud_tips.visible = false
	_timeline.push_visuals()

func _physics_process(delta: float) -> void:
	_camera.tick_yaw(delta)
	_elapsed += delta
	_timeline.rewind_held = _rewind_held
	# 自走 + 可回退：input_active 恒 true → 非回退/拖动/锁定时持续 advance
	var state := _timeline.get_game_state(true)
	match state:
		Timeline.State.REWINDING:
			_timeline.step_backward(delta)
			_rewind_frames += 1
		Timeline.State.DRAGGING, Timeline.State.LOCKED, Timeline.State.GAME_OVER:
			pass
		_:
			_timeline.advance(delta)
	_track_stability()
	if _actor.global_position.y < FALL_RESET_Y:
		_reset_count += 1
		_respawn_actor()

func _process(_delta: float) -> void:
	_timeline.push_visuals()
	_hud_tips.visible = _timeline.is_locked()

func _track_stability() -> void:
	var on_floor: bool = _actor.is_on_floor()
	if not _landed:
		if not on_floor:
			return
		_landed = true
		_ref_offset = _current_offset()
	# 回退中：平台倒退、actor 被带着倒走，相对位移本就变化，不计入"前进站稳"漂移
	if _timeline.rewind_held and _timeline.current_time > 0.0:
		return
	_frames_since_land += 1
	if on_floor:
		_on_floor_frames += 1
		var drift: float = _current_offset().distance_to(_ref_offset)
		_drift_max = maxf(_drift_max, drift)
		_drift_sum += drift
		_drift_samples += 1

func _current_offset() -> Vector2:
	return Vector2(
		_actor.global_position.x - _platform.global_position.x,
		_actor.global_position.z - _platform.global_position.z)

func _expected_platform_pos() -> Vector3:
	return _platform.pos_at_time(_timeline.current_time)

func _respawn_actor() -> void:
	_actor.velocity = Vector3.ZERO
	_actor.global_position = _actor_spawn

func _on_rewind_started() -> void:
	_rewind_held = true

func _on_rewind_ended() -> void:
	_rewind_held = false

func _on_door_passed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")

func _dump_state() -> Dictionary:
	var on_floor_pct: float = 0.0
	if _frames_since_land > 0:
		on_floor_pct = float(_on_floor_frames) / float(_frames_since_land) * 100.0
	var drift_mean: float = 0.0
	if _drift_samples > 0:
		drift_mean = _drift_sum / float(_drift_samples)
	var expected := _expected_platform_pos()
	var track_err: float = _platform.global_position.distance_to(expected)
	return {
		"level": "05_platform_timeline",
		"elapsed_s": _elapsed,
		"timeline": {
			"current_time": _timeline.current_time,
			"max_time": _timeline.max_time,
			"total_duration": _timeline.total_duration,
			"state": _state_name(_timeline.get_game_state(true)),
			"locked": _timeline.is_locked(),
			"rewind_held": _timeline.rewind_held,
			"rewind_frames_total": _rewind_frames,
		},
		"platform_tracks_timeline": {
			"pos": _platform.global_position,
			"expected_from_current_time": expected,
			"track_err_m": track_err,
		},
		"carry_stability_forward": {
			"landed": _landed,
			"drift_max_m": _drift_max,
			"drift_mean_m": drift_mean,
			"on_floor_pct": on_floor_pct,
			"reset_count": _reset_count,
			"ref_offset_xz": _ref_offset,
		},
		"actor": {
			"pos": _actor.global_position,
			"vel": _actor.velocity,
			"on_floor": _actor.is_on_floor(),
		},
		"expectation_hint": "PASS if: track_err_m<0.05(平台精确跟随时间轴) & landed=true & reset_count=0 & drift_max_m<0.25 & on_floor_pct>=99; 回退验证:按住回退键后 current_time<max_time 且 rewind_frames_total>0",
	}
