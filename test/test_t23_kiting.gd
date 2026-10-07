extends GdUnitTestSuite
## T23 — kiting of ranged units (GDD §6.8).


func test_T23_archer_backs_away_while_reloading() -> void:
	var world := TestWorlds.world(1)
	var archer := TestWorlds.spawn(world, &"archer", SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
	var servant := TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(6, 6), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 0)
	assert_int(servant.hp).is_equal(22)

	TestWorlds.run_until(world, 7)
	assert_float(archer.position.distance_to(servant.position)).is_greater(2.0)
	assert_vector(archer.facing).is_equal_approx(Vector2(-0.7071, -0.7071), Vector2(0.0001, 0.0001))

	TestWorlds.run_until(world, 29)
	assert_int(servant.hp).is_equal(22)

	TestWorlds.run_until(world, 30)
	assert_int(servant.hp).is_equal(14)
