class_name SimRunner
extends RefCounted
## One battle from scenario, strategy and seed, as tools/sim.sh runs it (GDD §11).
## Tests at the "Simulazione" level use this same API.


## The variant combination a seed rolls (GDD §9), without running the battle.
static func roll_variants(scenario: ScenarioData, rules: RulesData, seed_value: int) -> Dictionary:
	var world := SimScenario.create_world(scenario, rules, seed_value)
	return {"blitz": world.blitz_variant, "hunt": world.hunt_variant}


## World ready for "Via" with the strategy's reveals and units, or the validation error
## (GDD §11): {"world": World} or {"error": String}.
static func prepare(scenario: ScenarioData, rules: RulesData, strategy: SimStrategy, seed_value: int) -> Dictionary:
	var world := SimScenario.create_world(scenario, rules, seed_value)
	var combination := "%s-%s" % [world.blitz_variant, world.hunt_variant]
	var reveals := strategy.reveals_for(world.blitz_variant, world.hunt_variant)
	if reveals.size() > rules.reveals:
		return {"error": "%s: %d reveals, at most %d" % [combination, reveals.size(), rules.reveals]}
	var fog := SimFog.new(world.map, rules)
	for cell: Vector2i in reveals:
		if not fog.reveal(cell):
			return {"error": "%s: reveal %s outside the map" % [combination, cell]}
	var plan := strategy.plan_for(world.blitz_variant, world.hunt_variant)
	if plan.entries.is_empty():
		return {"error": "%s: no units" % combination}
	var error := plan.validation_error(scenario, fog, world)
	if not error.is_empty():
		return {"error": "%s: %s" % [combination, error]}
	SimScenario.deploy(world, plan)
	return {"world": world}


## Runs a prepared world to the end and returns the §11 result line.
static func run_to_end(world: World, scenario: ScenarioData, strategy: SimStrategy, seed_value: int) -> Dictionary:
	while not world.is_over():
		world.step()
	return result_of(world, scenario, strategy, seed_value)


## Prepare and run; {"error": …} if the strategy is not valid for this seed.
static func run(scenario: ScenarioData, rules: RulesData, strategy: SimStrategy, seed_value: int) -> Dictionary:
	var prepared := prepare(scenario, rules, strategy, seed_value)
	if prepared.has("error"):
		return prepared
	return run_to_end(prepared["world"], scenario, strategy, seed_value)


## The JSON object of GDD §11, keys in the documented order.
static func result_of(world: World, scenario: ScenarioData, strategy: SimStrategy, seed_value: int) -> Dictionary:
	var survivors: Dictionary = {"player": {}, "enemy": {}}
	for unit: SimUnit in world.units:
		if not unit.is_alive():
			continue
		var side: Dictionary = survivors["player" if unit.faction == SimUnit.Faction.PLAYER else "enemy"]
		var key := String(unit.unit_type)
		side[key] = side.get(key, 0) + 1
	return {
		"scenario": String(scenario.scenario_id),
		"strategy": strategy.strategy_name,
		"seed": seed_value,
		"variant": {"blitz": world.blitz_variant, "hunt": world.hunt_variant},
		"result": world.result,
		"reason": world.reason,
		"ticks": world.end_tick + 1,
		"survivors": survivors,
		"events": world.events,
		"state_hash": world.state_hash(),
	}
