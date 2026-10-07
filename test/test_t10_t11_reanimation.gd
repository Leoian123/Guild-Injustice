extends GdUnitTestSuite
## T10 (reanimation) and T11 (no double reanimation), GDD §8.


func test_T10_T11_reanimation() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(5, 5), false)
	var rat := TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(9, 5), false)
	TestWorlds.add_anchors(world)
	rat.hp = 0

	TestWorlds.run_until(world, 0)
	var risen := world.units[world.units.size() - 1]
	assert_str(String(risen.unit_type)).is_equal("rat")
	assert_int(risen.faction).is_equal(SimUnit.Faction.ENEMY)
	assert_int(risen.hp).is_equal(20)
	for unit: SimUnit in world.units:
		if unit != risen:
			assert_int(risen.id).is_greater(unit.id)
	assert_bool(risen.has_ability(BreedAbility)).is_false()
	assert_array(world.corpses).is_empty()

	# T11: the reanimated rat dies and leaves no corpse.
	risen.hp = 0
	TestWorlds.run_until(world, 1)
	assert_int(risen.state).is_equal(SimUnit.State.DEAD)
	assert_array(world.corpses).is_empty()
