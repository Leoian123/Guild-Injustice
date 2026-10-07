class_name PackCourageAbility
extends SimAbility
## Goblin pack courage (GDD §7): damage bonus with enough allies of the same kind around,
## flight towards the relic when alone and wounded.

## Ticks before the unit may flee again.
var flee_cooldown: int = 0


func on_tick_start(world: World, unit: SimUnit) -> void:
	if flee_cooldown > 0:
		flee_cooldown -= 1
	# With AI off the unit does not change state on its own (docs/TESTS.md).
	if not unit.ai_enabled:
		return
	var allies := _allies_near(world, unit)
	if unit.state == SimUnit.State.FLEE:
		var at_relic := unit.position.distance_to(world.map.relic_position()) <= 1.0
		if at_relic or allies >= world.rules.courage_min_allies:
			unit.state = SimUnit.State.IDLE
			unit.home = unit.position
			flee_cooldown = world.rules.flee_cooldown_ticks
			world.log_event(&"flee_end", unit.id, unit.unit_type)
	elif allies == 0 and flee_cooldown == 0 and not unit.is_fearless() \
			and unit.hp < unit.max_hp * world.rules.flee_hp_ratio:
		unit.state = SimUnit.State.FLEE
		unit.target_id = SimUnit.NO_TARGET
		world.log_event(&"flee_start", unit.id, unit.unit_type)


func damage_multiplier(attacker: SimUnit, _target: SimUnit, snapshot: SimSnapshot, rules: RulesData) -> float:
	var position := snapshot.position_of(attacker.id)
	var allies: int = 0
	for index: int in snapshot.size():
		if index == attacker.id - 1 or not snapshot.alive[index]:
			continue
		if snapshot.factions[index] != attacker.faction or snapshot.types[index] != attacker.unit_type:
			continue
		if snapshot.positions[index].distance_to(position) <= rules.courage_radius:
			allies += 1
	if allies >= rules.courage_min_allies:
		return 1.0 + rules.courage_bonus
	return 1.0


# Other living units of the same kind and faction within COURAGE_RADIUS, current positions.
func _allies_near(world: World, unit: SimUnit) -> int:
	var count: int = 0
	for other: SimUnit in world.units:
		if other == unit or not other.is_alive():
			continue
		if other.faction != unit.faction or other.unit_type != unit.unit_type:
			continue
		if other.position.distance_to(unit.position) <= world.rules.courage_radius:
			count += 1
	return count
