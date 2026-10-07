class_name SimUnit
extends SimState
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
var chase_radius: float = 0.0
## Will to fight (GDD §6.8), one instance per unit.
var will: SimWill
## Ability components (GDD §7, §8), one instance per unit.
var abilities: Array[SimAbility] = []

## Deployment point; player units return here without a target (GDD §6.6).
var home: Vector2 = Vector2.ZERO
## Tick of the last target computation (GDD §6.4).
var last_target_tick: int = 0
## Ticks lived; deployed units start at NEWBORN_COOLDOWN_TICKS (GDD §6.1).
var age: int = 0
## Reanimated units leave no corpse (GDD §6.7).
var reanimated: bool = false

## Test mode (docs/TESTS.md): with AI off the unit only attacks forced_target_id.
var ai_enabled: bool = true
var forced_target_id: int = NO_TARGET

## Source data, kept for births. A fixed input, not state.
var data: UnitData


func _init(p_id: int, p_data: UnitData, p_faction: Faction, p_position: Vector2, tick_rate: int) -> void:
	id = p_id
	data = p_data
	unit_type = p_data.unit_type
	faction = p_faction
	max_hp = p_data.max_hp
	hp = max_hp
	damage = p_data.damage
	attack_interval_ticks = UnitData.seconds_to_ticks(p_data.attack_interval, tick_rate)
	attack_range = p_data.attack_range
	speed_per_tick = p_data.speed / tick_rate
	engage_radius = p_data.engage_radius
	chase_radius = p_data.chase_radius
	will = SimWill.create(p_data.will)
	for ability_name: StringName in p_data.abilities:
		abilities.append(SimAbility.create(ability_name))
	position = p_position
	home = p_position


func hash_excluded() -> PackedStringArray:
	return PackedStringArray(["data"])


func is_alive() -> bool:
	return state != State.DEAD


func is_enemy_of(other: SimUnit) -> bool:
	return faction != other.faction


func has_ability(ability_script: Script) -> bool:
	for ability: SimAbility in abilities:
		if ability.get_script() == ability_script:
			return true
	return false


func is_fearless() -> bool:
	for ability: SimAbility in abilities:
		if ability.prevents_flee():
			return true
	return false
