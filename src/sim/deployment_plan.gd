class_name DeploymentPlan
extends RefCounted
## The player's purchases and placements (GDD §2, §11): entries {type, cell} in buy order.

var entries: Array[Dictionary] = []


func add(unit_type: StringName, cell: Vector2i) -> void:
	entries.append({"type": unit_type, "cell": cell})


## Removes the last unit placed on `cell`. False if there is none.
func remove_at(cell: Vector2i) -> bool:
	for i: int in range(entries.size() - 1, -1, -1):
		if entries[i]["cell"] == cell:
			entries.remove_at(i)
			return true
	return false


func cost() -> int:
	var total: int = 0
	for entry: Dictionary in entries:
		total += SimScenario.unit_data(entry["type"]).cost
	return total


## Why a unit of `unit_type` cannot go on `cell` now; "" if it can.
func placement_error(scenario: ScenarioData, fog: SimFog, unit_type: StringName, cell: Vector2i) -> String:
	if not unit_type in scenario.player_units:
		return "unit type '%s' is not available" % unit_type
	if cost() + SimScenario.unit_data(unit_type).cost > scenario.budget:
		return "over budget"
	if not fog.map.is_walkable(cell):
		return "cell %s is not walkable" % cell
	if not fog.is_visible(cell):
		return "cell %s is not visible" % cell
	return ""


## Validation of a whole plan (GDD §11): budget, unit types, walkable and visible cells. "" if valid.
func validation_error(scenario: ScenarioData, fog: SimFog) -> String:
	if cost() > scenario.budget:
		return "cost %d over budget %d" % [cost(), scenario.budget]
	for entry: Dictionary in entries:
		var cell: Vector2i = entry["cell"]
		if not entry["type"] in scenario.player_units:
			return "unit type '%s' is not available" % entry["type"]
		if not fog.map.is_walkable(cell):
			return "cell %s is not walkable" % cell
		if not fog.is_visible(cell):
			return "cell %s is not visible" % cell
	return ""
