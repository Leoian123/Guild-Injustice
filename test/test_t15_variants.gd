extends GdUnitTestSuite
## T15 — scenario variants (GDD §9), plus a check that the reference strategies are valid.


func test_T15_variants() -> void:
	var scenario := SimScenario.load_scenario(&"temple_01")
	var rules := SimScenario.load_rules()
	var seen: Dictionary = {}
	for seed_value: int in range(1, 41):
		var first := SimScenario.create_world(scenario, rules, seed_value)
		var again := SimScenario.create_world(scenario, rules, seed_value)
		var combination := "%s-%s" % [first.blitz_variant, first.hunt_variant]
		assert_str("%s-%s" % [again.blitz_variant, again.hunt_variant]).is_equal(combination)
		seen[combination] = true
	assert_array(seen.keys()).contains_exactly_in_any_order(["A-A", "A-B", "B-A", "B-B"])


# Not a rule test: the strategies in tools/strategies must pass the §11 validation
# (budget, at most REVEALS reveals, walkable and visible cells) for every combination.
func test_reference_strategies_are_valid() -> void:
	var scenario := SimScenario.load_scenario(&"temple_01")
	var rules := SimScenario.load_rules()
	var map := SimMap.load_from_file(scenario.map_path)
	for file: String in DirAccess.get_files_at("res://tools/strategies"):
		if not file.ends_with(".json"):
			continue
		var strategy := SimStrategy.load_file("res://tools/strategies/" + file)
		assert_object(strategy).is_not_null()
		for blitz: String in ["A", "B"]:
			for hunt: String in ["A", "B"]:
				var fog := SimFog.new(map, rules)
				var reveals := strategy.reveals_for(blitz, hunt)
				assert_int(reveals.size()).override_failure_message("%s %s-%s: too many reveals" % [file, blitz, hunt]) \
					.is_less_equal(rules.reveals)
				for cell: Vector2i in reveals:
					fog.reveal(cell)
				var plan := strategy.plan_for(blitz, hunt)
				assert_array(plan.entries).override_failure_message("%s %s-%s: no units" % [file, blitz, hunt]).is_not_empty()
				assert_str(plan.validation_error(scenario, fog)) \
					.override_failure_message("%s %s-%s: %s" % [file, blitz, hunt, plan.validation_error(scenario, fog)]) \
					.is_empty()
