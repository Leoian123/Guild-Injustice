class_name UnitData
extends Resource
## Unit stats (GDD §7, §8). Shared and read-only at runtime: SimUnit copies from it.

@export var unit_type: StringName = &""
@export var max_hp: int = 0
