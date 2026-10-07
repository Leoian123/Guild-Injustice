class_name WanderBehavior
extends SimAbility
## Swarm wandering (GDD §7): idle player rats linked within SWARM_RADIUS form swarms; at ticks
## that are multiples of WANDER_PERIOD_TICKS every rat of a swarm votes one of 8 directions
## with the RNG and the whole swarm follows the most voted one, WANDER_RADIUS cells long.

## N, NE, E, SE, S, SW, W, NW.
const DIRECTIONS: Array[Vector2] = [
	Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1),
	Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1),
]
## Bisection steps used to shorten a wander line cut by a wall. Precision, not a game number.
const SHORTEN_STEPS: int = 16

var has_destination: bool = false
var destination: Vector2 = Vector2.ZERO
## Index in DIRECTIONS of the last direction followed, -1 before the first vote.
var direction: int = -1


func idle_destination(_world: World, _unit: SimUnit) -> Variant:
	return destination if has_destination else null


## A rat that gets a target abandons its wander destination.
func on_has_target(_world: World, _unit: SimUnit) -> void:
	has_destination = false


## Phase 3, before anyone moves: the swarm vote, at ticks that are multiples of WANDER_PERIOD_TICKS (> 0).
static func run_swarms(world: World) -> void:
	var period := world.rules.wander_period_ticks
	if period <= 0 or world.tick == 0 or world.tick % period != 0:
		return
	var idle: Array[SimUnit] = []
	for unit: SimUnit in world.units:
		if unit.is_alive() and unit.ai_enabled and unit.faction == SimUnit.Faction.PLAYER \
				and unit.target_id == SimUnit.NO_TARGET and unit.state != SimUnit.State.FLEE \
				and _wander_of(unit) != null:
			idle.append(unit)
	var assigned: Dictionary = {}
	for first: SimUnit in idle:
		if assigned.has(first.id):
			continue
		var swarm := _swarm_from(world, first, idle, assigned)
		_vote_and_move(world, swarm)


# Members linked to `first` by chains of distance ≤ SWARM_RADIUS, sorted by ID.
static func _swarm_from(world: World, first: SimUnit, idle: Array[SimUnit], assigned: Dictionary) -> Array[SimUnit]:
	var swarm: Array[SimUnit] = [first]
	assigned[first.id] = true
	var index: int = 0
	while index < swarm.size():
		var current := swarm[index]
		for other: SimUnit in idle:
			if assigned.has(other.id):
				continue
			if other.position.distance_to(current.position) <= world.rules.swarm_radius:
				assigned[other.id] = true
				swarm.append(other)
		index += 1
	swarm.sort_custom(func(a: SimUnit, b: SimUnit) -> bool: return a.id < b.id)
	return swarm


static func _vote_and_move(world: World, swarm: Array[SimUnit]) -> void:
	var votes: Array[int] = []
	var counts: Array[int] = []
	counts.resize(DIRECTIONS.size())
	counts.fill(0)
	for unit: SimUnit in swarm:
		var vote := world.rng.randi_range(0, DIRECTIONS.size() - 1)
		votes.append(vote)
		counts[vote] += 1
	var best_count: int = counts.max()
	# Tie: the direction voted by the lowest-ID rat among the tied ones (votes are in ID order).
	var winner: int = 0
	for vote: int in votes:
		if counts[vote] == best_count:
			winner = vote
			break
	var heading := DIRECTIONS[winner].normalized()
	for unit: SimUnit in swarm:
		var wander := _wander_of(unit)
		wander.direction = winner
		var destination := _clipped_point(world, unit.position, heading, world.rules.wander_radius)
		# A sated rat stays near its den to breed (GDD §7): the leg is pulled back to the leash.
		if unit.will is HungerWill and (unit.will as HungerWill).is_sated():
			destination = _leashed(world, unit.position, destination, (unit.will as HungerWill).den)
		wander.destination = destination
		wander.has_destination = true


# `destination` pulled towards `den` until within SWARM_LEASH_RADIUS of it, then clipped by walls.
static func _leashed(world: World, start: Vector2, destination: Vector2, den: Vector2) -> Vector2:
	var leash := world.rules.swarm_leash_radius
	if den.distance_to(destination) <= leash:
		return destination
	var target := den + (destination - den).limit_length(leash)
	var length := start.distance_to(target)
	if length == 0.0:
		return start
	return _clipped_point(world, start, (target - start) / length, length)


# Farthest point along the line, up to `length`, that stays on floor and in sight of the start.
static func _clipped_point(world: World, start: Vector2, heading: Vector2, length: float) -> Vector2:
	var full := start + heading * length
	if _reachable(world, start, full):
		return full
	var low: float = 0.0
	var high: float = length
	for step: int in SHORTEN_STEPS:
		var middle := (low + high) / 2.0
		if _reachable(world, start, start + heading * middle):
			low = middle
		else:
			high = middle
	return start + heading * low


static func _reachable(world: World, start: Vector2, point: Vector2) -> bool:
	return world.map.is_walkable(Vector2i(point.floor())) and SimVision.has_line_of_sight(world.map, start, point)


static func _wander_of(unit: SimUnit) -> WanderBehavior:
	for ability: SimAbility in unit.abilities:
		if ability is WanderBehavior:
			return ability as WanderBehavior
	return null
