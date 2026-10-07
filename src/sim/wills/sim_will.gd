class_name SimWill
extends SimState
## Will to fight (GDD §6.8): decides which noticed enemies a unit accepts as target,
## where it goes without a target and how far it lets itself be pulled.
## One instance per unit: wills may keep per-unit state.


## Builds the will named in UnitData.will.
static func create(will_name: StringName) -> SimWill:
	match will_name:
		&"HoldGroundWill":
			return HoldGroundWill.new()
		&"HungerWill":
			return HungerWill.new()
		&"NecroBoundWill":
			return NecroBoundWill.new()
	push_error("SimWill: unknown will '%s'" % will_name)
	return null


## Called once when the unit enters the world.
func on_spawn(_world: World, _unit: SimUnit) -> void:
	pass


## Phase 1: per-unit timers.
func on_tick_start(_world: World, _unit: SimUnit) -> void:
	pass


## Phase 2: whether a noticed enemy is an acceptable target.
func accepts(_world: World, _unit: SimUnit, _enemy: SimUnit) -> bool:
	return true


## Phase 3: where the unit goes without a target; null = it stays.
func idle_destination(_world: World, _unit: SimUnit) -> Variant:
	return null


## Phase 3: whether any step may end at `position` (influence leash).
func allows_step(_world: World, _unit: SimUnit, _position: Vector2) -> bool:
	return true


## Phase 3: whether a ranged unit may back away from close enemies.
func may_kite(_world: World, _unit: SimUnit) -> bool:
	return true


## Phase 3: whether a kiting step may end at `position`.
func allows_kite_step(_world: World, _unit: SimUnit, _position: Vector2) -> bool:
	return true


## Phase 4: the unit landed an attack.
func on_attack_landed(_world: World, _unit: SimUnit) -> void:
	pass
