extends Node

const COMMON_CHILDREN := [
	"Joystick",
	"ExitButton",
	"BugReportButton",
	"TimerLabel",
	"TipsLabel",
	"GameOverDialog",
	"GMPanel",
]

func run_all(runner: Node) -> void:
	await _test_14_hud_base_loads(runner)
	await _test_14_hud_base_has_common_children(runner)
	await _test_14_levels_have_hud_base(runner)
	await _test_14_base_refs_resolve(runner)

func _test_14_hud_base_loads(runner: Node) -> void:
	var packed := load("res://hud_base.tscn")
	var ok: bool = packed != null
	if ok:
		var inst = packed.instantiate()
		ok = inst != null
		if inst != null:
			inst.queue_free()
	runner._check(ok, "14.1 hud_base.tscn loads")

func _test_14_hud_base_has_common_children(runner: Node) -> void:
	var packed := load("res://hud_base.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var missing: Array = []
	for child_name in COMMON_CHILDREN:
		if not inst.has_node(child_name):
			missing.append(child_name)
	inst.queue_free()
	var ok: bool = missing.is_empty()
	runner._check(ok, "14.2 hud_base has 7 common children (missing=%s)" % str(missing))

func _test_14_levels_have_hud_base(runner: Node) -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	var missing_paths: Array = []
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		if not inst.has_node("HUD/HUDBase"):
			all_ok = false
			missing_paths.append(p)
		inst.queue_free()
	runner._check(all_ok, "14.3 all 3 levels have HUD/HUDBase instance (missing=%s)" % str(missing_paths))

func _test_14_base_refs_resolve(runner: Node) -> void:
	# 验证 BaseLevel 的 _gm_panel / _hud_bug / _hud_exit 通过 HUDBase 可访问
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		var gm_ok: bool = inst._gm_panel != null and inst._gm_panel.has_method("set_levels")
		var bug_ok: bool = inst._hud_bug != null and inst._hud_bug is Button
		var exit_ok: bool = inst._hud_exit != null and inst._hud_exit is Button
		if not (gm_ok and bug_ok and exit_ok):
			all_ok = false
		inst.queue_free()
	runner._check(all_ok, "14.4 BaseLevel _gm_panel/_hud_bug/_hud_exit resolve via HUDBase on all 3 levels")
