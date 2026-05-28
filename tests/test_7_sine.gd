extends Node

func run_all(runner: Node) -> void:
	await _test_7_item_sine_formula(runner)

func _test_7_item_sine_formula(runner: Node) -> void:
	# 锁住 level_03_item.gd 公式契约：target_x = home_x + sin(t*freq*TAU+phase) * amplitude
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	# 锁住 level._physics_process 不再 tick timeline，否则它会覆盖我们设的 current_time
	inst._game_over = true
	var item: RigidBody3D = inst.get_node("Item1")
	var tl: Timeline = inst.get_node("ItemTimeline")
	# Item1 params: home_x=-4, home_y=-0.2, home_z=0, amp=4, freq=0.12, phase=0
	var test_times: Array = [0.0, 1.0, 2.0, 4.0]
	for t in test_times:
		tl.current_time = t
		# 等两帧让 item._physics_process 读新 current_time（第一帧可能还在用上一帧的）
		await runner.get_tree().physics_frame
		await runner.get_tree().physics_frame
		var expected_x: float = item.home_x + sin(t * item.frequency_hz * TAU + item.phase) * item.amplitude
		var actual_x: float = item.global_position.x
		var delta: float = absf(actual_x - expected_x)
		if delta > 0.01:
			inst.queue_free()
			runner._check(false, "7.1 item sine formula at t=%.1f: expected x=%.3f got %.3f (delta=%.3f)" % [t, expected_x, actual_x, delta])
			return
	inst.queue_free()
	runner._check(true, "7.1 item sine formula: 4 sample points all within 0.01 of formula")
