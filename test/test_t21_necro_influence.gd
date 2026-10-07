extends GdUnitTestSuite
## T21 — necromancer influence, NecroBoundWill (GDD §6.8).


func test_T21_influenced_undead_hunts() -> void:
	var world := TestWorlds.world(1)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(10, 5), true)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(10, 2), false)
	TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(8, 5), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 0)
	assert_int(undead.target_id).is_equal(goblin.id)

	TestWorlds.run_until(world, 60)
	assert_int(goblin.hp).is_less(45)
