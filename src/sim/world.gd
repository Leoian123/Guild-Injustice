class_name World
extends SimState
## Deterministic fixed-tick simulation (GDD §6.2, §12).

var rules: RulesData
var map: SimMap
var pathfinder: SimPathfinder
var rng: RandomNumberGenerator
## Index of the next tick to run. Ticks are numbered from 0 (GDD §6.1).
var tick: int = 0
var relic_timer: int = 0
## Battle outcome (GDD §3): "" while running, then "win" or "lose".
var result: String = ""
## enemies_dead, player_dead, relic_stolen or timeout (GDD §11).
var reason: String = ""
## Last tick executed, -1 while running.
var end_tick: int = -1
## Sorted by ascending ID, index = id - 1: IDs start at 1 and only grow.
var units: Array[SimUnit] = []
## Sorted by ascending unit ID.
var corpses: Array[SimCorpse] = []

## Battle log for tools/sim.sh (GDD §11). Output only: it never drives the simulation.
var events: Array[Dictionary] = []

var _next_id: int = 1
## Damage per unit index, filled in phase 4 and applied in phase 5.
var _pending_damage: PackedInt32Array = PackedInt32Array()


func _init(p_rules: RulesData, p_map: SimMap, p_seed: int) -> void:
	rules = p_rules
	map = p_map
	pathfinder = SimPathfinder.new(map)
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed


## Deployed unit: starts with age NEWBORN_COOLDOWN_TICKS (GDD §6.1).
func spawn_unit(data: UnitData, faction: SimUnit.Faction, position: Vector2) -> SimUnit:
	var unit := SimUnit.new(_next_id, data, faction, position, rules.tick_rate)
	unit.age = rules.newborn_cooldown_ticks
	return _add_unit(unit)


## Unit born in battle: starts with age 0 (GDD §6.1).
func spawn_newborn(data: UnitData, faction: SimUnit.Faction, position: Vector2) -> SimUnit:
	var unit := _add_unit(SimUnit.new(_next_id, data, faction, position, rules.tick_rate))
	log_event(&"birth", unit.id, unit.unit_type)
	return unit


## Reanimation (GDD §8): max HP = floor(dead unit's max HP × REANIMATE_HP_RATIO), other stats
## of the original, enemy faction, only FearlessTrait, NecroBoundWill (GDD §6.8), new ID,
## at the corpse; the corpse disappears.
func reanimate(corpse: SimCorpse) -> SimUnit:
	var original := get_unit(corpse.unit_id)
	var unit := SimUnit.new(_next_id, original.data, SimUnit.Faction.ENEMY, corpse.position, rules.tick_rate)
	unit.max_hp = reanimated_max_hp(original.max_hp)
	unit.hp = unit.max_hp
	var abilities: Array[SimAbility] = [FearlessTrait.new()]
	unit.abilities = abilities
	unit.will = NecroBoundWill.new()
	unit.reanimated = true
	_add_unit(unit)
	corpses.erase(corpse)
	log_event(&"reanimate", unit.id, unit.unit_type)
	return unit


func reanimated_max_hp(max_hp: int) -> int:
	return floori(max_hp * rules.reanimate_hp_ratio)


## Chance that a corpse is reanimable (GDD §6.7): max HP / (max HP + K), K = REANIMATE_K_BASE + x.
## x gathers body conditions (faith, disease…) outside Phase 1: today x = 0 (Δ-13).
static func reanimation_chance(max_hp: int, rules_value: RulesData) -> float:
	var k: float = rules_value.reanimate_k_base
	return max_hp / (max_hp + k)


func _add_unit(unit: SimUnit) -> SimUnit:
	_next_id += 1
	unit.facing = _initial_facing(unit.faction, unit.position)
	units.append(unit)
	unit.will.on_spawn(self, unit)
	return unit


func log_event(type: StringName, unit_id: int, detail: StringName) -> void:
	events.append({"tick": tick, "type": String(type), "unit": unit_id, "detail": String(detail)})


func get_unit(unit_id: int) -> SimUnit:
	if unit_id < 1 or unit_id > units.size():
		return null
	return units[unit_id - 1]


func is_over() -> bool:
	return result != ""


## Runs one tick. Does nothing once the battle is over.
func step() -> void:
	if is_over():
		return
	_phase_states()
	_phase_targets()
	_phase_movement()
	var snapshot := SimSnapshot.new(units)
	_phase_attacks(snapshot)
	_phase_damage()
	_phase_deaths()
	_phase_periodic_abilities()
	_phase_battle_end()
	tick += 1


## SHA-256 of the world's self-description (GDD §12).
func state_hash() -> String:
	return describe().sha256_text()


# Fixed inputs, data derived from them and the per-tick damage buffer are not state.
func hash_excluded() -> PackedStringArray:
	return PackedStringArray(["rules", "map", "pathfinder", "_pending_damage", "events"])


## A unit notices living enemies within its engage radius and in sight (GDD §6.4).
func notices(unit: SimUnit, other: SimUnit) -> bool:
	if other == null or not other.is_alive() or not unit.is_enemy_of(other):
		return false
	if unit.position.distance_to(other.position) > unit.engage_radius:
		return false
	return SimVision.has_line_of_sight(map, unit.position, other.position)


# Player units face away from the relic (south on the relic cell); enemies face it (GDD §6.5).
func _initial_facing(faction: SimUnit.Faction, position: Vector2) -> Vector2:
	var to_relic := map.relic_position() - position
	if to_relic.is_zero_approx():
		return Vector2.DOWN
	if faction == SimUnit.Faction.PLAYER:
		return -to_relic.normalized()
	return to_relic.normalized()


# Phase 1: timers, cooldowns and age; flee enter/exit (PackCourageAbility).
func _phase_states() -> void:
	for unit: SimUnit in units:
		if not unit.is_alive():
			continue
		if unit.attack_cd > 0:
			unit.attack_cd -= 1
		unit.age += 1
		unit.will.on_tick_start(self, unit)
		for ability: SimAbility in unit.abilities:
			ability.on_tick_start(self, unit)
	var kept: Array[SimCorpse] = []
	for corpse: SimCorpse in corpses:
		corpse.ttl -= 1
		if corpse.ttl > 0:
			kept.append(corpse)
	corpses = kept


# Phase 2: target selection (GDD §6.4).
func _phase_targets() -> void:
	for unit: SimUnit in units:
		if not unit.is_alive():
			continue
		if unit.state == SimUnit.State.FLEE:
			unit.target_id = SimUnit.NO_TARGET
			continue
		if not unit.ai_enabled:
			var forced := get_unit(unit.forced_target_id)
			unit.target_id = forced.id if forced != null and forced.is_alive() else SimUnit.NO_TARGET
			continue
		var must_choose: bool = unit.target_id == SimUnit.NO_TARGET
		if not must_choose:
			if not _is_valid_target(unit, get_unit(unit.target_id)):
				must_choose = true
			elif tick - unit.last_target_tick >= rules.retarget_ticks:
				must_choose = true
		if must_choose:
			unit.target_id = _choose_target(unit)
			unit.last_target_tick = tick


func _is_valid_target(unit: SimUnit, other: SimUnit) -> bool:
	return notices(unit, other) and unit.will.accepts(self, unit, other)


# Abilities may prefer a target (thief); otherwise the nearest noticed enemy,
# ties: less HP, then lower ID (iteration is by ascending ID).
func _choose_target(unit: SimUnit) -> int:
	var candidates: Array[SimUnit] = []
	for other: SimUnit in units:
		if _is_valid_target(unit, other):
			candidates.append(other)
	for ability: SimAbility in unit.abilities:
		var preferred := ability.preferred_target(self, unit, candidates)
		if preferred != null:
			return preferred.id
	var best: SimUnit = null
	var best_distance: float = 0.0
	for other: SimUnit in candidates:
		var distance := unit.position.distance_squared_to(other.position)
		if best == null or distance < best_distance or (distance == best_distance and other.hp < best.hp):
			best = other
			best_distance = distance
	return best.id if best != null else SimUnit.NO_TARGET


# Phase 3: movement along A* at speed / TICK_RATE cells per tick (GDD §6.3, §6.6, §6.8).
func _phase_movement() -> void:
	WanderBehavior.run_swarms(self)
	for unit: SimUnit in units:
		if not unit.is_alive() or not unit.ai_enabled:
			continue
		if unit.state == SimUnit.State.FLEE:
			_move_towards(unit, map.relic_position())
			continue
		var target := get_unit(unit.target_id)
		var threat := _kite_threat(unit)
		if threat != null:
			# Backing away replaces any other movement, even when the step is refused.
			if _kite_step(unit, threat):
				unit.state = SimUnit.State.MOVE
			else:
				unit.state = SimUnit.State.ATTACK if target != null else SimUnit.State.IDLE
			continue
		var destination: Variant = null
		if target != null:
			for ability: SimAbility in unit.abilities:
				ability.on_has_target(self, unit)
			destination = _approach_point(unit, target)
			if destination == null:
				if _can_attack(unit, target.position):
					unit.state = SimUnit.State.ATTACK
					continue
				destination = target.position
		else:
			destination = unit.will.idle_destination(self, unit)
			if destination == null:
				destination = _ability_idle_destination(unit)
		if destination != null and _move_towards(unit, destination):
			unit.state = SimUnit.State.MOVE
		elif target != null and _can_attack(unit, target.position):
			unit.state = SimUnit.State.ATTACK
		else:
			unit.state = SimUnit.State.IDLE


# An ability may steer the approach (thief: one cell behind the target, D-027).
func _approach_point(unit: SimUnit, target: SimUnit) -> Variant:
	for ability: SimAbility in unit.abilities:
		var point: Variant = ability.approach_point(self, unit, target)
		if point != null:
			return point
	return null


func _ability_idle_destination(unit: SimUnit) -> Variant:
	for ability: SimAbility in unit.abilities:
		var point: Variant = ability.idle_destination(self, unit)
		if point != null:
			return point
	return null


# A ranged unit reloading backs away from the nearest living enemy within KITE_RADIUS (GDD §6.8).
func _kite_threat(unit: SimUnit) -> SimUnit:
	if unit.attack_range <= 1.0 or unit.attack_cd == 0 or not unit.will.may_kite(self, unit):
		return null
	var nearest: SimUnit = null
	var nearest_distance: float = 0.0
	for other: SimUnit in units:
		if not other.is_alive() or not unit.is_enemy_of(other):
			continue
		var distance := unit.position.distance_to(other.position)
		if distance > rules.kite_radius:
			continue
		if nearest == null or distance < nearest_distance:
			nearest = other
			nearest_distance = distance
	return nearest


# Straight step away from the threat; refused on walls or when the will forbids it.
func _kite_step(unit: SimUnit, threat: SimUnit) -> bool:
	var away := unit.position - threat.position
	if away.is_zero_approx():
		return false
	var heading := away.normalized()
	var position := unit.position + heading * unit.speed_per_tick
	if map.is_wall(Vector2i(position.floor())):
		return false
	if not unit.will.allows_kite_step(self, unit, position) or not unit.will.allows_step(self, unit, position):
		return false
	unit.position = position
	unit.facing = heading
	return true


func _can_attack(unit: SimUnit, target_position: Vector2) -> bool:
	if unit.position.distance_to(target_position) > unit.attack_range:
		return false
	return SimVision.has_line_of_sight(map, unit.position, target_position)


# Walks up to speed_per_tick along the path; the last waypoint is the exact destination.
# The facing becomes the direction of the last segment walked. Returns true if the unit moved.
func _move_towards(unit: SimUnit, destination: Vector2) -> bool:
	if unit.position == destination:
		return false
	var path := pathfinder.find_path(Vector2i(unit.position.floor()), Vector2i(destination.floor()))
	if path.is_empty():
		return false
	var waypoints: Array[Vector2] = []
	for i: int in range(1, path.size()):
		waypoints.append(SimMap.cell_center(path[i]))
	if waypoints.is_empty():
		waypoints.append(destination)
	else:
		waypoints[waypoints.size() - 1] = destination

	var budget: float = unit.speed_per_tick
	var position := unit.position
	var heading := Vector2.ZERO
	for waypoint: Vector2 in waypoints:
		var distance := position.distance_to(waypoint)
		if distance == 0.0:
			continue
		heading = (waypoint - position) / distance
		if distance <= budget:
			position = waypoint
			budget -= distance
		else:
			position += heading * budget
			budget = 0.0
		if budget <= 0.0:
			break
	if heading == Vector2.ZERO:
		return false
	if not unit.will.allows_step(self, unit, position):
		return false
	unit.position = position
	unit.facing = heading
	return true


# Phase 4: attacks computed from the snapshot (GDD §6.5).
func _phase_attacks(snapshot: SimSnapshot) -> void:
	_pending_damage.resize(units.size())
	_pending_damage.fill(0)
	var attackers: Array[SimUnit] = []
	for unit: SimUnit in units:
		if not snapshot.is_alive(unit.id) or unit.attack_cd > 0 or unit.state == SimUnit.State.FLEE:
			continue
		if _attack_blocked(unit):
			continue
		var target := get_unit(unit.target_id)
		if target == null or not snapshot.is_alive(target.id):
			continue
		var from := snapshot.position_of(unit.id)
		var to := snapshot.position_of(target.id)
		if from.distance_to(to) > unit.attack_range:
			continue
		if not SimVision.has_line_of_sight(map, from, to):
			continue
		_pending_damage[target.id - 1] += SimCombat.compute_damage(unit, target, snapshot, rules)
		attackers.append(unit)
	for unit: SimUnit in attackers:
		var to_target := snapshot.position_of(unit.target_id) - snapshot.position_of(unit.id)
		if not to_target.is_zero_approx():
			unit.facing = to_target.normalized()
		unit.attack_cd = unit.attack_interval_ticks
		unit.will.on_attack_landed(self, unit)
		if unit.ai_enabled:
			unit.state = SimUnit.State.ATTACK


func _attack_blocked(unit: SimUnit) -> bool:
	for ability: SimAbility in unit.abilities:
		if ability.blocks_attack(self, unit):
			return true
	return false


# Phase 5: damage applied all at once.
func _phase_damage() -> void:
	for unit: SimUnit in units:
		unit.hp -= _pending_damage[unit.id - 1]


# Phase 6: deaths and corpses (GDD §6.7).
func _phase_deaths() -> void:
	for unit: SimUnit in units:
		if unit.is_alive() and unit.hp <= 0:
			unit.state = SimUnit.State.DEAD
			unit.target_id = SimUnit.NO_TARGET
			log_event(&"death", unit.id, unit.unit_type)
			# A body too weak to be raised again is destroyed (GDD §6.7).
			if reanimated_max_hp(unit.max_hp) < 1:
				continue
			var corpse := SimCorpse.new()
			corpse.unit_id = unit.id
			corpse.unit_type = unit.unit_type
			corpse.position = unit.position
			corpse.ttl = rules.corpse_ticks
			corpse.reanimable = rng.randf() < reanimation_chance(unit.max_hp, rules)
			_insert_corpse(corpse)


# Keeps corpses sorted by unit ID: a lower ID can die after a higher one.
func _insert_corpse(corpse: SimCorpse) -> void:
	var index: int = corpses.size()
	while index > 0 and corpses[index - 1].unit_id > corpse.unit_id:
		index -= 1
	corpses.insert(index, corpse)


# Phase 7: reanimation, then rat breeding. Units born here do not act until the next tick.
func _phase_periodic_abilities() -> void:
	for unit: SimUnit in units.duplicate():
		for ability: SimAbility in unit.abilities:
			ability.on_periodic(self, unit)
	BreedAbility.run_breeding(self)


# Phase 8: end of battle (GDD §3), checked in this order.
func _phase_battle_end() -> void:
	var player_alive: bool = false
	var enemy_alive: bool = false
	var enemy_on_relic: bool = false
	var player_contests: bool = false
	var relic := map.relic_position()
	for unit: SimUnit in units:
		if not unit.is_alive():
			continue
		var distance := unit.position.distance_to(relic)
		if unit.faction == SimUnit.Faction.PLAYER:
			player_alive = true
			if distance <= rules.relic_contest_radius:
				player_contests = true
		else:
			enemy_alive = true
			if distance <= rules.relic_on_radius:
				enemy_on_relic = true
	if enemy_on_relic and not player_contests:
		relic_timer += 1
	elif relic_timer > 0:
		relic_timer = 0
		log_event(&"relic_timer_reset", 0, &"")

	if not enemy_alive:
		_end(&"win", &"enemies_dead")
	elif not player_alive:
		_end(&"lose", &"player_dead")
	elif relic_timer >= rules.steal_ticks:
		_end(&"lose", &"relic_stolen")
	elif tick >= rules.time_limit_ticks - 1:
		_end(&"lose", &"timeout")


func _end(outcome: StringName, why: StringName) -> void:
	result = String(outcome)
	reason = String(why)
	end_tick = tick
