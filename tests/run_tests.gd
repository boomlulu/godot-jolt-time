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
