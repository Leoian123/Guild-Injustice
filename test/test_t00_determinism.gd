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


# Extension from M3: same check on a world where units move and fight.
func test_T00_determinism_with_combat() -> void:
	var first := _combat_world(7)
	var second := _combat_world(7)
	var third := _combat_world(8)
	for world: World in [first, second, third]:
		for i: int in 400:
			world.step()

	assert_str(first.state_hash()).is_equal(second.state_hash())
	assert_int(third.rng.state).is_not_equal(first.rng.state)
	# The scenario must actually fight, or the check proves nothing.
	assert_array(first.corpses).is_not_empty()
	for unit: SimUnit in first.units:
		if not unit.ai_enabled:
			assert_int(unit.hp).override_failure_message("anchor %d was hit" % unit.id).is_equal(unit.max_hp)


func _anchored_world(seed_value: int) -> World:
	var world := TestWorlds.world(seed_value)
	TestWorlds.add_anchors(world)
	return world


# Kept out of the anchors' reach: the anchors must survive.
func _combat_world(seed_value: int) -> World:
	var world := TestWorlds.world(seed_value)
	TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(13, 2), true)
	TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(13, 4), true)
	TestWorlds.spawn(world, &"archer", SimUnit.Faction.PLAYER, Vector2i(16, 3), true)
	TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(4, 2), true)
	TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(4, 4), true)
	TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(3, 3), true)
	TestWorlds.add_anchors(world)
	return world
