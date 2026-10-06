extends GdUnitTestSuite
## T00 — basic determinism (GDD §12).

const RULES_PATH: String = "res://data/rules.tres"


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


# Anchors from docs/TESTS.md: player paladin at (2,10), enemy undead at (21,10), AI off.
func _anchored_world(seed_value: int) -> World:
	var world := World.new(load(RULES_PATH) as RulesData, seed_value)
	var paladin := world.spawn_unit(_unit_data(&"paladin", 400), SimUnit.Faction.PLAYER, _cell_center(2, 10))
	paladin.ai_enabled = false
	var undead := world.spawn_unit(_unit_data(&"undead", 80), SimUnit.Faction.ENEMY, _cell_center(21, 10))
	undead.ai_enabled = false
	return world


func _unit_data(unit_type: StringName, max_hp: int) -> UnitData:
	var data := UnitData.new()
	data.unit_type = unit_type
	data.max_hp = max_hp
	return data


func _cell_center(x: int, y: int) -> Vector2:
	return Vector2(x + 0.5, y + 0.5)
