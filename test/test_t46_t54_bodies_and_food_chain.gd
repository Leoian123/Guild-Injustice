extends GdUnitTestSuite
## M6.1: T46–T48 solid bodies (GDD §6.3), T49–T54 swarm damage, breeding, rabbits (GDD §6.5, §7).

const PLAYER := SimUnit.Faction.PLAYER
const ENEMY := SimUnit.Faction.ENEMY


func test_T46_allies_are_solid() -> void:
	var world := TestWorlds.world(1)
	var walker := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(5, 5), true)
	TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(7, 5), false)
	var undead := TestWorlds.spawn(world, &"undead", ENEMY, Vector2i(9, 5), false)
	TestWorlds.add_anchors(world)
	while world.tick <= 60 and not world.is_over():
		var tick := world.tick
		world.step()
		assert_bool(Vector2i(walker.position.floor()) == Vector2i(7, 5)) \
			.override_failure_message("walker in the ally's cell after tick %d" % tick).is_false()
	assert_int(undead.hp).is_less(80)


func test_T47_allies_swap_in_a_corridor() -> void:
	var walls: Array[Vector2i] = []
	for x: int in range(3, 13):
		walls.append(Vector2i(x, 4))
		walls.append(Vector2i(x, 6))
	var world := TestWorlds.world(1, walls)
	var a := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(11, 5), true)
	var b := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(4, 5), true)
	TestWorlds.add_anchors(world)
	a.position = SimMap.cell_center(Vector2i(4, 5))
	b.position = SimMap.cell_center(Vector2i(11, 5))
	# They have crossed in the corridor; from tick 60 they patrol around their posts.
	TestWorlds.run_until(world, 200)
	assert_float(a.position.x).is_greater(8.0)
	assert_float(b.position.x).is_less(8.0)


func test_T48_non_solid_units_pass() -> void:
	var walls: Array[Vector2i] = []
	for y: int in range(1, 11):
		if y != 5:
			walls.append(Vector2i(10, y))
	var world := TestWorlds.world(1, walls)
	var ghost_data := TestWorlds.unit_data(&"servant").duplicate() as UnitData
	ghost_data.solid = false
	var ghost := TestWorlds.spawn_data(world, ghost_data, ENEMY, Vector2i(5, 5), true)
	var plug := TestWorlds.spawn(world, &"servant", ENEMY, Vector2i(10, 5), false)
	TestWorlds.add_anchors(world)
	var plug_position := plug.position
	var entered: bool = false
	while world.tick <= 100 and not world.is_over():
		world.step()
		assert_vector(plug.position).override_failure_message("the plug was moved (a swap)").is_equal(plug_position)
		if Vector2i(ghost.position.floor()) == Vector2i(10, 5):
			entered = true
	assert_bool(entered).is_true()


func test_T49_swarm_damage() -> void:
	var alone := TestWorlds.unit(1, &"rat", PLAYER, Vector2i(5, 5))
	var undead := TestWorlds.unit(2, &"undead", ENEMY, Vector2i(5, 6))
	assert_int(_damage(alone, undead, [alone, undead])).is_equal(1)

	var rat := TestWorlds.unit(1, &"rat", PLAYER, Vector2i(5, 5))
	var second := TestWorlds.unit(2, &"rat", PLAYER, Vector2i(7, 5))
	var third := TestWorlds.unit(3, &"rat", PLAYER, Vector2i(9, 5))
	var target := TestWorlds.unit(4, &"undead", ENEMY, Vector2i(5, 6))
	assert_int(_damage(rat, target, [rat, second, third, target])).is_equal(3)


func test_T50_only_sated_rats_breed() -> void:
	var rules := TestWorlds.rules().duplicate() as RulesData
	rules.rat_digest_ticks = 50
	var world := TestWorlds.world(1, [], rules)
	TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(5, 5), false)
	TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)
	TestWorlds.run_until(world, 100)
	assert_int(_count(world, &"rat", PLAYER)).is_equal(2)


func test_T51_rabbits() -> void:
	var world := TestWorlds.world(1)
	TestWorlds.spawn(world, &"rabbit", PLAYER, Vector2i(5, 5), false)
	TestWorlds.spawn(world, &"rabbit", PLAYER, Vector2i(7, 5), false)
	var undead := TestWorlds.spawn(world, &"undead", ENEMY, Vector2i(6, 6), false)
	TestWorlds.add_anchors(world)
	TestWorlds.run_until(world, 100)
	assert_int(_count(world, &"rabbit", PLAYER)).is_equal(3)
	TestWorlds.run_until(world, 200)
	assert_int(undead.hp).is_equal(80)


func test_T52_rat_hunts_rabbit() -> void:
	var world := TestWorlds.world(1, [], _hungry_rules())
	_rat(world)
	var rabbit := TestWorlds.spawn(world, &"rabbit", PLAYER, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)
	TestWorlds.run_until(world, 100)
	assert_bool(rabbit.is_alive()).is_false()
	assert_array(world.corpses).is_empty()


func test_T53_den_invader_first() -> void:
	var world := TestWorlds.world(1, [], _hungry_rules())
	var rat := _rat(world)
	var servant := TestWorlds.spawn(world, &"servant", ENEMY, Vector2i(7, 5), false)
	TestWorlds.spawn(world, &"rabbit", PLAYER, Vector2i(5, 8), false)
	TestWorlds.add_anchors(world)
	TestWorlds.run_until(world, 20)
	assert_int(rat.target_id).is_equal(servant.id)


func test_T54_risen_rabbit() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", ENEMY, Vector2i(5, 5), false)
	var rabbit := TestWorlds.spawn(world, &"rabbit", PLAYER, Vector2i(7, 5), false)
	TestWorlds.add_anchors(world)
	rabbit.hp = 0
	TestWorlds.run_until(world, 0)
	var risen := world.units[world.units.size() - 1]
	assert_str(String(risen.unit_type)).is_equal("rabbit")
	assert_int(risen.faction).is_equal(ENEMY)
	assert_int(risen.hp).is_equal(25)
	assert_int(risen.damage).is_equal(1)


func _hungry_rules() -> RulesData:
	var rules := TestWorlds.rules().duplicate() as RulesData
	rules.rat_digest_ticks = 10
	return rules


func _rat(world: World) -> SimUnit:
	var data := TestWorlds.without_ability(&"rat", &"WanderBehavior")
	return TestWorlds.spawn_data(world, data, PLAYER, Vector2i(5, 5), true)


func _count(world: World, unit_type: StringName, faction: SimUnit.Faction) -> int:
	var count: int = 0
	for unit: SimUnit in world.units:
		if unit.is_alive() and unit.faction == faction and unit.unit_type == unit_type:
			count += 1
	return count


func _damage(attacker: SimUnit, target: SimUnit, units: Array[SimUnit]) -> int:
	return SimCombat.compute_damage(attacker, target, SimSnapshot.new(units), TestWorlds.rules())
