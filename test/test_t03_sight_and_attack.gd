extends GdUnitTestSuite
## T03 — line of sight and attack (GDD §5.2, §6.5).


func test_T03_sight_and_attack() -> void:
	var walls: Array[Vector2i] = [Vector2i(8, 4), Vector2i(8, 5), Vector2i(8, 6)]
	var world := TestWorlds.world(1, walls)
	TestWorlds.spawn(world, &"archer", SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
	var undead := TestWorlds.spawn(world, &"undead", SimUnit.Faction.ENEMY, Vector2i(11, 5), false)
	TestWorlds.add_anchors(world)

	for i: int in 40:
		world.step()
	assert_int(undead.hp).is_equal(80)

	undead.position = SimMap.cell_center(Vector2i(8, 1))
	world.step()
	assert_int(undead.hp).is_equal(68)
