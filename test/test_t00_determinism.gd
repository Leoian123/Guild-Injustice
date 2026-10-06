extends GdUnitTestSuite
## T00 — basic determinism (GDD §12).


func test_T00_basic_determinism() -> void:
	var first := _anchored_world(7)
	var second := _anchored_world(7)
	var third := _anchored_world(8)
	for world: World in [first, second, third]:
		for i: int in 100:
			world.step()

	assert_str(first.state_hash()).is_equal(second.state_hash())
	assert_int(third.rng.state).is_not_equal(first.rng.state)
	assert_int(third.rng.state).is_not_equal(second.rng.state)


func _anchored_world(seed_value: int) -> World:
	var world := TestWorlds.world(seed_value)
	TestWorlds.add_anchors(world)
	return world
