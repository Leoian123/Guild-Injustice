class_name World
extends RefCounted
## Deterministic fixed-tick simulation (GDD §6.2, §12).

var rules: RulesData
var rng: RandomNumberGenerator
## Index of the next tick to run. Ticks are numbered from 0 (GDD §6.1).
var tick: int = 0
var relic_timer: int = 0
## Kept sorted by ascending ID: IDs only grow.
var units: Array[SimUnit] = []
## Kept sorted by ascending unit ID.
var corpses: Array[SimCorpse] = []

var _next_id: int = 1


func _init(p_rules: RulesData, p_seed: int) -> void:
	rules = p_rules
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed


func spawn_unit(data: UnitData, faction: SimUnit.Faction, position: Vector2) -> SimUnit:
	var unit := SimUnit.new(_next_id, data, faction, position)
	_next_id += 1
	units.append(unit)
	return unit


func step() -> void:
	_phase_states()
	_phase_targets()
	_phase_movement()
	_phase_attacks()
	_phase_damage()
	_phase_deaths()
	_phase_periodic_abilities()
	_phase_battle_end()
	tick += 1


func state_hash() -> String:
	var lines: PackedStringArray = []
	lines.append("tick=%d" % tick)
	lines.append("relic_timer=%d" % relic_timer)
	lines.append("rng_state=%d" % rng.state)
	for unit: SimUnit in units:
		lines.append("%d|%s|%s|%s|%d|%s|%s|%s|%s|%d|%d" % [
			unit.id,
			unit.unit_type,
			SimUnit.Faction.keys()[unit.faction],
			SimUnit.State.keys()[unit.state],
			unit.hp,
			_fmt(unit.position.x),
			_fmt(unit.position.y),
			_fmt(unit.facing.x),
			_fmt(unit.facing.y),
			unit.target_id,
			unit.attack_cd,
		])
	for corpse: SimCorpse in corpses:
		lines.append("corpse|%d|%s|%s|%s|%d" % [
			corpse.unit_id,
			corpse.unit_type,
			_fmt(corpse.position.x),
			_fmt(corpse.position.y),
			corpse.ttl,
		])
	return ("\n".join(lines) + "\n").sha256_text()


static func _fmt(value: float) -> String:
	return "%.4f" % value


# Phase 1: timers and cooldowns, flee enter/exit.
func _phase_states() -> void:
	pass


# Phase 2: target selection (GDD §6.4).
func _phase_targets() -> void:
	pass


# Phase 3: movement (GDD §6.3).
func _phase_movement() -> void:
	pass


# Phase 4: attacks computed from a snapshot (GDD §6.5).
func _phase_attacks() -> void:
	pass


# Phase 5: damage applied all at once.
func _phase_damage() -> void:
	pass


# Phase 6: deaths and corpses (GDD §6.7).
func _phase_deaths() -> void:
	pass


# Phase 7: reanimation, then rat breeding.
func _phase_periodic_abilities() -> void:
	pass


# Phase 8: end of battle (GDD §3).
func _phase_battle_end() -> void:
	pass
