class_name BackstabAbility
extends SimAbility
## Thief (GDD §7): ×BACKSTAB_MULT from behind, prefers isolated targets,
## approaches the point one cell behind the target.


## Behind (GDD §6.5): dot(target facing, attacker − target) < 0 in the snapshot; never at distance 0.
static func is_behind(attacker_position: Vector2, target_position: Vector2, target_facing: Vector2) -> bool:
	var offset := attacker_position - target_position
	if offset.is_zero_approx():
		return false
	return target_facing.dot(offset) < 0.0


func damage_multiplier(attacker: SimUnit, target: SimUnit, snapshot: SimSnapshot, rules: RulesData) -> float:
	if is_behind(snapshot.position_of(attacker.id), snapshot.position_of(target.id), snapshot.facing_of(target.id)):
		return rules.backstab_mult
	return 1.0


# Isolated = no ally of the candidate within ISOLATION_RADIUS. Nearest, then less HP, then ID.
func preferred_target(world: World, unit: SimUnit, candidates: Array[SimUnit]) -> SimUnit:
	var best: SimUnit = null
	var best_distance: float = 0.0
	for candidate: SimUnit in candidates:
		if not _is_isolated(world, candidate):
			continue
		var distance := unit.position.distance_squared_to(candidate.position)
		if best == null or distance < best_distance or (distance == best_distance and candidate.hp < best.hp):
			best = candidate
			best_distance = distance
	return best


## A target that moved in its last movement step: walking, backing away or fleeing.
static func is_moving(target: SimUnit) -> bool:
	return target.state == SimUnit.State.MOVE or target.state == SimUnit.State.FLEE


# Still target: position first, then strike (GDD §7). While the point behind it is not a wall,
# the thief attacks only from behind. A moving target is hit as soon as it is in reach.
func blocks_attack(world: World, unit: SimUnit) -> bool:
	var target := world.get_unit(unit.target_id)
	if target == null or approach_point(world, unit, target) == null:
		return false
	return not is_behind(unit.position, target.position, target.facing)


# Still target: one cell behind it, opposite to its facing. Moving target, or wall behind it:
# null, so the thief goes straight at the target like any unit.
func approach_point(world: World, _unit: SimUnit, target: SimUnit) -> Variant:
	if is_moving(target):
		return null
	var behind := target.position - target.facing.normalized()
	if world.map.is_wall(Vector2i(behind.floor())):
		return null
	return behind


func _is_isolated(world: World, candidate: SimUnit) -> bool:
	for other: SimUnit in world.units:
		if other == candidate or not other.is_alive() or other.faction != candidate.faction:
			continue
		if other.position.distance_to(candidate.position) <= world.rules.isolation_radius:
			return false
	return true
