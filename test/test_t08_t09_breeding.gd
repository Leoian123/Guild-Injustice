extends GdUnitTestSuite
## T08 (breeding) and T09 (rat cap), GDD §7.


func test_T08_breeding() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(5, 5), false)
	TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 99)
	assert_int(_player_rats(world)).is_equal(2)
	TestWorlds.run_until(world, 100)
	assert_int(_player_rats(world)).is_equal(3)
	TestWorlds.run_until(world, 199)
	assert_int(_player_rats(world)).is_equal(3)
	# The parents are hungry from tick 199 and the newborn alone makes no pair (rats breed sated).
	TestWorlds.run_until(world, 200)
	assert_int(_player_rats(world)).is_equal(3)


func test_T09_rat_cap() -> void:
	var world := TestWorlds.world(1)
	for cell: Vector2i in [Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6)]:
		TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, cell, false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 100)
	assert_int(_player_rats(world)).is_equal(21)
	TestWorlds.run_until(world, 200)
	assert_int(_player_rats(world)).is_equal(50)
	while world.tick <= 1000 and not world.is_over():
		world.step()
		assert_int(_player_rats(world)).is_less_equal(50)


func _player_rats(world: World) -> int:
	var count: int = 0
	for unit: SimUnit in world.units:
		if unit.is_alive() and unit.faction == SimUnit.Faction.PLAYER and unit.unit_type == &"rat":
			count += 1
	return count
