class_name DeploymentPlan
extends RefCounted
## The player's purchases and placements (GDD §2, §7, §11): entries {type, cell, guard} in buy order.

## Rounding guard for float costs such as 1900 × 1.1 = 2090.0000000000002. Precision, not a game number.
const COST_PRECISION: float = 0.000001

var entries: Array[Dictionary] = []


func add(unit_type: StringName, cell: Vector2i, guard: bool = false) -> void:
	entries.append({"type": unit_type, "cell": cell, "guard": guard})


## Removes the last unit placed on `cell`. False if there is none.
func remove_at(cell: Vector2i) -> bool:
	for i: int in range(entries.size() - 1, -1, -1):
		if entries[i]["cell"] == cell:
			entries.remove_at(i)
			return true
	return false


## Cost of one unit; a guard pays ceil(cost × (1 + GUARD_COST_RATIO)) (GDD §7).
static func unit_cost(unit_type: StringName, guard: bool, rules: RulesData) -> int:
	var cost := SimScenario.unit_data(unit_type).cost
	if not guard:
		return cost
	return ceili(snappedf(cost * (1.0 + rules.guard_cost_ratio), COST_PRECISION))


func cost(rules: RulesData) -> int:
	var total: int = 0
	for entry: Dictionary in entries:
		total += unit_cost(entry["type"], entry["guard"], rules)
	return total


## Why one more unit cannot go on `cell` now; "" if it can.
func placement_error(scenario: ScenarioData, fog: SimFog, world: World, unit_type: StringName,
		cell: Vector2i, guard: bool) -> String:
	if cost(fog.rules) + unit_cost(unit_type, guard, fog.rules) > scenario.budget:
		return "over budget"
	return _unit_error(scenario, fog, world, unit_type, cell, guard)


## Validation of a whole plan (GDD §11): budget with guard surcharges, unit types, walkable,
## visible cells without enemies, guards only on rational units. "" if valid.
func validation_error(scenario: ScenarioData, fog: SimFog, world: World) -> String:
	if cost(fog.rules) > scenario.budget:
		return "cost %d over budget %d" % [cost(fog.rules), scenario.budget]
	for entry: Dictionary in entries:
		var error := _unit_error(scenario, fog, world, entry["type"], entry["cell"], entry["guard"])
		if not error.is_empty():
			return error
	return ""


func _unit_error(scenario: ScenarioData, fog: SimFog, world: World, unit_type: StringName,
		cell: Vector2i, guard: bool) -> String:
	if not unit_type in scenario.player_units:
		return "unit type '%s' is not available" % unit_type
	if guard and not SimScenario.unit_data(unit_type).rational:
		return "unit type '%s' is not rational and cannot guard" % unit_type
	if not fog.map.is_walkable(cell):
		return "cell %s is not walkable" % cell
	if not fog.is_visible(cell):
		return "cell %s is not visible" % cell
	if world.is_enemy_cell(cell, SimUnit.Faction.PLAYER):
		return "cell %s has an enemy" % cell
	return ""
