extends Node

func run_all(runner: Node) -> void:
	_test_8_assert_helpers_pass_paths(runner)

func _test_8_assert_helpers_pass_paths(runner: Node) -> void:
	# self-test: assert_equal / assert_near 在 happy path 都通过
	# 用一个临时局部计数代替 _passes（避免污染主计数）
	var before_pass: int = runner._passes
	var before_fail: int = runner._failures.size()
	runner._assert_equal(1 + 1, 2, "8.1a assert_equal int")
	runner._assert_equal("foo", "foo", "8.1b assert_equal str")
	runner._assert_near(0.1 + 0.2, 0.3, 0.0001, "8.1c assert_near float")
	# 3 个都应该 pass
	var pass_added: int = runner._passes - before_pass
	var fail_added: int = runner._failures.size() - before_fail
	runner._check(pass_added == 3 and fail_added == 0,
		"8.1 assert helpers happy paths: %d passes / %d fails added (expected 3/0)" % [pass_added, fail_added])
