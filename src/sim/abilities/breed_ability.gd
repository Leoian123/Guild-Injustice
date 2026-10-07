class_name BreedAbility
extends SimAbility
## Rat breeding (GDD §7). Breeding works on pairs, so it runs once per tick for the whole
## world (run_breeding); the component only marks who can breed.


## At ticks that are multiples of BREED_PERIOD_TICKS (> 0): every pair of eligible player
## rats within BREED_RADIUS, in (lower ID, higher ID) order, makes one rat, until the living
## player rats reach RAT_CAP. Eligible = alive, with BreedAbility, age ≥ NEWBORN_COOLDOWN_TICKS.
static func run_breeding(world: World) -> void:
	var rules := world.rules
	if world.tick == 0 or world.tick % rules.breed_period_ticks != 0:
		return
	var parents: Array[SimUnit] = []
	var rat_count: int = 0
	for unit: SimUnit in world.units:
		if not unit.is_alive() or unit.faction != SimUnit.Faction.PLAYER:
			continue
		if not unit.has_ability(BreedAbility):
			continue
		rat_count += 1
		if unit.age >= rules.newborn_cooldown_ticks:
			parents.append(unit)
	for i: int in parents.size():
		for j: int in range(i + 1, parents.size()):
			if rat_count >= rules.rat_cap:
				return
			var first := parents[i]
			var second := parents[j]
			if first.position.distance_to(second.position) > rules.breed_radius:
				continue
			var middle := (first.position + second.position) / 2.0
			var cells := _free_cells_near(world, Vector2i(middle.floor()))
			if cells.is_empty():
				continue
			var cell := cells[world.rng.randi_range(0, cells.size() - 1)]
			var newborn := world.spawn_newborn(first.data, first.faction, SimMap.cell_center(cell))
			# Test mode (docs/TESTS.md): a newborn of AI-off parents stays AI-off. Always true in play.
			newborn.ai_enabled = first.ai_enabled
			rat_count += 1


## Free cells (walkable, no living unit) of the 3×3 square around `center`; if none,
## of the next ring outward, and so on (GDD §7). Row-major order. Empty if the map has none.
## Occupancy only spreads births: units never block each other otherwise (GDD §6.3).
static func _free_cells_near(world: World, center: Vector2i) -> Array[Vector2i]:
	var occupied: Dictionary = {}
	for unit: SimUnit in world.units:
		if unit.is_alive():
			occupied[Vector2i(unit.position.floor())] = true
	var max_ring: int = maxi(world.map.width, world.map.height)
	for ring: int in range(1, max_ring + 1):
		var cells: Array[Vector2i] = []
		for y: int in range(center.y - ring, center.y + ring + 1):
			for x: int in range(center.x - ring, center.x + ring + 1):
				var cell := Vector2i(x, y)
				# Ring 1 is the whole 3×3; later rings are only their border.
				if ring > 1 and maxi(absi(x - center.x), absi(y - center.y)) != ring:
					continue
				if world.map.is_walkable(cell) and not occupied.has(cell):
					cells.append(cell)
		if not cells.is_empty():
			return cells
	return []
