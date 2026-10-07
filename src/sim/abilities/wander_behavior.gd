class_name WanderBehavior
extends SimAbility
## Rat wandering (GDD §7): without a target, every WANDER_PERIOD_TICKS ticks since its last
## random move it picks with the RNG a walkable cell within WANDER_RADIUS and goes there.

var has_picked: bool = false
var last_pick_tick: int = 0
var destination: Vector2 = Vector2.ZERO


func idle_destination(world: World, unit: SimUnit) -> Variant:
	if not has_picked or world.tick - last_pick_tick >= world.rules.wander_period_ticks:
		var cells := world.walkable_cells_within(unit.position, world.rules.wander_radius)
		if cells.is_empty():
			return null
		destination = SimMap.cell_center(cells[world.rng.randi_range(0, cells.size() - 1)])
		has_picked = true
		last_pick_tick = world.tick
	return destination
