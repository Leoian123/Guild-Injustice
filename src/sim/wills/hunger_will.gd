class_name HungerWill
extends SimWill
## The scavenger rat (GDD §6.8): born sated; sated it stays near its den and breeds;
## hungry it goes for the nearest corpse it notices, otherwise it hunts. Eating a corpse,
## not biting, sates it.

## Ticks of satiety left; 0 = hungry.
var digest_ticks: int = 0
## Where the rat was released (GDD §7); newborns take the den of their first parent.
var den: Vector2 = Vector2.ZERO
## Unit ID of the corpse the rat is going to eat, -1 if none.
var meal_id: int = -1
## SWARM_LEASH_RADIUS, copied at spawn: the den's reach for invaders. A fixed input.
var _leash_radius: float = 0.0


func hash_excluded() -> PackedStringArray:
	return PackedStringArray(["_leash_radius"])


func is_sated() -> bool:
	return digest_ticks > 0


func on_spawn(world: World, unit: SimUnit) -> void:
	digest_ticks = world.rules.rat_digest_ticks
	den = unit.position
	_leash_radius = world.rules.swarm_leash_radius


# Phase 1: digestion, then a hungry rat looks for food (current positions).
func on_tick_start(world: World, unit: SimUnit) -> void:
	if digest_ticks > 0:
		digest_ticks -= 1
	meal_id = -1
	if not is_sated():
		var corpse := _nearest_food(world, unit)
		if corpse != null:
			meal_id = corpse.unit_id
			# A rat going to eat abandons its wander destination (GDD §7).
			for ability: SimAbility in unit.abilities:
				if ability is WanderBehavior:
					(ability as WanderBehavior).has_destination = false


# Sated: nothing. Hungry with food in sight: nothing, it goes to eat. Hungry: any enemy.
func accepts(world: World, _unit: SimUnit, _enemy: SimUnit) -> bool:
	return not is_sated() and world.corpse_of(meal_id) == null


func can_hunt(world: World, unit: SimUnit, ally: SimUnit) -> bool:
	if is_sated() or world.corpse_of(meal_id) != null:
		return false
	if not ally.is_alive() or not ally.will is PreyWill:
		return false
	if unit.position.distance_to(ally.position) > unit.engage_radius:
		return false
	return SimVision.has_line_of_sight(world.map, unit.position, ally.position)


## Hungry (GDD §6.8): first an enemy that invaded the den, then the easiest prey;
## each time the one with less HP, then the nearest, then the lower ID.
func preferred_target(_world: World, unit: SimUnit, candidates: Array[SimUnit]) -> SimUnit:
	if is_sated() or candidates.is_empty():
		return null
	var invaders: Array[SimUnit] = []
	for candidate: SimUnit in candidates:
		if candidate.is_enemy_of(unit) and den.distance_to(candidate.position) <= _leash_radius:
			invaders.append(candidate)
	return _easiest(unit, invaders if not invaders.is_empty() else candidates)


func leash_point() -> Variant:
	return den if is_sated() else null


func inherit_den(parent_will: SimWill) -> void:
	if parent_will is HungerWill:
		den = (parent_will as HungerWill).den


func idle_destination(world: World, _unit: SimUnit) -> Variant:
	var corpse := world.corpse_of(meal_id)
	return corpse.position if corpse != null else null


## Phase 7, after reanimation: every hungry rat within 1 cell of its corpse eats one point
## of integrity and is sated again (GDD §6.8). Rats eat in ID order.
static func run_meals(world: World) -> void:
	for unit: SimUnit in world.units:
		if not unit.is_alive() or not unit.will is HungerWill:
			continue
		var will := unit.will as HungerWill
		if will.is_sated():
			continue
		var corpse := world.corpse_of(will.meal_id)
		if corpse == null or unit.position.distance_to(corpse.position) > 1.0:
			continue
		world.eat(corpse)
		will.digest_ticks = world.rules.rat_digest_ticks
		will.meal_id = -1


static func _easiest(unit: SimUnit, pool: Array[SimUnit]) -> SimUnit:
	var best: SimUnit = null
	var best_distance: float = 0.0
	for candidate: SimUnit in pool:
		var distance := unit.position.distance_squared_to(candidate.position)
		if best == null or candidate.hp < best.hp \
				or (candidate.hp == best.hp and distance < best_distance) \
				or (candidate.hp == best.hp and distance == best_distance and candidate.id < best.id):
			best = candidate
			best_distance = distance
	return best


# Nearest corpse with integrity ≥ 1 within the engage radius and in sight; ties: lower unit ID.
func _nearest_food(world: World, unit: SimUnit) -> SimCorpse:
	var best: SimCorpse = null
	var best_distance: float = 0.0
	for corpse: SimCorpse in world.corpses:
		if corpse.integrity < 1:
			continue
		var distance := unit.position.distance_to(corpse.position)
		if distance > unit.engage_radius:
			continue
		if not SimVision.has_line_of_sight(world.map, unit.position, corpse.position):
			continue
		# Corpses are sorted by unit ID: a strict comparison keeps the lower ID on ties.
		if best == null or distance < best_distance:
			best = corpse
			best_distance = distance
	return best
