extends Node

# GravityField + GravityManager 引力系统

func run_all(runner: Node) -> void:
	_test_11_default_gravity(runner)
	await _test_11_field_overrides_default(runner)
	await _test_11_priority(runner)
	await _test_11_falloff(runner)
	await _test_11_unregister_on_exit(runner)

func _test_11_default_gravity(runner: Node) -> void:
	# 没 field 时 → DEFAULT_GRAVITY
	var g: Vector3 = GravityManager.resolve_gravity(Vector3.ZERO)
	runner._assert_equal(g, Vector3(0, -18, 0), "11.1 default gravity (0,-18,0) when no field")

func _test_11_field_overrides_default(runner: Node) -> void:
	var f = load("res://gravity_field.gd").new()
	f.gravity_vector = Vector3.UP * 5.0
	f.falloff_radius = 0.0  # 全场
	f.field_priority = 1
	runner.add_child(f)
	await runner.get_tree().physics_frame
	var g: Vector3 = GravityManager.resolve_gravity(Vector3(100, 100, 100))
	f.queue_free()
	await runner.get_tree().physics_frame
	runner._assert_equal(g, Vector3.UP * 5.0, "11.2 GravityField overrides default")

func _test_11_priority(runner: Node) -> void:
	var lo = load("res://gravity_field.gd").new()
	lo.gravity_vector = Vector3.UP
	lo.field_priority = 0
	runner.add_child(lo)
	var hi = load("res://gravity_field.gd").new()
	hi.gravity_vector = Vector3.DOWN
	hi.field_priority = 10
	runner.add_child(hi)
	await runner.get_tree().physics_frame
	var g: Vector3 = GravityManager.resolve_gravity(Vector3.ZERO)
	lo.queue_free()
	hi.queue_free()
	await runner.get_tree().physics_frame
	runner._assert_equal(g, Vector3.DOWN, "11.3 priority: hi (10) overrides lo (0)")

func _test_11_falloff(runner: Node) -> void:
	# falloff_radius=10，距离 0 强度满 (-100)，距离 5 = 50% (-50)，距离 >=10 → field 不参与，回落默认 -18
	var f = load("res://gravity_field.gd").new()
	f.gravity_vector = Vector3(0, -100, 0)
	f.falloff_radius = 10.0
	f.field_priority = 1
	runner.add_child(f)
	await runner.get_tree().physics_frame
	var g_center: Vector3 = GravityManager.resolve_gravity(Vector3.ZERO)
	var g_mid: Vector3 = GravityManager.resolve_gravity(Vector3(5, 0, 0))
	var g_far: Vector3 = GravityManager.resolve_gravity(Vector3(15, 0, 0))
	f.queue_free()
	await runner.get_tree().physics_frame
	var ok: bool = (
		absf(g_center.y - (-100)) < 0.1
		and absf(g_mid.y - (-50)) < 0.1
		and absf(g_far.y - (-18)) < 0.1
	)
	runner._check(ok, "11.4 falloff: center=%.1f mid=%.1f far=%.1f" % [g_center.y, g_mid.y, g_far.y])

func _test_11_unregister_on_exit(runner: Node) -> void:
	var f = load("res://gravity_field.gd").new()
	f.gravity_vector = Vector3.UP * 99
	f.field_priority = 100
	runner.add_child(f)
	await runner.get_tree().physics_frame
	var g_with: Vector3 = GravityManager.resolve_gravity(Vector3.ZERO)
	runner.remove_child(f)
	f.free()
	await runner.get_tree().physics_frame
	var g_without: Vector3 = GravityManager.resolve_gravity(Vector3.ZERO)
	var ok: bool = g_with == Vector3.UP * 99 and g_without == Vector3(0, -18, 0)
	runner._check(ok, "11.5 GravityField unregisters on exit_tree")
