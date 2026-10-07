class_name SimScenario
extends RefCounted
## Builds a battle from a scenario (GDD §9): map, variants rolled with the world RNG
## (Blitz, then Hunt), enemies in ID order; later the player's units in plan order (§6.1).

const RULES_PATH: String = "res://data/rules.tres"


static func load_scenario(scenario_id: StringName) -> ScenarioData:
	return load("res://data/scenarios/%s.tres" % scenario_id) as ScenarioData


static func load_rules() -> RulesData:
	return load(RULES_PATH) as RulesData


static func unit_data(unit_type: StringName) -> UnitData:
	return load("res://data/units/%s.tres" % unit_type) as UnitData


## World before reconnaissance: variants rolled, enemies spawned, no player unit yet.
static func create_world(scenario: ScenarioData, rules: RulesData, seed_value: int) -> World:
	var world := World.new(rules, SimMap.load_from_file(scenario.map_path), seed_value)
	world.blitz_variant = _roll_variant(world.rng)
	world.hunt_variant = _roll_variant(world.rng)
	_spawn_group(world, scenario.group_entries(&"blitz", world.blitz_variant))
	_spawn_group(world, scenario.group_entries(&"hunt", world.hunt_variant))
	return world


## Tools and tests: a world with the enemies of a chosen variant combination, no roll.
static func create_world_with_variants(scenario: ScenarioData, rules: RulesData, blitz: String, hunt: String) -> World:
	var world := World.new(rules, SimMap.load_from_file(scenario.map_path), 0)
	world.blitz_variant = blitz
	world.hunt_variant = hunt
	_spawn_group(world, scenario.group_entries(&"blitz", blitz))
	_spawn_group(world, scenario.group_entries(&"hunt", hunt))
	return world


## "Via": the player's units enter the world in plan order.
static func deploy(world: World, plan: DeploymentPlan) -> void:
	for entry: Dictionary in plan.entries:
		var unit := world.spawn_unit(unit_data(entry["type"]), SimUnit.Faction.PLAYER, SimMap.cell_center(entry["cell"]))
		if entry["guard"]:
			# A guard's post is the relic, wherever it was deployed (GDD §7).
			unit.guard = true
			unit.home = world.map.relic_position()


static func _roll_variant(rng: RandomNumberGenerator) -> String:
	return "A" if rng.randi_range(0, 1) == 0 else "B"


static func _spawn_group(world: World, entries: Array) -> void:
	for entry: Array in entries:
		var cell := Vector2i(int(entry[1]), int(entry[2]))
		world.spawn_unit(unit_data(StringName(entry[0])), SimUnit.Faction.ENEMY, SimMap.cell_center(cell))
