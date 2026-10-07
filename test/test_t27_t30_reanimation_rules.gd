extends GdUnitTestSuite
## T27 (flesh shields), T28 (end of the chain), T29 (reanimation roll), T30 (the bolt).
## GDD §6.7, §8.

const PLAYER := SimUnit.Faction.PLAYER
const ENEMY := SimUnit.Faction.ENEMY


func test_T27_flesh_shields() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", ENEMY, Vector2i(5, 5), false)
	var rat := TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(7, 5), false)
	var goblin := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(5, 9), false)
	TestWorlds.add_anchors(world)
	rat.hp = 0
	goblin.hp = 0

	TestWorlds.run_until(world, 0)
	var risen := world.units[world.units.size() - 1]
	assert_str(String(risen.unit_type)).is_equal("goblin")
	assert_int(risen.faction).is_equal(ENEMY)
	assert_int(risen.hp).is_equal(22)
	assert_array(world.corpses).has_size(1)
	assert_int(world.corpses[0].unit_id).is_equal(rat.id)


func test_T28_end_of_the_chain() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", ENEMY, Vector2i(5, 5), false)
	var rat := TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(9, 5), false)
	TestWorlds.add_anchors(world)
	rat.hp = 0

	var expected_hp: Array[int] = [10, 5, 2, 1]
	for i: int in expected_hp.size():
		var rise_tick: int = i * 120
		TestWorlds.run_until(world, rise_tick)
		var risen := world.units[world.units.size() - 1]
		assert_int(risen.hp).override_failure_message("rise at tick %d" % rise_tick).is_equal(expected_hp[i])
		risen.hp = 0
	TestWorlds.run_until(world, 361)
	assert_array(world.corpses).is_empty()
	var unit_count := world.units.size()
	TestWorlds.run_until(world, 480)
	assert_int(world.units.size()).is_equal(unit_count)


func test_T29_reanimation_roll() -> void:
	assert_float(World.reanimation_chance(20, TestWorlds.rules_with_k(1.0))).is_equal_approx(0.952, 0.001)

	var world := TestWorlds.world(1, [], TestWorlds.rules_with_k(1000000.0))
	TestWorlds.spawn(world, &"necromancer", ENEMY, Vector2i(5, 5), false)
	var rat := TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(9, 5), false)
	TestWorlds.add_anchors(world)
	rat.hp = 0

	TestWorlds.run_until(world, 0)
	assert_array(world.corpses).has_size(1)
	assert_bool(world.corpses[0].reanimable).is_false()
	for unit: SimUnit in world.units:
		assert_bool(unit.faction == ENEMY and unit.unit_type == &"rat").is_false()


func test_T30_the_bolt() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", ENEMY, Vector2i(5, 5), true)
	# The goblin is nearer than the rats, so the bolt flies at tick 0, 40, 80 and is ready
	# again at tick 120, together with the reanimation.
	var goblin := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(8, 5), false)
	var rat_a := TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(5, 9), false)
	var rat_b := TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(5, 10), false)
	TestWorlds.add_anchors(world)
	rat_a.hp = 0
	rat_b.hp = 0

	TestWorlds.run_until(world, 0)
	assert_int(goblin.hp).is_equal(35)
	var first_risen := world.units[world.units.size() - 1]
	first_risen.hp = 0

	TestWorlds.run_until(world, 119)
	assert_int(goblin.hp).is_equal(15)
	var count_before := world.units.size()
	TestWorlds.run_until(world, 120)
	assert_int(goblin.hp).is_equal(15)
	assert_int(world.units.size()).is_equal(count_before + 1)
	var second_risen := world.units[world.units.size() - 1]
	assert_str(String(second_risen.unit_type)).is_equal("rat")
	assert_int(second_risen.faction).is_equal(ENEMY)
	assert_int(second_risen.hp).is_equal(10)
	TestWorlds.run_until(world, 121)
	assert_int(goblin.hp).is_equal(5)
