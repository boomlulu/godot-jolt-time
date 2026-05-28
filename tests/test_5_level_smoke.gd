extends Node

func run_all(runner: Node) -> void:
	await _test_5_l03_pause_freezes_timeline(runner)
	await _test_5_l03_unpause_advances_timeline(runner)
	await _test_5_l03_carry_actor_follows_platform(runner)
	await _test_5_l02_key_pickup_sets_flag(runner)
	await _test_5_l02_door_locked_without_key(runner)
	await _test_5_world_waiting_freezes_actor(runner)

func _test_5_l03_pause_freezes_timeline(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	# 等 actor 落地稳定
	for i in range(30):
		await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3.ZERO
	inst._item_paused = true
	for i in range(5):
		await runner.get_tree().physics_frame
	actor.velocity = Vector3.ZERO  # 防止滑动 + 强制保持静止
	var t0: float = inst._item_timeline.current_time
	for i in range(30):
		await runner.get_tree().physics_frame
		actor.velocity = Vector3.ZERO
	var t1: float = inst._item_timeline.current_time
	var delta: float = t1 - t0
	var ok: bool = delta < 0.05  # 允许极小数值漂移
	inst.queue_free()
	runner._check(ok, "5.1 L03 paused + actor idle: timeline frozen (delta=%.3f)" % delta)

func _test_5_l03_unpause_advances_timeline(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	for i in range(10):
		await runner.get_tree().physics_frame
	var t0: float = inst._item_timeline.current_time
	inst._item_paused = false  # 显式确认
	for i in range(30):
		await runner.get_tree().physics_frame
	var t1: float = inst._item_timeline.current_time
	var delta: float = t1 - t0
	var ok: bool = delta > 0.3  # 30 帧 ~0.5s
	inst.queue_free()
	runner._check(ok, "5.2 L03 unpaused: timeline advanced (delta=%.3f)" % delta)

func _test_5_l03_carry_actor_follows_platform(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
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
	runner._check(ok, "5.3 L03 carry: actor.x +=0.5 to follow platform (actual dx=%.3f)" % dx)

func _test_5_l02_key_pickup_sets_flag(runner: Node) -> void:
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var has_key_before: bool = inst._has_key
	inst._on_key_entered(actor)
	var has_key_after: bool = inst._has_key
	var ok: bool = (not has_key_before) and has_key_after
	inst.queue_free()
	runner._check(ok, "5.4 L02 _on_key_entered(actor) sets _has_key true")

func _test_5_l02_door_locked_without_key(runner: Node) -> void:
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	inst._has_key = false
	var triggered_before: bool = inst._door_triggered
	inst._handle_door_body_entered(actor)
	var triggered_after: bool = inst._door_triggered
	# 没 key 时 door 应只显示 tip 不切场景。_door_triggered 应保持 false
	var ok: bool = (not triggered_before) and (not triggered_after)
	inst.queue_free()
	runner._check(ok, "5.5 L02 door no-key: _door_triggered stays false")

func _test_5_world_waiting_freezes_actor(runner: Node) -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	for i in range(5):
		await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	var waiting: bool = inst._waiting_for_input
	var frozen: bool = actor.time_controlled
	# 初始无输入 → waiting=true → time_controlled=true
	var ok: bool = waiting and frozen
	inst.queue_free()
	runner._check(ok, "5.6 World initial waiting_for_input gates actor freeze (waiting=%s frozen=%s)" % [str(waiting), str(frozen)])
