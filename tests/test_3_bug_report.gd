extends Node

const BugReportModule := preload("res://bug_report.gd")

func run_all(runner: Node) -> void:
	_test_3_dict_to_text_flat(runner)
	_test_3_dict_to_text_nested(runner)
	_test_3_dict_to_text_array_of_dicts(runner)
	_test_3_dict_to_text_array_of_primitives(runner)
	_test_3_dict_to_text_float_format(runner)
	await _test_3_dump_state_world(runner)
	await _test_3_dump_state_level_02(runner)
	await _test_3_dump_state_level_03(runner)

func _test_3_dict_to_text_flat(runner: Node) -> void:
	var d := {"a": 1, "b": "hello", "c": true}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("a: 1") and out.contains("b: hello") and out.contains("c: true")
	runner._check(ok, "3.1 flat dict")

func _test_3_dict_to_text_nested(runner: Node) -> void:
	var d := {"timeline": {"current": 1.5, "state": "IDLE"}}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("timeline:") and out.contains("  current: 1.500") and out.contains("  state: IDLE")
	runner._check(ok, "3.2 nested dict 2-space indent")

func _test_3_dict_to_text_array_of_dicts(runner: Node) -> void:
	var d := {"items": [{"x": 1}, {"x": 2}]}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("items:") and out.contains("- x: 1") and out.contains("- x: 2")
	runner._check(ok, "3.3 array of dicts with dash prefix")

func _test_3_dict_to_text_array_of_primitives(runner: Node) -> void:
	var d := {"nums": [1, 2, 3]}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("nums: [1, 2, 3]")
	runner._check(ok, "3.4 inline array of primitives")

func _test_3_dict_to_text_float_format(runner: Node) -> void:
	var d := {"v": 3.14159}
	var out := BugReportModule.dict_to_text(d)
	var ok := out.contains("v: 3.142")
	runner._check(ok, "3.5 float 3 decimals")

func _test_3_dump_state_world(runner: Node) -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var state: Dictionary = inst._dump_state()
	var ok := state.has("timeline") and state.has("actor") and state.has("pushbox") and state.has("camera") and state.has("flags")
	inst.queue_free()
	runner._check(ok, "3.6 world _dump_state has expected top keys")

func _test_3_dump_state_level_02(runner: Node) -> void:
	var packed := load("res://level_02.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var state: Dictionary = inst._dump_state()
	var ok := state.has("actor_timeline") and state.has("box_timeline") and state.has("actor") and state.has("pushbox") and state.has("flags")
	inst.queue_free()
	runner._check(ok, "3.7 level_02 _dump_state has expected top keys")

func _test_3_dump_state_level_03(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var state: Dictionary = inst._dump_state()
	var ok := state.has("item_timeline") and state.has("actor") and state.has("items") and state.has("flags")
	var items_arr: Array = state.get("items", [])
	ok = ok and items_arr.size() == 3
	inst.queue_free()
	runner._check(ok, "3.8 level_03 _dump_state has expected top keys + 3 items")
