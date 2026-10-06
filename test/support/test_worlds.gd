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
static func world(seed_value: int, extra_walls: Array[Vector2i] = []) -> World:
	return World.new(rules(), test_map(extra_walls), seed_value)


## Anchors: player paladin at (2,10) and enemy undead at (21,10), AI off.
static func add_anchors(world_value: World) -> void:
	var paladin := world_value.spawn_unit(unit_data(&"paladin", 400), SimUnit.Faction.PLAYER, SimMap.cell_center(Vector2i(2, 10)))
	paladin.ai_enabled = false
	var undead := world_value.spawn_unit(unit_data(&"undead", 80), SimUnit.Faction.ENEMY, SimMap.cell_center(Vector2i(21, 10)))
	undead.ai_enabled = false


## Minimal UnitData built in the test until data/units exists (M4).
static func unit_data(unit_type: StringName, max_hp: int) -> UnitData:
	var data := UnitData.new()
	data.unit_type = unit_type
	data.max_hp = max_hp
	return data
