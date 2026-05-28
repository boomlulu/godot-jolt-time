extends Node

const LevelConfigCls := preload("res://level_config.gd")

func run_all(runner: Node) -> void:
	_test_15_config_class_loadable(runner)
	_test_15_config_default_values(runner)
	_test_15_world_tres_loads(runner)
	_test_15_level_02_tres_loads(runner)
	_test_15_level_03_tres_loads(runner)
	_test_15_all_tres_have_display_name(runner)

func _test_15_config_class_loadable(runner: Node) -> void:
	var c = LevelConfigCls.new()
	runner._check(c != null, "15.1 LevelConfig class instantiates")

func _test_15_config_default_values(runner: Node) -> void:
	var c = LevelConfigCls.new()
	var ok: bool = (
		absf(c.timer_duration - 10.0) < 0.001
		and absf(c.timescale - 1.0) < 0.001
		and absf(c.actor_speed - 5.0) < 0.001
		and c.gravity_vector == Vector3(0, -18, 0)
	)
	runner._check(ok, "15.2 LevelConfig defaults: timer=10 scale=1 speed=5 g=(0,-18,0)")

func _test_15_world_tres_loads(runner: Node) -> void:
	var c = load("res://config/level_world.tres")
	var ok: bool = c != null and c.display_name == "新手引导" and c.next_scene == "res://level_02.tscn"
	runner._check(ok, "15.3 level_world.tres loads with expected display_name + next_scene")

func _test_15_level_02_tres_loads(runner: Node) -> void:
	var c = load("res://config/level_02.tres")
	var ok: bool = c != null and c.display_name == "第二关·钥匙" and c.next_scene == "res://level_03.tscn"
	runner._check(ok, "15.4 level_02.tres loads")

func _test_15_level_03_tres_loads(runner: Node) -> void:
	var c = load("res://config/level_03.tres")
	var ok: bool = (
		c != null
		and c.display_name == "第三关"
		and absf(c.timer_duration - 20.0) < 0.001  # level_03 是 20s
		and absf(c.fall_death_y - (-5.0)) < 0.001
	)
	runner._check(ok, "15.5 level_03.tres loads with timer=20 fall=-5")

func _test_15_all_tres_have_display_name(runner: Node) -> void:
	var paths := ["res://config/level_world.tres", "res://config/level_02.tres", "res://config/level_03.tres"]
	for p in paths:
		var c = load(p)
		if c == null or c.display_name.is_empty():
			runner._check(false, "15.6 missing display_name in %s" % p)
			return
	runner._check(true, "15.6 all 3 LevelConfig .tres have display_name set")
