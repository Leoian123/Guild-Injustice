extends GdUnitTestSuite
## T25 — mindless units attack whoever contests the relic (GDD §6.8, §3).


func test_T25_mindless_attacks_relic_contender() -> void:
	var world := TestWorlds.world(1)
	var servant := TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(18, 6), true)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(21, 6), false)
	goblin.position = Vector2(21.7, 6.5)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 0)
	assert_int(servant.target_id).is_equal(goblin.id)

	TestWorlds.run_until(world, 100)
	assert_int(goblin.hp).is_less(45)
