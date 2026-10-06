extends GdUnitTestSuite
## T02 — simultaneous damage (GDD §6.2).


func test_T02_simultaneous_damage() -> void:
	var world := TestWorlds.world(1)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(5, 5), false)
	var servant := TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(6, 5), false)
	goblin.hp = 1
	servant.hp = 1
	goblin.forced_target_id = servant.id
	servant.forced_target_id = goblin.id

	world.step()

	assert_int(goblin.state).is_equal(SimUnit.State.DEAD)
	assert_int(servant.state).is_equal(SimUnit.State.DEAD)
