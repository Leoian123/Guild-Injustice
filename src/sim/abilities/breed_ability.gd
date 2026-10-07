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
			var cells := world.walkable_cells_within(middle, 1.0)
			if cells.is_empty():
				continue
			var cell := cells[world.rng.randi_range(0, cells.size() - 1)]
			world.spawn_newborn(first.data, first.faction, SimMap.cell_center(cell))
			rat_count += 1
