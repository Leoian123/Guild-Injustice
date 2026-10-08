extends GdUnitTestSuite
## M5.1: T35 body blocking, T36 raider with no other way, T37 allies pass through,
## T38 patrol, T39 guard, T40 guard cost, T41 reanimation in an occupied cell (GDD §6.3, §6.6, §7, §8).

const PLAYER := SimUnit.Faction.PLAYER
const ENEMY := SimUnit.Faction.ENEMY


func test_T35_raider_goes_around() -> void:
	var walls: Array[Vector2i] = []
	for y: int in range(1, 11):
		if y != 2 and y != 8:
			walls.append(Vector2i(10, y))
	var world := TestWorlds.world(1, walls)
	var servant := TestWorlds.spawn(world, &"servant", ENEMY, Vector2i(5, 7), true)
	var goblin := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(10, 8), false)
	TestWorlds.add_anchors(world)
	while world.tick <= 100 and not world.is_over():
		var tick := world.tick
		world.step()
		assert_bool(Vector2i(servant.position.floor()) == Vector2i(10, 8)) \
			.override_failure_message("servant in the goblin's cell after tick %d" % tick).is_false()
	assert_int(goblin.hp).is_equal(45)
	assert_float(servant.position.x).is_greater(11.0)


func test_T36_raider_opens_the_way_by_fighting() -> void:
	var walls: Array[Vector2i] = []
	for y: int in range(1, 11):
		if y != 5:
			walls.append(Vector2i(10, y))
	var world := TestWorlds.world(1, walls)
	var servant := TestWorlds.spawn(world, &"servant", ENEMY, Vector2i(5, 5), true)
	var goblin := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(10, 5), false)
	TestWorlds.add_anchors(world)
	while world.tick <= 60 and not world.is_over():
		var tick := world.tick
		world.step()
		assert_bool(Vector2i(servant.position.floor()) == Vector2i(10, 5)) \
			.override_failure_message("servant in the goblin's cell after tick %d" % tick).is_false()
	assert_int(servant.target_id).is_equal(goblin.id)
	assert_int(goblin.hp).is_less(45)


func test_T38_patrol() -> void:
	var world := TestWorlds.world(1)
	var goblin := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(5, 5), true)
	TestWorlds.add_anchors(world)
	TestWorlds.run_until(world, 59)
	assert_vector(goblin.position).is_equal(goblin.home)
	var left_home: bool = false
	while world.tick <= 600 and not world.is_over():
		world.step()
		if goblin.position != goblin.home:
			left_home = true
		if world.tick == 120:
			assert_bool(left_home).override_failure_message("still at its post after tick 119").is_true()
		assert_float(goblin.position.distance_to(goblin.home)).is_less_equal(world.rules.patrol_radius + 1.0)


func test_T39_guard() -> void:
	var world := TestWorlds.world(1)
	var plan := DeploymentPlan.new()
	plan.add(&"goblin", Vector2i(5, 5), true)
	SimScenario.deploy(world, plan)
	var goblin := world.units[0]
	var servant := TestWorlds.spawn(world, &"servant", ENEMY, Vector2i(5, 8), false)
	TestWorlds.add_anchors(world)
	goblin.hp = 20
	var relic := world.map.relic_position()
	var start_distance := goblin.position.distance_to(relic)
	while world.tick <= 200 and not world.is_over():
		world.step()
		assert_int(goblin.state).is_not_equal(SimUnit.State.FLEE)
		assert_int(servant.hp).is_equal(30)
	assert_float(goblin.position.distance_to(relic)).is_less(start_distance)


func test_T40_guard_cost() -> void:
	var rules := TestWorlds.rules()
	assert_int(DeploymentPlan.unit_cost(&"rat", true, rules)).is_equal(110)
	assert_int(DeploymentPlan.unit_cost(&"paladin", true, rules)).is_equal(2090)
	var scenario := SimScenario.load_scenario(&"temple_01")
	var world := TestWorlds.world(1)
	var fog := SimFog.new(world.map, rules)
	var relic_cell := world.map.relic_cell
	var plan := DeploymentPlan.new()
	assert_str(plan.placement_error(scenario, fog, world, &"rat", relic_cell, true)).is_not_empty()
	assert_str(plan.placement_error(scenario, fog, world, &"goblin", relic_cell, true)).is_empty()


func test_T41_risen_in_an_occupied_cell() -> void:
	var world := TestWorlds.neutral_dice_world(1)
	TestWorlds.spawn(world, &"necromancer", ENEMY, Vector2i(5, 5), false)
	var fallen := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(8, 5), false)
	var other := TestWorlds.spawn(world, &"goblin", PLAYER, Vector2i(8, 5), false)
	TestWorlds.add_anchors(world)
	fallen.hp = 0
	TestWorlds.run_until(world, 0)
	var risen := world.units[world.units.size() - 1]
	assert_str(String(risen.unit_type)).is_equal("goblin")
	assert_int(risen.faction).is_equal(ENEMY)
	var cell := Vector2i(risen.position.floor())
	assert_int(maxi(absi(cell.x - 8), absi(cell.y - 5))).is_equal(1)
	assert_bool(cell == Vector2i(other.position.floor())).is_false()


func test_T42_guards_spread_in_the_room() -> void:
	var world := TestWorlds.world(1)
	var plan := DeploymentPlan.new()
	plan.add(&"goblin", Vector2i(3, 3), true)
	plan.add(&"goblin", Vector2i(3, 8), true)
	SimScenario.deploy(world, plan)
	var guards: Array[SimUnit] = [world.units[0], world.units[1]]
	TestWorlds.add_anchors(world)
	TestWorlds.run_until(world, 299)
	while world.tick <= 600 and not world.is_over():
		var tick := world.tick
		world.step()
		var points: Array[Vector2i] = []
		for guard: SimUnit in guards:
			assert_bool(HoldGroundWill.is_in_guarded_room(world, guard)) 				.override_failure_message("guard %d out of the room after tick %d" % [guard.id, tick]).is_true()
			var will := guard.will as HoldGroundWill
			assert_bool(will.has_patrol_point).is_true()
			var point := Vector2i(will.patrol_point.floor())
			assert_bool(world.relic_room.has_point(point)).is_true()
			points.append(point)
		assert_bool(points[0] == points[1]) 			.override_failure_message("same patrol cell after tick %d" % tick).is_false()


func test_T44_sated_rat_stays_near_its_den() -> void:
	var world := TestWorlds.world(1)
	var rat := TestWorlds.spawn(world, &"rat", PLAYER, Vector2i(10, 5), true)
	TestWorlds.add_anchors(world)
	var den := (rat.will as HungerWill).den
	var moved: bool = false
	while world.tick <= 198 and not world.is_over():
		var tick := world.tick
		world.step()
		assert_bool((rat.will as HungerWill).is_sated()).override_failure_message("hungry at tick %d" % tick).is_true()
		assert_float(rat.position.distance_to(den)).is_less_equal(world.rules.swarm_leash_radius + 0.5)
		if rat.position != den:
			moved = true
	assert_bool(moved).is_true()
