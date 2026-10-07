extends GdUnitTestSuite
## Function-level damage tests: T04, T05 (backstab), T06, T07 (armor), T16 (rounding).
## No World: units and snapshot are built in the test, IDs in snapshot order.

const PLAYER := SimUnit.Faction.PLAYER
const ENEMY := SimUnit.Faction.ENEMY


func test_T04_backstab_from_behind() -> void:
	var thief := TestWorlds.unit(1, &"thief", PLAYER, Vector2i(5, 6))
	var undead := TestWorlds.unit(2, &"undead", ENEMY, Vector2i(5, 5))
	undead.facing = Vector2(0, -1)
	assert_int(_damage(thief, undead, [thief, undead])).is_equal(24)


func test_T05_backstab_from_front() -> void:
	var thief := TestWorlds.unit(1, &"thief", PLAYER, Vector2i(5, 4))
	var undead := TestWorlds.unit(2, &"undead", ENEMY, Vector2i(5, 5))
	undead.facing = Vector2(0, -1)
	assert_int(_damage(thief, undead, [thief, undead])).is_equal(6)


func test_T06_armor() -> void:
	var paladin := TestWorlds.unit(1, &"paladin", PLAYER, Vector2i(5, 5))
	var servant := TestWorlds.unit(2, &"servant", ENEMY, Vector2i(5, 6))
	assert_int(_damage(servant, paladin, [paladin, servant])).is_equal(1)


func test_T07_paladin_surrounded() -> void:
	var paladin := TestWorlds.unit(1, &"paladin", PLAYER, Vector2i(5, 5))
	var servants: Array[SimUnit] = [paladin]
	var cells: Array[Vector2i] = [Vector2i(4, 5), Vector2i(6, 5), Vector2i(5, 4), Vector2i(5, 6)]
	for i: int in cells.size():
		servants.append(TestWorlds.unit(i + 2, &"servant", ENEMY, cells[i]))
	assert_int(_damage(servants[1], paladin, servants)).is_equal(5)


func test_T16_rounding() -> void:
	var goblin := TestWorlds.unit(1, &"goblin", PLAYER, Vector2i(5, 5))
	var ally_a := TestWorlds.unit(2, &"goblin", PLAYER, Vector2i(6, 5))
	var ally_b := TestWorlds.unit(3, &"goblin", PLAYER, Vector2i(5, 6))
	var servant := TestWorlds.unit(4, &"servant", ENEMY, Vector2i(4, 5))
	assert_int(_damage(goblin, servant, [goblin, ally_a, ally_b, servant])).is_equal(9)

	var archer := TestWorlds.unit(1, &"archer", PLAYER, Vector2i(5, 5))
	var close_enemy := TestWorlds.unit(2, &"servant", ENEMY, Vector2i(6, 5))
	assert_int(_damage(archer, close_enemy, [archer, close_enemy])).is_equal(8)


func _damage(attacker: SimUnit, target: SimUnit, units: Array[SimUnit]) -> int:
	return SimCombat.compute_damage(attacker, target, SimSnapshot.new(units), TestWorlds.rules())
