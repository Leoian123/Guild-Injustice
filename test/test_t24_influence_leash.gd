extends GdUnitTestSuite
## T24 — influence leash (GDD §6.8).


func test_T24_undead_waits_at_influence_edge() -> void:
	var world := TestWorlds.world(1)
	var necromancer := TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(5, 5), false)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(12, 5), true)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 99)
	var position_after_99 := undead.position
	TestWorlds.run_until(world, 100)

	assert_float(undead.position.distance_to(necromancer.position)).is_less_equal(8.0)
	assert_vector(undead.position).is_equal(position_after_99)
