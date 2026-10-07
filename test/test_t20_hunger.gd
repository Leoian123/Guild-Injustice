extends GdUnitTestSuite
## T20 (the scavenger's hunger) and T43 (a corpse eaten up), GDD §6.7, §6.8.
## The test rat has no WanderBehavior, so it stays still while sated.


func test_T20_scavenger_eats_a_corpse() -> void:
	var world := TestWorlds.world(1)
	var rat := _rat(world)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)
	undead.hp = 0
	var hunger := rat.will as HungerWill

	TestWorlds.run_until(world, 198)
	assert_int(world.corpse_of(undead.id).integrity).is_equal(3)
	assert_bool(hunger.is_sated()).is_true()
	TestWorlds.run_until(world, 199)
	assert_bool(hunger.is_sated()).is_false()
	TestWorlds.run_until(world, 220)
	assert_int(world.corpse_of(undead.id).integrity).is_equal(2)
	assert_bool(hunger.is_sated()).is_true()


func test_T43_corpse_eaten_up() -> void:
	var world := TestWorlds.world(1)
	var rat := _rat(world)
	var servant := TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)
	servant.hp = 0

	TestWorlds.run_until(world, 220)
	assert_array(world.corpses).is_empty()
	assert_bool((rat.will as HungerWill).is_sated()).is_true()


func _rat(world: World) -> SimUnit:
	var data := TestWorlds.without_ability(&"rat", &"WanderBehavior")
	return TestWorlds.spawn_data(world, data, SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
