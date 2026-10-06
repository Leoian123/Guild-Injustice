class_name UnitData
extends Resource
## Unit stats (GDD §7, §8). Shared and read-only at runtime: SimUnit copies from it.

@export var unit_type: StringName = &""
@export var cost: int = 0
@export var max_hp: int = 0
@export var damage: int = 0
## Seconds between attacks.
@export var attack_interval: float = 0.0
## Cells.
@export var attack_range: float = 0.0
## Cells per second.
@export var speed: float = 0.0
## Cells.
@export var engage_radius: float = 0.0


## Seconds to ticks: round(seconds × tick rate), at least 1 (GDD §6.1).
static func seconds_to_ticks(seconds: float, tick_rate: int) -> int:
	return maxi(1, roundi(seconds * tick_rate))
