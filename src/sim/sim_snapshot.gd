class_name SimSnapshot
extends RefCounted
## Frozen copy of positions, facings and HP for the attack phase (GDD §6.2, phase 4).
## Indexed like World.units (index = id - 1).

var positions: PackedVector2Array = PackedVector2Array()
var facings: PackedVector2Array = PackedVector2Array()
var hps: PackedInt32Array = PackedInt32Array()
var alive: Array[bool] = []
var factions: Array[SimUnit.Faction] = []
var types: Array[StringName] = []


func _init(units: Array[SimUnit]) -> void:
	for unit: SimUnit in units:
		positions.append(unit.position)
		facings.append(unit.facing)
		hps.append(unit.hp)
		alive.append(unit.is_alive() and unit.hp > 0)
		factions.append(unit.faction)
		types.append(unit.unit_type)


func size() -> int:
	return positions.size()


func position_of(unit_id: int) -> Vector2:
	return positions[unit_id - 1]


func facing_of(unit_id: int) -> Vector2:
	return facings[unit_id - 1]


func is_alive(unit_id: int) -> bool:
	return alive[unit_id - 1]
