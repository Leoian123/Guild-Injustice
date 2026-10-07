extends GdUnitTestSuite
## T20 — hunger, HungerWill (GDD §6.8). The test rat has no WanderBehavior.


func test_T20_rat_bites_until_sated() -> void:
	var world := TestWorlds.world(1)
	var rat := TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(6, 5), false)
	TestWorlds.add_anchors(world)
	var hunger := rat.will as HungerWill

	TestWorlds.run_until(world, 32)
	assert_int(undead.hp).is_equal(71)
	assert_bool(hunger.is_sated()).is_true()

	TestWorlds.run_until(world, 33)
	assert_int(rat.target_id).is_equal(SimUnit.NO_TARGET)

	TestWorlds.run_until(world, 131)
	assert_int(undead.hp).is_equal(71)

	TestWorlds.run_until(world, 132)
	assert_int(undead.hp).is_equal(68)
