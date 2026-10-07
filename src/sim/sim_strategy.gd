class_name SimStrategy
extends RefCounted
## A strategy file (GDD §11): { name, description, reveals, units } or the same per variant
## combination under by_variant ("A-A", "A-B", "B-A", "B-B": Blitz variant, dash, Hunt variant).

var strategy_name: String = ""
var description: String = ""
var _plain: Dictionary = {}
var _by_variant: Dictionary = {}


## Null and an error pushed if the file is missing or malformed.
static func load_file(path: String) -> SimStrategy:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("SimStrategy: cannot parse '%s'" % path)
		return null
	var data: Dictionary = parsed
	var strategy := SimStrategy.new()
	strategy.strategy_name = data.get("name", path.get_file().get_basename())
	strategy.description = data.get("description", "")
	if data.has("by_variant"):
		strategy._by_variant = data["by_variant"]
	else:
		strategy._plain = data
	return strategy


## Reveal cells for the rolled combination.
func reveals_for(blitz: String, hunt: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for pair: Array in _section(blitz, hunt).get("reveals", []):
		cells.append(Vector2i(int(pair[0]), int(pair[1])))
	return cells


## Deployment plan for the rolled combination, units in file order.
func plan_for(blitz: String, hunt: String) -> DeploymentPlan:
	var plan := DeploymentPlan.new()
	for unit: Dictionary in _section(blitz, hunt).get("units", []):
		var cell: Array = unit["cell"]
		plan.add(StringName(unit["type"]), Vector2i(int(cell[0]), int(cell[1])), bool(unit.get("guard", false)))
	return plan


func _section(blitz: String, hunt: String) -> Dictionary:
	if _by_variant.is_empty():
		return _plain
	return _by_variant.get("%s-%s" % [blitz, hunt], {})
