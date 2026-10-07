extends GdUnitTestSuite
## T19 — courage, HoldGroundWill (GDD §6.8).


func test_T19_hold_ground_drops_far_target() -> void:
	var world := TestWorlds.world(1)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(10, 5), false)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 59)
	assert_int(goblin.target_id).is_equal(undead.id)

	var distance_before := goblin.position.distance_to(goblin.home)
	undead.position = SimMap.cell_center(Vector2i(13, 5))
	TestWorlds.run_until(world, 60)
	assert_int(goblin.target_id).is_equal(SimUnit.NO_TARGET)
	assert_float(goblin.position.distance_to(goblin.home)).is_less(distance_before)
