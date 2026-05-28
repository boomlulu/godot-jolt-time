extends Node3D

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
