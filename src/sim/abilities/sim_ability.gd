class_name SimAbility
extends SimState
## Ability component (GDD §7, §8). One instance per unit, so abilities may keep per-unit
## state; that state reaches the state_hash on its own (SimState).


## Builds the ability named in UnitData.abilities.
static func create(ability_name: StringName) -> SimAbility:
	match ability_name:
		&"WanderBehavior":
			return WanderBehavior.new()
		&"BreedAbility":
			return BreedAbility.new()
		&"PackCourageAbility":
			return PackCourageAbility.new()
		&"PointBlankPenalty":
			return PointBlankPenalty.new()
		&"BackstabAbility":
			return BackstabAbility.new()
		&"ArmorAbility":
			return ArmorAbility.new()
		&"ReanimateAbility":
			return ReanimateAbility.new()
		&"FearlessTrait":
			return FearlessTrait.new()
	push_error("SimAbility: unknown ability '%s'" % ability_name)
	return null


## Phase 1: per-unit timers and state changes (flee).
func on_tick_start(_world: World, _unit: SimUnit) -> void:
	pass


## Phase 2: preferred target among the acceptable ones; null = common rule.
func preferred_target(_world: World, _unit: SimUnit, _candidates: Array[SimUnit]) -> SimUnit:
	return null


## Phase 3: where to go when chasing `target`; null = straight at the target.
func approach_point(_world: World, _unit: SimUnit, _target: SimUnit) -> Variant:
	return null


## Phase 3: where to go without a target, if the will has no destination; null = stay.
func idle_destination(_world: World, _unit: SimUnit) -> Variant:
	return null


## Phase 4, attacker side: damage multiplier, from the snapshot only.
func damage_multiplier(_attacker: SimUnit, _target: SimUnit, _snapshot: SimSnapshot, _rules: RulesData) -> float:
	return 1.0


## Phase 4, target side: flat damage reduction, from the snapshot only.
func damage_reduction(_target: SimUnit, _attacker: SimUnit, _snapshot: SimSnapshot, _rules: RulesData) -> int:
	return 0


## Phase 7: periodic action of this unit (reanimation).
func on_periodic(_world: World, _unit: SimUnit) -> void:
	pass


## True for FearlessTrait: the unit never enters FLEE.
func prevents_flee() -> bool:
	return false
