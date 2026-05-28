extends Node

func run_all(runner: Node) -> void:
	await _test_4_gm_panel_loads(runner)
	await _test_4_gm_panel_populates_buttons(runner)
	await _test_4_gm_panel_emits_signal(runner)
	await _test_4_levels_have_gm_panel(runner)

func _test_4_gm_panel_loads(runner: Node) -> void:
	var packed := load("res://gm_panel.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var ok: bool = inst != null and inst.has_method("set_levels")
	inst.queue_free()
	runner._check(ok, "4.1 gm_panel.tscn loads and has set_levels()")

func _test_4_gm_panel_populates_buttons(runner: Node) -> void:
	var packed := load("res://gm_panel.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	inst.set_levels([
		{"name": "Test A", "scene": "res://a.tscn"},
		{"name": "Test B", "scene": "res://b.tscn"},
	])
	await runner.get_tree().physics_frame
	var level_buttons: VBoxContainer = inst.get_node("PanelOverlay/CenterBox/VBox/LevelButtons")
	var count: int = level_buttons.get_child_count()
	var ok: bool = count == 2
	inst.queue_free()
	runner._check(ok, "4.2 gm_panel set_levels populates %d buttons (expected 2)" % count)

func _test_4_gm_panel_emits_signal(runner: Node) -> void:
	var packed := load("res://gm_panel.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	inst.set_levels([{"name": "X", "scene": "res://x.tscn"}])
	await runner.get_tree().physics_frame
	var captured := [""]
	inst.level_chosen.connect(func(p): captured[0] = p)
	inst._on_level_pressed("res://x.tscn")
	var ok: bool = captured[0] == "res://x.tscn"
	inst.queue_free()
	runner._check(ok, "4.3 gm_panel emits level_chosen on level click")

func _test_4_levels_have_gm_panel(runner: Node) -> void:
	var paths := ["res://world.tscn", "res://level_02.tscn", "res://level_03.tscn"]
	var all_ok := true
	for p in paths:
		var packed = load(p)
		var inst = packed.instantiate()
		runner.add_child(inst)
		await runner.get_tree().physics_frame
		var has_gm: bool = inst.has_node("HUD/HUDBase/GMPanel")
		if not has_gm:
			all_ok = false
		var gm = inst.get_node_or_null("HUD/HUDBase/GMPanel")
		if gm != null:
			var level_buttons = gm.get_node_or_null("PanelOverlay/CenterBox/VBox/LevelButtons")
			if level_buttons == null or level_buttons.get_child_count() != 3:
				all_ok = false
		inst.queue_free()
	runner._check(all_ok, "4.4 all 3 levels have GMPanel instance with 3 populated buttons")
