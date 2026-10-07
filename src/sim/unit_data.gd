class_name UnitData
extends Resource
## Unit stats (GDD §7, §8). Shared and read-only at runtime: SimUnit copies from it.

const MELEE: StringName = &"melee"
const RANGED: StringName = &"ranged"

@export var unit_type: StringName = &""
@export var cost: int = 0
@export var max_hp: int = 0
@export var damage: int = 0
## Seconds between attacks.
@export var attack_interval: float = 0.0
## Cells.
@export var attack_range: float = 0.0
## Attack type (GDD §6.5), independent of the range: MELEE or RANGED.
@export var attack_kind: StringName = MELEE
## Cells per second.
@export var speed: float = 0.0
## Cells.
@export var engage_radius: float = 0.0
## Cells from the deployment point a HoldGroundWill unit dares to chase (GDD §6.8).
@export var chase_radius: float = 0.0
## Will component name (GDD §6.8): HoldGroundWill, HungerWill or NecroBoundWill.
@export var will: StringName = &""
## Only rational units take orders, such as guard duty (GDD §7).
@export var rational: bool = false
## Ability component names (GDD §7, §8).
@export var abilities: Array[StringName] = []


## Seconds to ticks: round(seconds × tick rate), at least 1 (GDD §6.1).
static func seconds_to_ticks(seconds: float, tick_rate: int) -> int:
	return maxi(1, roundi(seconds * tick_rate))
