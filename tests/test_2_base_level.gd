extends Node

func run_all(runner: Node) -> void:
	_test_2_base_level_class_registered(runner)
	await _test_2_levels_extend_base_level(runner)
	await _test_2_get_levels_returns_three(runner)
	await _test_2_state_name_translates(runner)
	await _test_2_base_handlers_present(runner)

func _test_2_base_level_class_registered(runner: Node) -> void:
	var ok: bool = ClassDB.class_exists("BaseLevel") or load("res://base_level.gd") != null
	runner._check(ok, "2.1 BaseLevel class loadable")

func _test_2_levels_extend_base_level(runner: Node) -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		var is_base: bool = inst is BaseLevel
		if not is_base:
			all_ok = false
		inst.queue_free()
	runner._check(all_ok, "2.2 all 3 levels extend BaseLevel")

func _test_2_get_levels_returns_three(runner: Node) -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		var levels: Array = inst._get_levels()
		if levels.size() != 4:
			all_ok = false
		inst.queue_free()
	runner._check(all_ok, "2.3 all levels _get_levels() returns 4 entries")

func _test_2_state_name_translates(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var ok: bool = (
		inst._state_name(Timeline.State.IDLE) == "IDLE"
		and inst._state_name(Timeline.State.ADVANCING) == "ADVANCING"
		and inst._state_name(Timeline.State.REWINDING) == "REWINDING"
		and inst._state_name(Timeline.State.DRAGGING) == "DRAGGING"
		and inst._state_name(Timeline.State.LOCKED) == "LOCKED"
		and inst._state_name(Timeline.State.GAME_OVER) == "GAME_OVER"
	)
	inst.queue_free()
	runner._check(ok, "2.4 _state_name maps all 6 enum values")

func _test_2_base_handlers_present(runner: Node) -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var ok: bool = (
		inst.has_method("_on_exit_pressed")
		and inst.has_method("_on_level_pressed")
		and inst.has_method("_on_bug_report")
	)
	inst.queue_free()
	runner._check(ok, "2.5 base handlers present on level instance")
