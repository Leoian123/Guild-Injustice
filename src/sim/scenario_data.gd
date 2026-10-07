class_name ScenarioData
extends Resource
## A scenario (GDD §9): map, budget, enemy variants. Values live in data/scenarios/.
## Enemy entries are [unit_type, x, y], in ID assignment order.

@export var scenario_id: StringName = &""
@export var map_path: String = ""
@export var budget: int = 0
## Unit types the player can buy (GDD §7).
@export var player_units: Array[StringName] = []
## Blitz group (`blitz`), variants A and B.
@export var blitz_a: Array = []
@export var blitz_b: Array = []
## Hunt group (`hunt`), variants A and B.
@export var hunt_a: Array = []
@export var hunt_b: Array = []
## The room of the relic (GDD §4): guards hold it (GDD §7).
@export var relic_room: Rect2i = Rect2i()
## Cells of the generic threat markers shown in the fog (GDD §5.1).
@export var threat_markers: Array[Vector2i] = []


## The enemy entries of one group variant: group "blitz" or "hunt", variant "A" or "B".
func group_entries(group: StringName, variant: String) -> Array:
	if group == &"blitz":
		return blitz_a if variant == "A" else blitz_b
	return hunt_a if variant == "A" else hunt_b
