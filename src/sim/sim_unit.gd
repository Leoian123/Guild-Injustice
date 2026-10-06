class_name SimUnit
extends RefCounted
## Runtime state of one unit. Values are copied from UnitData at creation.

enum Faction { PLAYER, ENEMY }
enum State { IDLE, MOVE, ATTACK, FLEE, DEAD }

const NO_TARGET: int = -1

var id: int = 0
var unit_type: StringName = &""
var faction: Faction = Faction.PLAYER
var state: State = State.IDLE
var hp: int = 0
var position: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.ZERO
var target_id: int = NO_TARGET
var attack_cd: int = 0

var max_hp: int = 0
var damage: int = 0
var attack_interval_ticks: int = 0
var attack_range: float = 0.0
## Cells per tick.
var speed_per_tick: float = 0.0
var engage_radius: float = 0.0

## Deployment point; player units return here without a target (GDD §6.6).
var home: Vector2 = Vector2.ZERO
## Tick of the last target computation (GDD §6.4).
var last_target_tick: int = 0

## Test mode (docs/TESTS.md): with AI off the unit only attacks forced_target_id.
var ai_enabled: bool = true
var forced_target_id: int = NO_TARGET


func _init(p_id: int, p_data: UnitData, p_faction: Faction, p_position: Vector2, tick_rate: int) -> void:
	id = p_id
	unit_type = p_data.unit_type
	faction = p_faction
	max_hp = p_data.max_hp
	hp = max_hp
	damage = p_data.damage
	attack_interval_ticks = UnitData.seconds_to_ticks(p_data.attack_interval, tick_rate)
	attack_range = p_data.attack_range
	speed_per_tick = p_data.speed / tick_rate
	engage_radius = p_data.engage_radius
	position = p_position
	home = p_position


func is_alive() -> bool:
	return state != State.DEAD


func is_enemy_of(other: SimUnit) -> bool:
	return faction != other.faction
