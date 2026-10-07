extends GdUnitTestSuite
## T12 (contested relic) and T13 (the timer resets), GDD §3.


func test_T12_contested_relic() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(20, 6), false)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(21, 6), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 199)
	assert_bool(world.is_over()).is_false()
	assert_int(world.relic_timer).is_equal(0)

	goblin.position = SimMap.cell_center(Vector2i(10, 6))
	TestWorlds.run_until(world, 298)
	assert_bool(world.is_over()).is_false()
	TestWorlds.run_until(world, 299)
	assert_str(world.reason).is_equal("relic_stolen")
	assert_int(world.end_tick).is_equal(299)


func test_T13_timer_resets() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(20, 6), false)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(10, 6), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 79)
	assert_int(world.relic_timer).is_equal(80)

	goblin.position = SimMap.cell_center(Vector2i(21, 6))
	TestWorlds.run_until(world, 80)
	assert_int(world.relic_timer).is_equal(0)

	goblin.position = SimMap.cell_center(Vector2i(10, 6))
	TestWorlds.run_until(world, 179)
	assert_bool(world.is_over()).is_false()
	TestWorlds.run_until(world, 180)
	assert_str(world.reason).is_equal("relic_stolen")
	assert_int(world.end_tick).is_equal(180)
