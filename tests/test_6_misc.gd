extends Node

const LevelsRegistry := preload("res://levels_registry.gd")

func run_all(runner: Node) -> void:
	await _test_6_levels_registry_single_source(runner)
	_test_6_motion_epsilon_constant(runner)
	await _test_6_pushbox_has_activity(runner)
	await _test_6_door_triggered_template(runner)
	await _test_6_door_blocked_without_key(runner)
	await _test_6_door_ignores_non_actor(runner)
	await _test_6_tick_timeline_advance(runner)
	await _test_6_tick_timeline_idle_with_waiting(runner)
	await _test_6_tick_timeline_rewinding(runner)

func _test_6_levels_registry_single_source(runner: Node) -> void:
	# 注册表有 5 项（含第五关·平台时间轴）
	var registry_size: int = LevelsRegistry.ALL.size()
	if registry_size != 5:
		runner._check(false, "6.1 registry size expected 5 got %d" % registry_size)
		return
	# 三关 _get_levels() 返同一引用 / 同内容
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		var levels: Array = inst._get_levels()
		var same: bool = levels == LevelsRegistry.ALL
		inst.queue_free()
		if not same:
			runner._check(false, "6.1 %s _get_levels != LevelsRegistry.ALL" % p)
			return
	runner._check(true, "6.1 LevelsRegistry single source: 5 entries, all levels match")

func _test_6_motion_epsilon_constant(runner: Node) -> void:
	# 常量定义在 Rewindable，值为 0.05
	var v: float = Rewindable.MOTION_EPSILON
	var ok: bool = absf(v - 0.05) < 0.0001
	runner._check(ok, "6.2 Rewindable.MOTION_EPSILON = 0.05 (got %.4f)" % v)

func _test_6_pushbox_has_activity(runner: Node) -> void:
	# world 和 level_02 的 PushBox 应该挂 physics_box.gd 并有 has_activity 方法
	var paths := ["res://world.tscn", "res://level_02.tscn"]
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		var pb: Node = inst.get_node("PushBox")
		var has_method_ok: bool = pb.has_method("has_activity")
		# 初始静止 → has_activity false
		var inactive: bool = not pb.has_activity()
		# 强行设速度 → has_activity true
		(pb as RigidBody3D).linear_velocity = Vector3(2, 0, 0)
		var active: bool = pb.has_activity()
		inst.queue_free()
		if not (has_method_ok and inactive and active):
			runner._check(false, "6.3 %s PushBox.has_activity (method=%s inactive=%s active=%s)" % [p, str(has_method_ok), str(inactive), str(active)])
			return
	runner._check(true, "6.3 PushBox has_activity() works for world + level_02")

func _test_6_door_triggered_template(runner: Node) -> void:
	# 用 level_03 测，_on_door_passed=_trigger_win 不切场景，更安全
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var before: bool = inst._door_triggered
	inst._handle_door_body_entered(actor)
	var after: bool = inst._door_triggered
	var won: bool = inst._won
	inst.queue_free()
	# _trigger_win 会 pause，手动清掉
	runner.get_tree().paused = false
	var ok: bool = (not before) and after and won
	runner._check(ok, "6.4 BaseLevel door template: door pass triggers _on_door_passed (l03 win)")

func _test_6_door_blocked_without_key(runner: Node) -> void:
	# level_02 没 key 时 door blocked，_door_triggered 保持 false
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	inst._has_key = false
	inst._handle_door_body_entered(actor)
	var ok: bool = not inst._door_triggered
	inst.queue_free()
	runner._check(ok, "6.5 BaseLevel door blocked: no key -> _door_triggered stays false")

func _test_6_door_ignores_non_actor(runner: Node) -> void:
	# 非 actor 触发 → 不算
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var fake: Node3D = Node3D.new()
	runner.add_child(fake)
	inst._handle_door_body_entered(fake)
	var ok: bool = not inst._door_triggered
	fake.queue_free()
	inst.queue_free()
	runner._check(ok, "6.6 door template: non-actor body ignored")

func _test_6_tick_timeline_advance(runner: Node) -> void:
	# 构造 Timeline，input_active=true → 调用 _tick_timeline → current_time 推进
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	runner.add_child(tl)
	var packed := load("res://world.tscn")
	var level = packed.instantiate()
	runner.add_child(level)
	await runner.get_tree().physics_frame
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
	runner._check(ok, "6.7 _tick_timeline ADVANCING: current_time=%.3f freeze_calls=%d advance_calls=%d" % [ct, freeze_calls[0], advance_calls[0]])

func _test_6_tick_timeline_idle_with_waiting(runner: Node) -> void:
	# waiting=true + input=false → IDLE → on_freeze(true)
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	runner.add_child(tl)
	var packed := load("res://world.tscn")
	var level = packed.instantiate()
	runner.add_child(level)
	await runner.get_tree().physics_frame
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
	runner._check(ok, "6.8 _tick_timeline IDLE+waiting: on_freeze(true)")

func _test_6_tick_timeline_rewinding(runner: Node) -> void:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	runner.add_child(tl)
	tl.current_time = 5.0
	tl.max_time = 5.0
	tl.rewind_held = true
	var packed := load("res://world.tscn")
	var level = packed.instantiate()
	runner.add_child(level)
	await runner.get_tree().physics_frame
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
	runner._check(ok, "6.9 _tick_timeline REWINDING: current_time %.3f -> %.3f" % [ct_before, ct_after])
