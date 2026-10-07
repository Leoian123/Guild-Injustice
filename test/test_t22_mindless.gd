extends GdUnitTestSuite
## T22 — mindless undead (GDD §6.8): T21 without a living necromancer.


func test_T22_mindless_without_necromancer() -> void:
	var world := TestWorlds.world(1)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(10, 5), true)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(10, 2), false)
	TestWorlds.add_anchors(world)
	_assert_mindless(world, undead, goblin, 0)


func test_T22_mindless_after_necromancer_dies() -> void:
	var world := TestWorlds.world(1)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(10, 5), true)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(10, 2), false)
	var necromancer := TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(8, 5), false)
	TestWorlds.add_anchors(world)
	necromancer.hp = 0
	_assert_mindless(world, undead, goblin, 1)


# From tick `first_mindless` to tick 60 the undead has no target; after tick 60 the goblin
# is untouched and the undead is closer to the relic than at the start.
func _assert_mindless(world: World, undead: SimUnit, goblin: SimUnit, first_mindless: int) -> void:
	var relic := world.map.relic_position()
	var start_distance := undead.position.distance_to(relic)
	while world.tick <= 60:
		var tick := world.tick
		world.step()
		if tick >= first_mindless:
			assert_int(undead.target_id) \
				.override_failure_message("target after tick %d" % tick).is_equal(SimUnit.NO_TARGET)
	assert_int(goblin.hp).is_equal(45)
	assert_float(undead.position.distance_to(relic)).is_less(start_distance)
