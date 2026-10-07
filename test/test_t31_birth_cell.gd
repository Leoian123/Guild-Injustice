extends GdUnitTestSuite
## T31 — a newborn rat is born in a free cell; a full 3×3 pushes it to the next ring (GDD §7).


func test_T31_newborn_in_free_cell() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(5, 5), false)
	TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(7, 5), false)
	for cell: Vector2i in [Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(6, 5),
			Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6)]:
		TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, cell, false)
	TestWorlds.add_anchors(world)
	var count_before := world.units.size()

	TestWorlds.run_until(world, 100)
	assert_int(world.units.size()).is_equal(count_before + 1)
	var newborn := world.units[world.units.size() - 1]
	assert_str(String(newborn.unit_type)).is_equal("rat")
	var cell := Vector2i(newborn.position.floor())
	assert_vector(newborn.position).is_equal(SimMap.cell_center(cell))
	assert_int(maxi(absi(cell.x - 6), absi(cell.y - 5))).is_equal(2)
