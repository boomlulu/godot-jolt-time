extends Node

# 第四关移动平台原生 carry 稳定性测试（Jolt 后端实测）。
# actor 落到 AnimatableBody3D 平台后应被 move_and_slide 原生带着走，相对平台几乎零漂移。
# 若 carry 失效：平台滑走，相对漂移会达"米"级 → 本测试用 drift<0.2 判定"非常稳"。

func run_all(runner: Node) -> void:
	await _test_16_actor_glued_to_platform(runner)

func _test_16_actor_glued_to_platform(runner: Node) -> void:
	var packed := load("res://level_04.tscn")
	var inst = packed.instantiate()
	runner.add_child(inst)
	var actor: CharacterBody3D = inst.get_node("Actor")
	var platform: AnimatableBody3D = inst.get_node("MovingPlatform")
	# 落地 + 稳定（~90 帧 / 1.5s）
	for i in range(90):
		await runner.get_tree().physics_frame
	var landed: bool = actor.is_on_floor()
	var off0 := Vector2(
		actor.global_position.x - platform.global_position.x,
		actor.global_position.z - platform.global_position.z)
	var plat_start := platform.global_position
	# 平台继续 Lissajous 横移 120 帧（2s），玩家无输入 → 应被原生带着走
	var max_drift: float = 0.0
	var max_plat_move: float = 0.0
	var on_floor_frames: int = 0
	for i in range(120):
		await runner.get_tree().physics_frame
		if actor.is_on_floor():
			on_floor_frames += 1
		var off := Vector2(
			actor.global_position.x - platform.global_position.x,
			actor.global_position.z - platform.global_position.z)
		max_drift = maxf(max_drift, off.distance_to(off0))
		max_plat_move = maxf(max_plat_move, platform.global_position.distance_to(plat_start))
	var on_floor_ratio: float = float(on_floor_frames) / 120.0
	var ok: bool = landed and max_plat_move > 0.5 and max_drift < 0.2 and on_floor_ratio > 0.9
	inst.queue_free()
	runner._check(ok, "16.1 L04 actor glued to moving platform (landed=%s plat_move=%.2f drift=%.4f on_floor=%d pct)" % [landed, max_plat_move, max_drift, int(on_floor_ratio * 100.0)])
