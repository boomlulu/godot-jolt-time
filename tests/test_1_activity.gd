extends Node

func run_all(runner: Node) -> void:
	await _test_1_actor_idle_no_activity(runner)
	await _test_1_actor_high_velocity_active(runner)
	await _test_1_actor_airborne_active(runner)
	await _test_1_item_has_activity_false(runner)
	await _test_1_level_03_pause_makes_inactive(runner)
	await _test_1_level_03_unpause_makes_active(runner)

func _test_1_actor_idle_no_activity(runner: Node) -> void:
	# 用 level_03（actor 不受 waiting_for_input 门控冻结，能自然落地）
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	var actor: CharacterBody3D = inst.get_node("Actor")
	for i in range(30):
		await runner.get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	for i in range(5):
		await runner.get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	var ok: bool = not actor.has_activity()
	var on_floor: bool = actor.is_on_floor()
	inst.queue_free()
	runner._check(ok, "1.1 actor idle on floor has_activity=false (on_floor=%s)" % str(on_floor))

func _test_1_actor_high_velocity_active(runner: Node) -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3(5, 0, 0)
	var ok: bool = actor.has_activity()
	inst.queue_free()
	runner._check(ok, "1.2 actor velocity>0.05 has_activity=true")

func _test_1_actor_airborne_active(runner: Node) -> void:
	var packed := load("res://world.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.global_position.y = 50.0
	await runner.get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	var ok: bool = actor.has_activity()
	inst.queue_free()
	runner._check(ok, "1.3 actor airborne has_activity=true")

func _test_1_item_has_activity_false(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	await runner.get_tree().physics_frame
	var item: RigidBody3D = inst.get_node("Item1")
	var ok: bool = not item.has_activity()
	inst.queue_free()
	runner._check(ok, "1.4 level_03_item has_activity always false (KINEMATIC by-rule)")

func _test_1_level_03_pause_makes_inactive(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	for i in range(20):
		await runner.get_tree().physics_frame
	inst._item_paused = true
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3.ZERO
	for i in range(5):
		await runner.get_tree().physics_frame
	actor.velocity = Vector3.ZERO
	var active: bool = inst._is_input_active()
	var actor_active: bool = actor.has_activity()
	var on_floor: bool = actor.is_on_floor()
	inst.queue_free()
	runner._check(not active, "1.5 level_03 paused + actor idle => input_active=false (actor.has_activity=%s on_floor=%s)" % [str(actor_active), str(on_floor)])

func _test_1_level_03_unpause_makes_active(runner: Node) -> void:
	var packed := load("res://level_03.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	for i in range(20):
		await runner.get_tree().physics_frame
	inst._item_paused = false
	var actor: CharacterBody3D = inst.get_node("Actor")
	actor.velocity = Vector3.ZERO
	await runner.get_tree().physics_frame
	var active: bool = inst._is_input_active()
	inst.queue_free()
	runner._check(active, "1.6 level_03 unpaused (items by rule) => input_active=true")
