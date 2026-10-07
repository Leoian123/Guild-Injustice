class_name NecroBoundWill
extends SimWill
## Bound to the necromancer (GDD §6.8): hunts inside its influence, mindless outside.

const NECROMANCER: StringName = &"necromancer"


static func is_necromancer(unit: SimUnit) -> bool:
	return unit.unit_type == NECROMANCER


## True if a living allied necromancer is within the influence radius of `position`.
static func influences(world: World, unit: SimUnit, position: Vector2) -> bool:
	for other: SimUnit in world.necromancers:
		if other.is_alive() and other.faction == unit.faction:
			if other.position.distance_to(position) <= world.rules.necro_influence_radius:
				return true
	return false


func accepts(world: World, unit: SimUnit, enemy: SimUnit) -> bool:
	if is_necromancer(unit) or influences(world, unit, unit.position):
		return true
	# Mindless: only what is already in reach, or whoever contests the relic.
	if unit.position.distance_to(enemy.position) <= unit.attack_range:
		return true
	return world.map.relic_position().distance_to(enemy.position) <= world.rules.relic_contest_radius


func is_raider() -> bool:
	return true


func idle_destination(world: World, _unit: SimUnit) -> Variant:
	return world.map.relic_position()


func allows_step(world: World, unit: SimUnit, position: Vector2) -> bool:
	if is_necromancer(unit) or not influences(world, unit, unit.position):
		return true
	return influences(world, unit, position)


# The necromancer backs away only once no other bound unit is around him.
func may_kite(world: World, unit: SimUnit) -> bool:
	if not is_necromancer(unit):
		return true
	for other: SimUnit in world.units:
		if other != unit and other.is_alive() and other.faction == unit.faction and other.will is NecroBoundWill:
			if other.position.distance_to(unit.position) <= world.rules.necro_influence_radius:
				return false
	return true
