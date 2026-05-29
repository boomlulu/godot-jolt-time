extends Node

# 第五关：平台由 Timeline 驱动（自走 + 可回退 + 拖动）验证。
# 不变量：平台位置恒 == pos_at_time(current_time)（纯时间函数跟随时间轴）。
# 若 carry 失效或时间轴没驱动平台，下列子条件会暴露。

func run_all(runner: Node) -> void:
	await _test_17_platform_follows_timeline(runner)

func _test_17_platform_follows_timeline(runner: Node) -> void:
	var inst = load("res://level_05.tscn").instantiate()
	runner.add_child(inst)
	var tl: Timeline = inst.get_node("Timeline")
	var plat = inst.get_node("MovingPlatform")
	# 自走推进 ~120 帧
	for i in range(120):
		await runner.get_tree().physics_frame
	var t_fwd: float = tl.current_time
	var max_fwd: float = tl.max_time
	var pos_fwd: Vector3 = plat.global_position
	var advanced: bool = t_fwd > 1.0
	var track_ok_fwd: bool = plat.global_position.distance_to(inst._expected_platform_pos()) < 0.05
	# 回退 ~60 帧
	inst._rewind_held = true
	for i in range(60):
		await runner.get_tree().physics_frame
	var t_rew: float = tl.current_time
	var rewound: bool = t_rew < t_fwd - 0.3
	var max_kept: bool = absf(tl.max_time - max_fwd) < 0.001
	var track_ok_rew: bool = plat.global_position.distance_to(inst._expected_platform_pos()) < 0.05
	var plat_moved_back: bool = plat.global_position.distance_to(pos_fwd) > 0.1
	inst._rewind_held = false
	# 拖动 seek（dragging 期间 level 不 advance）
	tl.set_dragging(true)
	tl.seek(max_fwd * 0.5)
	await runner.get_tree().physics_frame
	var seek_applied: bool = absf(tl.current_time - max_fwd * 0.5) < 0.15
	var track_ok_seek: bool = plat.global_position.distance_to(inst._expected_platform_pos()) < 0.05
	tl.set_dragging(false)
	var ok: bool = advanced and track_ok_fwd and rewound and max_kept and track_ok_rew and plat_moved_back and seek_applied and track_ok_seek
	inst.queue_free()
	runner._check(ok, "17.1 L05 platform follows timeline (adv=%s trkF=%s rew=%s(%.2f->%.2f) maxKept=%s trkR=%s movedBack=%s seek=%s trkS=%s)" % [advanced, track_ok_fwd, rewound, t_fwd, t_rew, max_kept, track_ok_rew, plat_moved_back, seek_applied, track_ok_seek])
