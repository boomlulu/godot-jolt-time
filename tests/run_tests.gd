extends Node3D

const BugReportModule := preload("res://bug_report.gd")

var _failures: Array = []
var _passes: int = 0

func _ready() -> void:
	await get_tree().physics_frame  # 让 _ready 后物理系统就绪
	_test_b_kinematic_freeze_has_no_motion()
	_test_b_normal_rigid_has_motion()
	_test_b_character_body_motion()
	_test_c_button_same_frame_dedup()
	_test_d_timer_label_format()
	_test_d_timer_label_zero()
	_test_3_dict_to_text_flat()
	_test_3_dict_to_text_nested()
	_test_3_dict_to_text_array_of_dicts()
	_test_3_dict_to_text_array_of_primitives()
	_test_3_dict_to_text_float_format()
	await _test_3_dump_state_world()
	await _test_3_dump_state_level_02()
	await _test_3_dump_state_level_03()
	await _test_1_actor_idle_no_activity()
	await _test_1_actor_high_velocity_active()
	await _test_1_actor_airborne_active()
	await _test_1_item_has_activity_false()
	await _test_1_level_03_pause_makes_inactive()
	await _test_1_level_03_unpause_makes_active()
	await _test_4_gm_panel_loads()
	await _test_4_gm_panel_populates_buttons()
	await _test_4_gm_panel_emits_signal()
	await _test_4_levels_have_gm_panel()
	_test_2_base_level_class_registered()
	await _test_2_levels_extend_base_level()
	await _test_2_get_levels_returns_three()
	await _test_2_state_name_translates()
	await _test_2_base_handlers_present()
	await _test_5_l03_pause_freezes_timeline()
	await _test_5_l03_unpause_advances_timeline()
	await _test_5_l03_carry_actor_follows_platform()
	await _test_5_l02_key_pickup_sets_flag()
	await _test_5_l02_door_locked_without_key()
	await _test_5_world_waiting_freezes_actor()
	await _test_6_levels_registry_single_source()
	_test_6_motion_epsilon_constant()
	await _test_6_pushbox_has_activity()
	await _test_6_door_triggered_template()
	await _test_6_door_blocked_without_key()
	await _test_6_door_ignores_non_actor()
	await _test_6_tick_timeline_advance()
	await _test_6_tick_timeline_idle_with_waiting()
	await _test_6_tick_timeline_rewinding()
	await _test_7_item_sine_formula()
	_print_summary_and_quit()

# B: KINEMATIC freeze RigidBody3D 即使 linear_velocity 非零也不算 motion
func _test_b_kinematic_freeze_has_no_motion() -> void:
	var rb := RigidBody3D.new()
	rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	rb.freeze = true
	rb.linear_velocity = Vector3(5, 0, 0)
	add_child(rb)
	var ok := not Rewindable.has_motion(rb)
	rb.queue_free()
	_check(ok, "B1 KINEMATIC freeze has_motion=false")

# B: 普通 RigidBody3D 带 velocity 应该报 motion
func _test_b_normal_rigid_has_motion() -> void:
	var rb := RigidBody3D.new()
	rb.linear_velocity = Vector3(5, 0, 0)
	add_child(rb)
	var ok := Rewindable.has_motion(rb)
	rb.queue_free()
	_check(ok, "B2 non-frozen rigid has_motion=true")

# CharacterBody3D 行为不变
func _test_b_character_body_motion() -> void:
	var cb := CharacterBody3D.new()
	cb.velocity = Vector3(5, 0, 0)
	add_child(cb)
	var ok := Rewindable.has_motion(cb)
	cb.queue_free()
	_check(ok, "B3 CharacterBody motion=true")

# C: 同一帧内多次 _emit_once 只 emit 一次 pressed
func _test_c_button_same_frame_dedup() -> void:
	var btn := Button.new()
	btn.set_script(load("res://touch_button.gd"))
	add_child(btn)
	var counter := [0]
	btn.pressed.connect(func(): counter[0] += 1)
	btn._emit_once()
	btn._emit_once()
	btn._emit_once()
	var actual: int = counter[0]
	var ok: bool = actual == 1
	btn.queue_free()
	_check(ok, "C1 same-frame emit dedup: expected 1 got %d" % actual)

# D: TimerLabel 根据 Timeline 渲染剩余时间
func _test_d_timer_label_format() -> void:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	tl.current_time = 5.0
	add_child(tl)
	var lbl := Label.new()
	lbl.set_script(load("res://timer_label.gd"))
	lbl.bind_timeline(tl)
	add_child(lbl)
	lbl._process(0.0)
	var ok := lbl.text == "00:15:000"
	var actual := lbl.text
	lbl.queue_free()
	tl.queue_free()
	_check(ok, "D1 timer label remaining=15s -> '00:15:000', got '%s'" % actual)

# D: current_time >= total_duration 时显示 00:00:000
func _test_d_timer_label_zero() -> void:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	tl.current_time = 25.0
	add_child(tl)
	var lbl := Label.new()
	lbl.set_script(load("res://timer_label.gd"))
	lbl.bind_timeline(tl)
	add_child(lbl)
	lbl._process(0.0)
	var ok := lbl.text == "00:00:000"
	var actual := lbl.text
	lbl.queue_free()
	tl.queue_free()
	_check(ok, "D2 timer label overflow -> '00:00:000', got '%s'" % actual)

func _test_3_dict_to_text_flat() -> void:
	var d := {"a": 1, "b": "hello", "c": true}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("a: 1") and out.contains("b: hello") and out.contains("c: true")
	_check(ok, "3.1 flat dict")

func _test_3_dict_to_text_nested() -> void:
	var d := {"timeline": {"current": 1.5, "state": "IDLE"}}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("timeline:") and out.contains("  current: 1.500") and out.contains("  state: IDLE")
	_check(ok, "3.2 nested dict 2-space indent")

func _test_3_dict_to_text_array_of_dicts() -> void:
	var d := {"items": [{"x": 1}, {"x": 2}]}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("items:") and out.contains("- x: 1") and out.contains("- x: 2")
	_check(ok, "3.3 array of dicts with dash prefix")

func _test_3_dict_to_text_array_of_primitives() -> void:
	var d := {"nums": [1, 2, 3]}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("nums: [1, 2, 3]")
	_check(ok, "3.4 inline array of primitives")

func _test_3_dict_to_text_float_format() -> void:
	var d := {"v": 3.14159}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("v: 3.142")
	_check(ok, "3.5 float 3 decimals")

func _test_3_dump_state_world() -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var state: Dictionary = inst._dump_state()
	var ok := state.has("timeline") and state.has("actor") and state.has("pushbox") and state.has("camera") and state.has("flags")
	inst.queue_free()
	_check(ok, "3.6 world _dump_state has expected top keys")

func _test_3_dump_state_level_02() -> void:
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var state: Dictionary = inst._dump_state()
	var ok := state.has("actor_timeline") and state.has("box_timeline") and state.has("actor") and state.has("pushbox") and state.has("flags")
	inst.queue_free()
	_check(ok, "3.7 level_02 _dump_state has expected top keys")

func _test_3_dump_state_level_03() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var state: Dictionary = inst._dump_state()
	var ok := state.has("item_timeline") and state.has("actor") and state.has("items") and state.has("flags")
	var items_arr: Array = state.get("items", [])
	ok = ok and items_arr.size() == 3
	inst.queue_free()
	_check(ok, "3.8 level_03 _dump_state has expected top keys + 3 items")

func _test_1_actor_idle_no_activity() -> void:
	# 用 level_03（actor 不受 waiting_for_input 门控冻结，能自然落地）
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	var actor: CharacterBody3D = inst.get_node("Actor")
	for i in range(30):
		await get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	for i in range(5):
		await get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	var ok: bool = not actor.has_activity()
	var on_floor: bool = actor.is_on_floor()
	inst.queue_free()
	_check(ok, "1.1 actor idle on floor has_activity=false (on_floor=%s)" % str(on_floor))

func _test_1_actor_high_velocity_active() -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3(5, 0, 0)
	var ok: bool = actor.has_activity()
	inst.queue_free()
	_check(ok, "1.2 actor velocity>0.05 has_activity=true")

func _test_1_actor_airborne_active() -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.global_position.y = 50.0
	await get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	var ok: bool = actor.has_activity()
	inst.queue_free()
	_check(ok, "1.3 actor airborne has_activity=true")

func _test_1_item_has_activity_false() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var item: RigidBody3D = inst.get_node("Item1")
	var ok: bool = not item.has_activity()
	inst.queue_free()
	_check(ok, "1.4 level_03_item has_activity always false (KINEMATIC by-rule)")

func _test_1_level_03_pause_makes_inactive() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in range(20):
		await get_tree().physics_frame
	inst._item_paused = true
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3.ZERO
	for i in range(5):
		await get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	var active: bool = inst._is_input_active()
	var actor_active: bool = actor.has_activity()
	var on_floor: bool = actor.is_on_floor()
	inst.queue_free()
	_check(not active, "1.5 level_03 paused + actor idle => input_active=false (actor.has_activity=%s on_floor=%s)" % [str(actor_active), str(on_floor)])

func _test_1_level_03_unpause_makes_active() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in range(20):
		await get_tree().physics_frame
	inst._item_paused = false
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3.ZERO
	await get_tree().physics_frame
	var active: bool = inst._is_input_active()
	inst.queue_free()
	_check(active, "1.6 level_03 unpaused (items by rule) => input_active=true")

func _test_4_gm_panel_loads() -> void:
	var packed := load("res://gm_panel.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var ok: bool = inst != null and inst.has_method("set_levels")
	inst.queue_free()
	_check(ok, "4.1 gm_panel.tscn loads and has set_levels()")

func _test_4_gm_panel_populates_buttons() -> void:
	var packed := load("res://gm_panel.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	inst.set_levels([
		{"name": "Test A", "scene": "res://a.tscn"},
		{"name": "Test B", "scene": "res://b.tscn"},
	])
	await get_tree().physics_frame
	var level_buttons: VBoxContainer = inst.get_node("PanelOverlay/CenterBox/VBox/LevelButtons")
	var count: int = level_buttons.get_child_count()
	var ok: bool = count == 2
	inst.queue_free()
	_check(ok, "4.2 gm_panel set_levels populates %d buttons (expected 2)" % count)

func _test_4_gm_panel_emits_signal() -> void:
	var packed := load("res://gm_panel.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	inst.set_levels([{"name": "X", "scene": "res://x.tscn"}])
	await get_tree().physics_frame
	var captured := [""]
	inst.level_chosen.connect(func(p): captured[0] = p)
	inst._on_level_pressed("res://x.tscn")
	var ok: bool = captured[0] == "res://x.tscn"
	inst.queue_free()
	_check(ok, "4.3 gm_panel emits level_chosen on level click")

func _test_4_levels_have_gm_panel() -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().physics_frame
		var has_gm: bool = inst.has_node("HUD/GMPanel")
		if not has_gm:
			all_ok = false
		var gm = inst.get_node_or_null("HUD/GMPanel")
		if gm != null:
			var level_buttons = gm.get_node_or_null("PanelOverlay/CenterBox/VBox/LevelButtons")
			if level_buttons == null or level_buttons.get_child_count() != 3:
				all_ok = false
		inst.queue_free()
	_check(all_ok, "4.4 all 3 levels have GMPanel instance with 3 populated buttons")

func _test_2_base_level_class_registered() -> void:
	var ok: bool = ClassDB.class_exists("BaseLevel") or load("res://base_level.gd") != null
	_check(ok, "2.1 BaseLevel class loadable")

func _test_2_levels_extend_base_level() -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().physics_frame
		var is_base: bool = inst is BaseLevel
		if not is_base:
			all_ok = false
		inst.queue_free()
	_check(all_ok, "2.2 all 3 levels extend BaseLevel")

func _test_2_get_levels_returns_three() -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().physics_frame
		var levels: Array = inst._get_levels()
		if levels.size() != 3:
			all_ok = false
		inst.queue_free()
	_check(all_ok, "2.3 all 3 levels _get_levels() returns 3 entries")

func _test_2_state_name_translates() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var ok: bool = (
		inst._state_name(Timeline.State.IDLE) == "IDLE"
		and inst._state_name(Timeline.State.ADVANCING) == "ADVANCING"
		and inst._state_name(Timeline.State.REWINDING) == "REWINDING"
		and inst._state_name(Timeline.State.DRAGGING) == "DRAGGING"
		and inst._state_name(Timeline.State.LOCKED) == "LOCKED"
		and inst._state_name(Timeline.State.GAME_OVER) == "GAME_OVER"
	)
	inst.queue_free()
	_check(ok, "2.4 _state_name maps all 6 enum values")

func _test_2_base_handlers_present() -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var ok: bool = (
		inst.has_method("_on_exit_pressed")
		and inst.has_method("_on_level_pressed")
		and inst.has_method("_on_bug_report")
	)
	inst.queue_free()
	_check(ok, "2.5 base handlers present on level instance")

const LevelsRegistry := preload("res://levels_registry.gd")

func _test_6_levels_registry_single_source() -> void:
	# 注册表有 3 项
	var registry_size: int = LevelsRegistry.ALL.size()
	if registry_size != 3:
		_check(false, "6.1 registry size expected 3 got %d" % registry_size)
		return
	# 三关 _get_levels() 返同一引用 / 同内容
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().physics_frame
		var levels: Array = inst._get_levels()
		var same: bool = levels == LevelsRegistry.ALL
		inst.queue_free()
		if not same:
			_check(false, "6.1 %s _get_levels != LevelsRegistry.ALL" % p)
			return
	_check(true, "6.1 LevelsRegistry single source: 3 entries, all levels match")

func _test_6_motion_epsilon_constant() -> void:
	# 常量定义在 Rewindable，值为 0.05
	var v: float = Rewindable.MOTION_EPSILON
	var ok: bool = absf(v - 0.05) < 0.0001
	_check(ok, "6.2 Rewindable.MOTION_EPSILON = 0.05 (got %.4f)" % v)

func _test_6_pushbox_has_activity() -> void:
	# world 和 level_02 的 PushBox 应该挂 physics_box.gd 并有 has_activity 方法
	var paths := ["res://world.tscn", "res://level_02.tscn"]
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().physics_frame
		var pb: Node = inst.get_node("PushBox")
		var has_method_ok: bool = pb.has_method("has_activity")
		# 初始静止 → has_activity false
		var inactive: bool = not pb.has_activity()
		# 强行设速度 → has_activity true
		(pb as RigidBody3D).linear_velocity = Vector3(2, 0, 0)
		var active: bool = pb.has_activity()
		inst.queue_free()
		if not (has_method_ok and inactive and active):
			_check(false, "6.3 %s PushBox.has_activity (method=%s inactive=%s active=%s)" % [p, str(has_method_ok), str(inactive), str(active)])
			return
	_check(true, "6.3 PushBox has_activity() works for world + level_02")

func _test_6_door_triggered_template() -> void:
	# 用 level_03 测，_on_door_passed=_trigger_win 不切场景，更安全
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var before: bool = inst._door_triggered
	inst._handle_door_body_entered(actor)
	var after: bool = inst._door_triggered
	var won: bool = inst._won
	inst.queue_free()
	# _trigger_win 会 pause，手动清掉
	get_tree().paused = false
	var ok: bool = (not before) and after and won
	_check(ok, "6.4 BaseLevel door template: door pass triggers _on_door_passed (l03 win)")

func _test_6_door_blocked_without_key() -> void:
	# level_02 没 key 时 door blocked，_door_triggered 保持 false
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	inst._has_key = false
	inst._handle_door_body_entered(actor)
	var ok: bool = not inst._door_triggered
	inst.queue_free()
	_check(ok, "6.5 BaseLevel door blocked: no key -> _door_triggered stays false")

func _test_6_door_ignores_non_actor() -> void:
	# 非 actor 触发 → 不算
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var fake: Node3D = Node3D.new()
	add_child(fake)
	inst._handle_door_body_entered(fake)
	var ok: bool = not inst._door_triggered
	fake.queue_free()
	inst.queue_free()
	_check(ok, "6.6 door template: non-actor body ignored")

func _test_7_item_sine_formula() -> void:
	# 锁住 level_03_item.gd 公式契约：target_x = home_x + sin(t*freq*TAU+phase) * amplitude
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	# 锁住 level._physics_process 不再 tick timeline，否则它会覆盖我们设的 current_time
	inst._game_over = true
	var item: RigidBody3D = inst.get_node("Item1")
	var tl: Timeline = inst.get_node("ItemTimeline")
	# Item1 params: home_x=-4, home_y=-0.2, home_z=0, amp=4, freq=0.12, phase=0
	var test_times: Array = [0.0, 1.0, 2.0, 4.0]
	for t in test_times:
		tl.current_time = t
		# 等两帧让 item._physics_process 读新 current_time（第一帧可能还在用上一帧的）
		await get_tree().physics_frame
		await get_tree().physics_frame
		var expected_x: float = item.home_x + sin(t * item.frequency_hz * TAU + item.phase) * item.amplitude
		var actual_x: float = item.global_position.x
		var delta: float = absf(actual_x - expected_x)
		if delta > 0.01:
			inst.queue_free()
			_check(false, "7.1 item sine formula at t=%.1f: expected x=%.3f got %.3f (delta=%.3f)" % [t, expected_x, actual_x, delta])
			return
	inst.queue_free()
	_check(true, "7.1 item sine formula: 4 sample points all within 0.01 of formula")

func _check(ok: bool, name: String) -> void:
	if ok:
		_passes += 1
		print("[PASS] " + name)
	else:
		_failures.append(name)
		printerr("[FAIL] " + name)

func _print_summary_and_quit() -> void:
	print("---")
	print("PASS: %d  FAIL: %d" % [_passes, _failures.size()])
	if _failures.size() > 0:
		for f in _failures:
			print("  - " + f)
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)

func _test_5_l03_pause_freezes_timeline() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	# 等 actor 落地稳定
	for i in range(30):
		await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3.ZERO
	inst._item_paused = true
	for i in range(5):
		await get_tree().physics_frame
	actor.velocity = Vector3.ZERO  # 防止滑动 + 强制保持静止
	var t0: float = inst._item_timeline.current_time
	for i in range(30):
		await get_tree().physics_frame
		actor.velocity = Vector3.ZERO
	var t1: float = inst._item_timeline.current_time
	var delta: float = t1 - t0
	var ok: bool = delta < 0.05  # 允许极小数值漂移
	inst.queue_free()
	_check(ok, "5.1 L03 paused + actor idle: timeline frozen (delta=%.3f)" % delta)

func _test_5_l03_unpause_advances_timeline() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in range(10):
		await get_tree().physics_frame
	var t0: float = inst._item_timeline.current_time
	inst._item_paused = false  # 显式确认
	for i in range(30):
		await get_tree().physics_frame
	var t1: float = inst._item_timeline.current_time
	var delta: float = t1 - t0
	var ok: bool = delta > 0.3  # 30 帧 ~0.5s
	inst.queue_free()
	_check(ok, "5.2 L03 unpaused: timeline advanced (delta=%.3f)" % delta)

func _test_5_l03_carry_actor_follows_platform() -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var item1: RigidBody3D = inst.get_node("Item1")
	# 把 actor 放到 item1 正上方贴近 item top（item 顶面 y=0，actor 半高 0.8 → 中心 y=0.8，ray 0.9→0.2 命中 item）
	# 注：item 顶面 y=0，actor center 必须 ≤ 0.6 才能让 ray (center+0.1 → center-0.6) 触及 item top；
	# 但那会和 item 碰撞穿插。改用直接 teleport 到 y=0.5（轻微穿插，BoxShape 容差通常允许），并停 physics 1 帧后再调用 carry。
	actor.global_position = Vector3(item1.global_position.x, 0.5, item1.global_position.z)
	actor.velocity = Vector3.ZERO
	# 不 await physics_frame，避免 level_03._physics_process 跑掉、重置 _riding_platform 并把 actor 顶飞
	# 直接进入测试
	inst._riding_platform = item1
	inst._riding_last_x = item1.global_position.x - 0.5
	var actor_x0: float = actor.global_position.x
	inst._carry_actor_on_platform()
	var actor_x1: float = actor.global_position.x
	var dx: float = actor_x1 - actor_x0
	var ok: bool = absf(dx - 0.5) < 0.01
	inst.queue_free()
	_check(ok, "5.3 L03 carry: actor.x +=0.5 to follow platform (actual dx=%.3f)" % dx)

func _test_5_l02_key_pickup_sets_flag() -> void:
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var has_key_before: bool = inst._has_key
	inst._on_key_entered(actor)
	var has_key_after: bool = inst._has_key
	var ok: bool = (not has_key_before) and has_key_after
	inst.queue_free()
	_check(ok, "5.4 L02 _on_key_entered(actor) sets _has_key true")

func _test_5_l02_door_locked_without_key() -> void:
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	inst._has_key = false
	var triggered_before: bool = inst._door_triggered
	inst._handle_door_body_entered(actor)
	var triggered_after: bool = inst._door_triggered
	# 没 key 时 door 应只显示 tip 不切场景。_door_triggered 应保持 false
	var ok: bool = (not triggered_before) and (not triggered_after)
	inst.queue_free()
	_check(ok, "5.5 L02 door no-key: _door_triggered stays false")

func _test_6_tick_timeline_advance() -> void:
	# 构造 Timeline，input_active=true → 调用 _tick_timeline → current_time 推进
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	add_child(tl)
	var packed := load("res://world.tscn")
	var level = packed.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var freeze_calls := [0]
	var advance_calls := [0]
	level._tick_timeline(
		tl, 0.1, true,
		func(_f): freeze_calls[0] += 1,
		func(): advance_calls[0] += 1,
		func(): return false,
		func(): pass,
	)
	var ok: bool = tl.current_time > 0.0 and freeze_calls[0] >= 1 and advance_calls[0] == 1
	var ct: float = tl.current_time
	level.queue_free()
	tl.queue_free()
	_check(ok, "6.7 _tick_timeline ADVANCING: current_time=%.3f freeze_calls=%d advance_calls=%d" % [ct, freeze_calls[0], advance_calls[0]])

func _test_6_tick_timeline_idle_with_waiting() -> void:
	# waiting=true + input=false → IDLE → on_freeze(true)
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	add_child(tl)
	var packed := load("res://world.tscn")
	var level = packed.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var last_freeze := [false]
	level._tick_timeline(
		tl, 0.1, false,
		func(f): last_freeze[0] = f,
		func(): pass,
		func(): return true,
		func(): pass,
	)
	var ok: bool = last_freeze[0] == true
	level.queue_free()
	tl.queue_free()
	_check(ok, "6.8 _tick_timeline IDLE+waiting: on_freeze(true)")

func _test_6_tick_timeline_rewinding() -> void:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	add_child(tl)
	tl.current_time = 5.0
	tl.max_time = 5.0
	tl.rewind_held = true
	var packed := load("res://world.tscn")
	var level = packed.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var ct_before: float = tl.current_time
	level._tick_timeline(
		tl, 0.1, false,
		func(_f): pass,
		func(): pass,
		func(): return false,
		func(): pass,
	)
	var ct_after: float = tl.current_time
	var ok: bool = ct_after < ct_before
	level.queue_free()
	tl.queue_free()
	_check(ok, "6.9 _tick_timeline REWINDING: current_time %.3f -> %.3f" % [ct_before, ct_after])

func _test_5_world_waiting_freezes_actor() -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in range(5):
		await get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var waiting: bool = inst._waiting_for_input
	var frozen: bool = actor.time_controlled
	# 初始无输入 → waiting=true → time_controlled=true
	var ok: bool = waiting and frozen
	inst.queue_free()
	_check(ok, "5.6 World initial waiting_for_input gates actor freeze (waiting=%s frozen=%s)" % [str(waiting), str(frozen)])
