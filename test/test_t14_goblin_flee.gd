extends GdUnitTestSuite
## T14 — goblin flight (GDD §7).


func test_T14_goblin_flees() -> void:
	var world := TestWorlds.world(1)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
	var servant := TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)
	goblin.hp = 20
	var relic := world.map.relic_position()

	var distance := goblin.position.distance_to(relic)
	TestWorlds.run_until(world, 0)
	assert_int(goblin.state).is_equal(SimUnit.State.FLEE)
	var flee_starts := world.events.filter(func(event: Dictionary) -> bool:
		return event["type"] == "flee_start" and event["unit"] == goblin.id)
	assert_array(flee_starts).has_size(1)
	assert_float(goblin.position.distance_to(relic)).is_less(distance)

	while world.tick <= 19 and not world.is_over():
		distance = goblin.position.distance_to(relic)
		world.step()
		assert_int(servant.hp).is_equal(30)
		assert_float(goblin.position.distance_to(relic)).is_less(distance)
