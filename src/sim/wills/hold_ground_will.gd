class_name HoldGroundWill
extends SimWill
## Courage (GDD §6.8): chases only what it can reach within chase_radius of its post.
## Without a target it patrols around its post (GDD §6.6). Guards (GDD §7) do not chase at all.

var has_patrol_point: bool = false
var patrol_point: Vector2 = Vector2.ZERO


func accepts(_world: World, unit: SimUnit, enemy: SimUnit) -> bool:
	if unit.guard:
		return unit.position.distance_to(enemy.position) <= unit.attack_range
	return unit.home.distance_to(enemy.position) <= unit.chase_radius + unit.attack_range


func idle_destination(_world: World, unit: SimUnit) -> Variant:
	return patrol_point if has_patrol_point else unit.home


## After a fight the unit goes back to its post before patrolling again.
func on_has_target(_world: World, _unit: SimUnit) -> void:
	has_patrol_point = false


func allows_kite_step(_world: World, unit: SimUnit, position: Vector2) -> bool:
	return unit.home.distance_to(position) <= unit.chase_radius


## Phase 3, before anyone moves: at ticks that are multiples of PATROL_PERIOD_TICKS (> 0),
## every idle unit with this will picks with the RNG, in ID order, a walkable cell without
## enemies within its patrol radius of its post, preferring cells without allies.
static func run_patrols(world: World) -> void:
	var period := world.rules.patrol_period_ticks
	if period <= 0 or world.tick == 0 or world.tick % period != 0:
		return
	for unit: SimUnit in world.units:
		if not unit.is_alive() or not unit.ai_enabled or not unit.will is HoldGroundWill:
			continue
		# "Every unit without a target" (GDD §6.6), fleeing ones included: the roll is taken anyway.
		if unit.target_id != SimUnit.NO_TARGET:
			continue
		var radius := world.rules.guard_patrol_radius if unit.guard else world.rules.patrol_radius
		var cells := _patrol_cells(world, unit, radius)
		if cells.is_empty():
			continue
		var will := unit.will as HoldGroundWill
		will.patrol_point = SimMap.cell_center(cells[world.rng.randi_range(0, cells.size() - 1)])
		will.has_patrol_point = true


# Candidate cells in row-major order: without allies if any, otherwise all of them.
static func _patrol_cells(world: World, unit: SimUnit, radius: float) -> Array[Vector2i]:
	var enemies := world.enemy_cells(unit.faction)
	var free: Array[Vector2i] = []
	var all: Array[Vector2i] = []
	var low := Vector2i((unit.home - Vector2(radius, radius)).floor())
	var high := Vector2i((unit.home + Vector2(radius, radius)).floor())
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			var cell := Vector2i(x, y)
			if not world.map.is_walkable(cell) or enemies.has(cell):
				continue
			if SimMap.cell_center(cell).distance_to(unit.home) > radius:
				continue
			all.append(cell)
			if not _has_other_ally(world, unit, cell):
				free.append(cell)
	return free if not free.is_empty() else all


static func _has_other_ally(world: World, unit: SimUnit, cell: Vector2i) -> bool:
	for other: SimUnit in world.units:
		if other != unit and other.is_alive() and other.faction == unit.faction \
				and Vector2i(other.position.floor()) == cell:
			return true
	return false
