extends GdUnitTestSuite
## T32 (position first, then backstab) and T33 (swarm), GDD §7.


func test_T32_thief_positions_before_striking() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"thief", SimUnit.Faction.PLAYER, Vector2i(5, 3), true)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(5, 5), false)
	TestWorlds.add_anchors(world)
	undead.facing = Vector2(0, -1)
	_assert_hits_are_multiples(world, undead, 24)


func test_T32_wall_behind_means_frontal_hits() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"thief", SimUnit.Faction.PLAYER, Vector2i(5, 3), true)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(5, 1), false)
	TestWorlds.add_anchors(world)
	undead.facing = Vector2(0, 1)
	_assert_hits_are_multiples(world, undead, 6)


func test_T34_thief_hits_a_target_walking_away() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"thief", SimUnit.Faction.PLAYER, Vector2i(3, 6), true)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(6, 6), true)
	TestWorlds.add_anchors(world)

	TestWorlds.run_until(world, 60)
	assert_int(undead.hp).is_less(80)


func test_T33_swarm_moves_together() -> void:
	var world := TestWorlds.world(1)
	var rats: Array[SimUnit] = []
	for cell: Vector2i in [Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(9, 4), Vector2i(10, 4)]:
		rats.append(TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, cell, true))
	TestWorlds.add_anchors(world)
	var starts: Array[Vector2] = []
	for rat: SimUnit in rats:
		starts.append(rat.position)

	TestWorlds.run_until(world, 19)
	for i: int in rats.size():
		assert_vector(rats[i].position).is_equal(starts[i])

	# Nobody moved before tick 20, so the vote happens from the start positions.
	TestWorlds.run_until(world, 20)
	var direction := _wander(rats[0]).direction
	assert_int(direction).is_not_equal(-1)
	for i: int in rats.size():
		var wander := _wander(rats[i])
		assert_int(wander.direction).is_equal(direction)
		assert_bool(wander.has_destination).is_true()
		assert_float(wander.destination.distance_to(starts[i])).is_less_equal(world.rules.wander_radius + 0.0001)


# Until tick 60 every loss of HP is a multiple of `hit`; after tick 60 the target was hit.
func _assert_hits_are_multiples(world: World, target: SimUnit, hit: int) -> void:
	while world.tick <= 60 and not world.is_over():
		var tick := world.tick
		world.step()
		assert_int((target.max_hp - target.hp) % hit) \
			.override_failure_message("HP %d after tick %d" % [target.hp, tick]).is_equal(0)
	assert_int(target.hp).is_less(target.max_hp)


func _wander(rat: SimUnit) -> WanderBehavior:
	for ability: SimAbility in rat.abilities:
		if ability is WanderBehavior:
			return ability
	return null
