extends GdUnitTestSuite
## T01 — full determinism (GDD §12), with the same API as tools/sim.sh (SimRunner).
## This test is never removed or disabled (.claude/rules/testing.md).


func test_T01_full_determinism() -> void:
	var scenario := SimScenario.load_scenario(&"temple_01")
	var rules := SimScenario.load_rules()
	var strategy := SimStrategy.load_file("res://tools/strategies/s1_sciame_e_lame.json")

	var first := SimRunner.run(scenario, rules, strategy, 42)
	var second := SimRunner.run(scenario, rules, strategy, 42)

	assert_bool(first.has("error")).is_false()
	assert_str(first["state_hash"]).is_equal(second["state_hash"])
	assert_str(first["result"]).is_equal(second["result"])
	assert_str(first["reason"]).is_equal(second["reason"])
	assert_int(first["ticks"]).is_equal(second["ticks"])
