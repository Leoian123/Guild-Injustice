extends GdUnitTestSuite
## T10 (reanimation) and T11 (chain reanimation), GDD §6.7, §8. Neutralized dice.


func test_T10_reanimation() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(5, 5), false)
	var goblin := TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(9, 5), false)
	TestWorlds.add_anchors(world)
	goblin.hp = 0

	TestWorlds.run_until(world, 0)
	var risen := _last_unit(world)
	assert_str(String(risen.unit_type)).is_equal("goblin")
	assert_int(risen.faction).is_equal(SimUnit.Faction.ENEMY)
	assert_int(risen.hp).is_equal(25)
	assert_int(risen.integrity).is_equal(0)
	for unit: SimUnit in world.units:
		if unit != risen:
			assert_int(risen.id).is_greater(unit.id)
	assert_bool(risen.has_ability(PackCourageAbility)).is_false()
	assert_array(world.corpses).is_empty()


func test_T11_chain_reanimation() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(5, 5), false)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(9, 5), false)
	TestWorlds.add_anchors(world)
	undead.hp = 0

	TestWorlds.run_until(world, 0)
	var risen := _last_unit(world)
	assert_str(String(risen.unit_type)).is_equal("undead")
	assert_int(risen.hp).is_equal(75)
	assert_int(risen.integrity).is_equal(2)

	risen.hp = 0
	TestWorlds.run_until(world, 1)
	assert_array(world.corpses).has_size(1)
	assert_int(world.corpses[0].unit_id).is_equal(risen.id)
	assert_bool(world.corpses[0].reanimable).is_true()
	assert_int(world.corpses[0].integrity).is_equal(2)
	TestWorlds.run_until(world, 119)
	assert_array(world.corpses).has_size(1)
	TestWorlds.run_until(world, 120)
	var second := _last_unit(world)
	assert_int(second.id).is_greater(risen.id)
	assert_str(String(second.unit_type)).is_equal("undead")
	assert_int(second.hp).is_equal(50)
	assert_array(world.corpses).is_empty()


func _last_unit(world: World) -> SimUnit:
	return world.units[world.units.size() - 1]
