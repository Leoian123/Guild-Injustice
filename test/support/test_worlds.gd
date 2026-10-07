class_name TestWorlds
extends RefCounted
## Test-mode fixtures from docs/TESTS.md ("Modalità di test").

const RULES_PATH: String = "res://data/rules.tres"
const TEMPLE_01_PATH: String = "res://data/maps/temple_01.txt"
const TEST_MAP_SIZE: Vector2i = Vector2i(24, 12)
const TEST_MAP_RELIC: Vector2i = Vector2i(20, 6)


static func rules() -> RulesData:
	return load(RULES_PATH) as RulesData


## 24×12, wall border, all-floor interior, relic at (20,6), plus `extra_walls`.
static func test_map(extra_walls: Array[Vector2i] = []) -> SimMap:
	var rows: PackedStringArray = []
	for y: int in TEST_MAP_SIZE.y:
		var row: String = ""
		for x: int in TEST_MAP_SIZE.x:
			var cell := Vector2i(x, y)
			if x == 0 or y == 0 or x == TEST_MAP_SIZE.x - 1 or y == TEST_MAP_SIZE.y - 1:
				row += SimMap.WALL
			elif cell == TEST_MAP_RELIC:
				row += SimMap.RELIC
			elif cell in extra_walls:
				row += SimMap.WALL
			else:
				row += SimMap.FLOOR
		rows.append(row)
	return SimMap.from_text("\n".join(rows))


static func temple_01() -> SimMap:
	return SimMap.load_from_file(TEMPLE_01_PATH)


## World on the test map. Call add_anchors() after creating the test's own units.
static func world(seed_value: int, extra_walls: Array[Vector2i] = [], rules_value: RulesData = null) -> World:
	return World.new(rules_value if rules_value != null else rules(), test_map(extra_walls), seed_value)


## Test-local copy of the rules with another REANIMATE_K_BASE (docs/TESTS.md, "Dado neutralizzato" = 0).
static func rules_with_k(k_base: float) -> RulesData:
	var copy := rules().duplicate() as RulesData
	copy.reanimate_k_base = k_base
	return copy


## World with the reanimation roll neutralized: every corpse that survives is reanimable.
static func neutral_dice_world(seed_value: int) -> World:
	return world(seed_value, [], rules_with_k(0.0))


## Anchors: player paladin at (2,10) and enemy undead at (21,10), AI off.
static func add_anchors(world_value: World) -> void:
	spawn(world_value, &"paladin", SimUnit.Faction.PLAYER, Vector2i(2, 10), false)
	spawn(world_value, &"undead", SimUnit.Faction.ENEMY, Vector2i(21, 10), false)


## Steps until tick `last` has run ("after tick N" in docs/TESTS.md).
static func run_until(world_value: World, last: int) -> void:
	while world_value.tick <= last:
		world_value.step()


## Unit "in (x,y)" = at the center of the cell (docs/TESTS.md).
static func spawn(world_value: World, unit_type: StringName, faction: SimUnit.Faction, cell: Vector2i, ai_enabled: bool) -> SimUnit:
	return spawn_data(world_value, unit_data(unit_type), faction, cell, ai_enabled)


static func spawn_data(world_value: World, data: UnitData, faction: SimUnit.Faction, cell: Vector2i, ai_enabled: bool) -> SimUnit:
	var unit := world_value.spawn_unit(data, faction, SimMap.cell_center(cell))
	unit.ai_enabled = ai_enabled
	return unit


## The shared unit data from data/units/. Read-only: tests needing a variant use without_ability().
static func unit_data(unit_type: StringName) -> UnitData:
	return load("res://data/units/%s.tres" % unit_type) as UnitData


## A test-local copy of a unit's data without one ability (docs/TESTS.md, e.g. T20).
static func without_ability(unit_type: StringName, ability: StringName) -> UnitData:
	var data := unit_data(unit_type).duplicate() as UnitData
	var abilities: Array[StringName] = data.abilities.duplicate()
	abilities.erase(ability)
	data.abilities = abilities
	return data


## A unit outside any World, for function-level tests: IDs must follow the snapshot order.
static func unit(id: int, unit_type: StringName, faction: SimUnit.Faction, cell: Vector2i) -> SimUnit:
	return SimUnit.new(id, unit_data(unit_type), faction, SimMap.cell_center(cell), rules().tick_rate)
