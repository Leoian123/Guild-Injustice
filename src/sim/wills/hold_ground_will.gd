class_name HoldGroundWill
extends SimWill
## Courage (GDD §6.8): chases only what it can reach within chase_radius of its post.
## Without a target it patrols around its post (GDD §6.6). Guards (GDD §7) do not chase at all
## and hold the room of the relic: they walk there, take a free cell of the room and patrol in it.

var has_patrol_point: bool = false
var patrol_point: Vector2 = Vector2.ZERO


func accepts(_world: World, unit: SimUnit, enemy: SimUnit) -> bool:
	if unit.guard:
		return unit.position.distance_to(enemy.position) <= unit.attack_range
	return unit.home.distance_to(enemy.position) <= unit.chase_radius + unit.attack_range


func idle_destination(world: World, unit: SimUnit) -> Variant:
	if unit.guard and not has_patrol_point:
		if not is_in_guarded_room(world, unit):
			return unit.home
		# Just entered the room: take a free cell right away (GDD §7).
		_pick_patrol_point(world, unit)
	return patrol_point if has_patrol_point else unit.home


## After a fight the unit goes back to its post before patrolling again.
func on_has_target(_world: World, _unit: SimUnit) -> void:
	has_patrol_point = false


func allows_kite_step(_world: World, unit: SimUnit, position: Vector2) -> bool:
	return unit.home.distance_to(position) <= unit.chase_radius


static func is_in_guarded_room(world: World, unit: SimUnit) -> bool:
	return world.relic_room.has_point(Vector2i(unit.position.floor()))


## Phase 3, before anyone moves: at ticks that are multiples of PATROL_PERIOD_TICKS (> 0),
## every unit with this will and without a target picks with the RNG, in ID order, a patrol cell:
## within PATROL_RADIUS of its post, or inside the room for a guard that has reached it.
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
		if unit.guard and not is_in_guarded_room(world, unit):
			continue
		(unit.will as HoldGroundWill)._pick_patrol_point(world, unit)


func _pick_patrol_point(world: World, unit: SimUnit) -> void:
	var cells := _patrol_cells(world, unit)
	if cells.is_empty():
		return
	patrol_point = SimMap.cell_center(cells[world.rng.randi_range(0, cells.size() - 1)])
	has_patrol_point = true


# Walkable cells without enemies, in row-major order: the room for guards, the circle of
# PATROL_RADIUS around the post for the others. Preferred: no allies and, for guards, not
# taken by another guard; if none, all of them.
static func _patrol_cells(world: World, unit: SimUnit) -> Array[Vector2i]:
	var enemies := world.enemy_cells(unit.faction)
	var taken := _cells_taken_by_other_guards(world, unit) if unit.guard else {}
	var area := world.relic_room if unit.guard else _circle_bounds(unit.home, world.rules.patrol_radius)
	var free: Array[Vector2i] = []
	var all: Array[Vector2i] = []
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if not world.map.is_walkable(cell) or enemies.has(cell):
				continue
			if not unit.guard and SimMap.cell_center(cell).distance_to(unit.home) > world.rules.patrol_radius:
				continue
			all.append(cell)
			if not taken.has(cell) and not _has_other_ally(world, unit, cell):
				free.append(cell)
	return free if not free.is_empty() else all


static func _circle_bounds(center: Vector2, radius: float) -> Rect2i:
	var low := Vector2i((center - Vector2(radius, radius)).floor())
	var high := Vector2i((center + Vector2(radius, radius)).floor())
	return Rect2i(low, high - low + Vector2i.ONE)


static func _cells_taken_by_other_guards(world: World, unit: SimUnit) -> Dictionary:
	var taken: Dictionary = {}
	for other: SimUnit in world.units:
		if other == unit or not other.is_alive() or not other.guard or not other.will is HoldGroundWill:
			continue
		var will := other.will as HoldGroundWill
		if will.has_patrol_point:
			taken[Vector2i(will.patrol_point.floor())] = true
	return taken


static func _has_other_ally(world: World, unit: SimUnit, cell: Vector2i) -> bool:
	for other: SimUnit in world.units:
		if other != unit and other.is_alive() and other.faction == unit.faction \
				and Vector2i(other.position.floor()) == cell:
			return true
	return false
