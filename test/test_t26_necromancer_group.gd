extends GdUnitTestSuite
## T26 — the necromancer backs away only without undead around (GDD §6.8).


func test_T26_necromancer_holds_with_group() -> void:
	var world := TestWorlds.world(1)
	var necromancer := TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(5, 5), true)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(6, 6), false)
	TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(5, 8), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 0)
	assert_int(goblin.hp).is_equal(35)
	TestWorlds.run_until(world, 10)
	assert_vector(necromancer.position).is_equal(SimMap.cell_center(Vector2i(5, 5)))


func test_T26_necromancer_backs_away_alone() -> void:
	var world := TestWorlds.world(1)
	var necromancer := TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(5, 5), true)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(6, 6), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 0)
	assert_int(goblin.hp).is_equal(35)
	TestWorlds.run_until(world, 9)
	assert_float(necromancer.position.distance_to(goblin.position)).is_less_equal(2.0)
	TestWorlds.run_until(world, 10)
	assert_float(necromancer.position.distance_to(goblin.position)).is_greater(2.0)
	assert_vector(necromancer.facing).is_equal_approx(Vector2(-0.7071, -0.7071), Vector2(0.0001, 0.0001))
