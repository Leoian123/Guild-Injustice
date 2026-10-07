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
## Room of the relic (GDD §4), held by guards (GDD §7). A fixed input of the scenario.
var relic_room: Rect2i = Rect2i()
## Scenario variants rolled at creation (GDD §9): "A" or "B", empty in test worlds.
var blitz_variant: String = ""
var hunt_variant: String = ""
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
## Living units of each faction at the start of phase 2, in ID order (a per-tick buffer).
var _alive_by_faction: Array = [[], []]
## Necromancers among `units`, in ID order: an index for the influence checks (GDD §6.8).
var necromancers: Array[SimUnit] = []
## Cells occupied by living units of each faction at the start of phase 3, for paths (GDD §6.3).
var _occupied: Array[Dictionary] = [{}, {}]
## Whether the last _move_towards had to ignore enemy units to find a path.
var _last_path_ignored_units: bool = false
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


## Reanimation (GDD §8): max HP = corpse integrity × INTEGRITY_HP, integrity one point less,
## other stats of the original, enemy faction, only FearlessTrait, NecroBoundWill (GDD §6.8),
## new ID, at the corpse; the corpse disappears.
func reanimate(corpse: SimCorpse) -> SimUnit:
	var original := get_unit(corpse.unit_id)
	var unit := SimUnit.new(_next_id, original.data, SimUnit.Faction.ENEMY, corpse.position, rules.tick_rate)
	unit.max_hp = corpse.integrity * rules.integrity_hp
	unit.hp = unit.max_hp
	unit.integrity = corpse.integrity - 1
	var abilities: Array[SimAbility] = [FearlessTrait.new()]
	unit.abilities = abilities
	unit.will = NecroBoundWill.new()
	unit.reanimated = true
	if is_enemy_cell(Vector2i(corpse.position.floor()), unit.faction):
		unit.position = SimMap.cell_center(_first_cell_without_enemies(Vector2i(corpse.position.floor()), unit.faction))
		unit.home = unit.position
	_add_unit(unit)
	corpses.erase(corpse)
	log_event(&"reanimate", unit.id, unit.unit_type)
	return unit


## Chance that a corpse is reanimable (GDD §6.7): max HP / (max HP + K), K = REANIMATE_K_BASE + x.
## x gathers body conditions (faith, disease…) outside Phase 1: today x = 0 (Δ-13).
static func reanimation_chance(max_hp: int, rules_value: RulesData) -> float:
	var k: float = rules_value.reanimate_k_base
	return max_hp / (max_hp + k)


func _add_unit(unit: SimUnit) -> SimUnit:
	_next_id += 1
	unit.facing = _initial_facing(unit.faction, unit.position)
	units.append(unit)
	if NecroBoundWill.is_necromancer(unit):
		necromancers.append(unit)
	unit.will.on_spawn(self, unit)
	return unit


## True if a living unit hostile to `faction` stands in `cell` right now (GDD §6.3).
func is_enemy_cell(cell: Vector2i, faction: SimUnit.Faction) -> bool:
	for unit: SimUnit in units:
		if unit.is_alive() and unit.faction != faction and Vector2i(unit.position.floor()) == cell:
			return true
	return false


## Cells occupied by enemies of `faction` at the start of phase 3.
func enemy_cells(faction: SimUnit.Faction) -> Dictionary:
	return _occupied[SimUnit.Faction.ENEMY if faction == SimUnit.Faction.PLAYER else SimUnit.Faction.PLAYER]


# First walkable cell without enemies of `faction`, ring by ring around `center`, row by row.
func _first_cell_without_enemies(center: Vector2i, faction: SimUnit.Faction) -> Vector2i:
	var max_ring: int = maxi(map.width, map.height)
	for ring: int in range(1, max_ring + 1):
		for y: int in range(center.y - ring, center.y + ring + 1):
			for x: int in range(center.x - ring, center.x + ring + 1):
				if maxi(absi(x - center.x), absi(y - center.y)) != ring:
					continue
				var cell := Vector2i(x, y)
				if map.is_walkable(cell) and not is_enemy_cell(cell, faction):
					return cell
	return center


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
	return PackedStringArray(["rules", "map", "pathfinder", "relic_room", "necromancers", "_alive_by_faction", "_pending_damage", "events",
		"_occupied", "_last_path_ignored_units"])


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


# Phase 2: target selection (GDD §6.4). Nobody moves or dies in this phase, so the living
# units of each faction are listed once, in ID order, as the only possible targets.
func _phase_targets() -> void:
	_alive_by_faction = [[], []]
	for unit: SimUnit in units:
		if unit.is_alive():
			_alive_by_faction[unit.faction].append(unit)
	for unit: SimUnit in units:
		if not unit.is_alive():
			continue
		if unit.state == SimUnit.State.FLEE:
			unit.target_id = SimUnit.NO_TARGET
			continue
		var blocker := get_unit(unit.blocker_id)
		if blocker != null and not blocker.is_alive():
			unit.blocker_id = SimUnit.NO_TARGET
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
	if not notices(unit, other):
		return false
	return unit.will.accepts(self, unit, other) or other.id == unit.blocker_id


# Abilities may prefer a target (thief); otherwise the nearest noticed enemy,
# ties: less HP, then lower ID (iteration is by ascending ID).
func _choose_target(unit: SimUnit) -> int:
	var candidates: Array[SimUnit] = []
	var enemy_faction := SimUnit.Faction.ENEMY if unit.faction == SimUnit.Faction.PLAYER else SimUnit.Faction.PLAYER
	for other: SimUnit in _alive_by_faction[enemy_faction]:
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
	_snapshot_occupancy()
	WanderBehavior.run_swarms(self)
	HoldGroundWill.run_patrols(self)
	for unit: SimUnit in units:
		if not unit.is_alive() or not unit.ai_enabled:
			continue
		if unit.state == SimUnit.State.FLEE:
			_move_towards(unit, map.relic_position())
			continue
		var target := get_unit(unit.target_id)
		if target != null:
			unit.will.on_has_target(self, unit)
			for ability: SimAbility in unit.abilities:
				ability.on_has_target(self, unit)
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
		var moved: bool = destination != null and _move_towards(unit, destination)
		if target == null and destination != null and unit.will.is_raider():
			# A raider with no way around the enemies opens one by fighting (GDD §6.3).
			unit.blocker_id = _first_blocker(unit, destination) if _last_path_ignored_units else SimUnit.NO_TARGET
		if moved:
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


# A ranged unit (attack type, not range) reloading backs away from the nearest living enemy within KITE_RADIUS (GDD §6.8).
func _kite_threat(unit: SimUnit) -> SimUnit:
	if unit.attack_kind != UnitData.RANGED or unit.attack_cd == 0 or not unit.will.may_kite(self, unit):
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
	var cell := Vector2i(position.floor())
	if map.is_wall(cell):
		return false
	if cell != Vector2i(unit.position.floor()) and is_enemy_cell(cell, unit.faction):
		# Enemies block: the step stops at the border of their cell (GDD §6.3).
		position = _clip_to_cell(unit.position, position)
		if position == unit.position:
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
	_last_path_ignored_units = false
	if unit.position == destination:
		return false
	var path := _path_for(unit, destination)
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
		var next := waypoint if distance <= budget else position + heading * budget
		var next_cell := Vector2i(next.floor())
		if next_cell != Vector2i(position.floor()) and is_enemy_cell(next_cell, unit.faction):
			# Enemies block: stop at the border of their cell (GDD §6.3).
			position = _clip_to_cell(position, next)
			break
		budget -= position.distance_to(next)
		position = next
		if budget <= 0.0:
			break
	if heading == Vector2.ZERO or position == unit.position:
		return false
	if not unit.will.allows_step(self, unit, position):
		return false
	unit.position = position
	unit.facing = heading
	return true


# A* around the cells held by enemies at the start of phase 3; if there is no such path,
# the path that ignores units (GDD §6.3).
func _path_for(unit: SimUnit, destination: Vector2) -> Array[Vector2i]:
	var from := Vector2i(unit.position.floor())
	var to := Vector2i(destination.floor())
	var path := pathfinder.find_path_avoiding(from, to, enemy_cells(unit.faction))
	if path.is_empty():
		path = pathfinder.find_path(from, to)
		_last_path_ignored_units = not path.is_empty()
	return path


# The lowest-ID enemy standing on the first enemy-held cell of the unit-blind path.
func _first_blocker(unit: SimUnit, destination: Vector2) -> int:
	var blocked := enemy_cells(unit.faction)
	for cell: Vector2i in pathfinder.find_path(Vector2i(unit.position.floor()), Vector2i(destination.floor())):
		if not blocked.has(cell):
			continue
		for other: SimUnit in units:
			if other.is_alive() and unit.is_enemy_of(other) and Vector2i(other.position.floor()) == cell:
				return other.id
	return SimUnit.NO_TARGET


## Last point of the segment from `from` towards `to` that stays inside the cell of `from`.
## The margin keeps the position strictly inside, so its cell does not change.
const CELL_BORDER_MARGIN: float = 0.001
static func _clip_to_cell(from: Vector2, to: Vector2) -> Vector2:
	var cell := from.floor()
	var delta := to - from
	var t: float = 1.0
	if delta.x > 0.0:
		t = minf(t, (cell.x + 1.0 - CELL_BORDER_MARGIN - from.x) / delta.x)
	elif delta.x < 0.0:
		t = minf(t, (cell.x + CELL_BORDER_MARGIN - from.x) / delta.x)
	if delta.y > 0.0:
		t = minf(t, (cell.y + 1.0 - CELL_BORDER_MARGIN - from.y) / delta.y)
	elif delta.y < 0.0:
		t = minf(t, (cell.y + CELL_BORDER_MARGIN - from.y) / delta.y)
	return from + delta * maxf(t, 0.0)


func _snapshot_occupancy() -> void:
	_occupied = [{}, {}]
	for unit: SimUnit in units:
		if unit.is_alive():
			_occupied[unit.faction][Vector2i(unit.position.floor())] = true


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
			# No body left: no corpse (GDD §6.7).
			if unit.integrity < 1:
				continue
			var corpse := SimCorpse.new()
			corpse.unit_id = unit.id
			corpse.unit_type = unit.unit_type
			corpse.position = unit.position
			corpse.ttl = rules.corpse_ticks
			corpse.integrity = unit.integrity
			corpse.reanimable = rng.randf() < reanimation_chance(unit.max_hp, rules)
			_insert_corpse(corpse)


# Keeps corpses sorted by unit ID: a lower ID can die after a higher one.
func _insert_corpse(corpse: SimCorpse) -> void:
	var index: int = corpses.size()
	while index > 0 and corpses[index - 1].unit_id > corpse.unit_id:
		index -= 1
	corpses.insert(index, corpse)


# Phase 7: reanimation, then rats' meals, then rat breeding (GDD §6.2).
# Units born here do not act until the next tick.
func _phase_periodic_abilities() -> void:
	for unit: SimUnit in units.duplicate():
		for ability: SimAbility in unit.abilities:
			ability.on_periodic(self, unit)
	HungerWill.run_meals(self)
	BreedAbility.run_breeding(self)


## The corpse of `unit_id`, or null if it is gone.
func corpse_of(unit_id: int) -> SimCorpse:
	for corpse: SimCorpse in corpses:
		if corpse.unit_id == unit_id:
			return corpse
	return null


## One bite of a corpse (GDD §6.8): integrity down by 1; at 0 the corpse disappears.
func eat(corpse: SimCorpse) -> void:
	corpse.integrity -= 1
	if corpse.integrity <= 0:
		corpses.erase(corpse)


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
