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
	spawn(world_value, &"paladin", SimUnit.Faction.PLAYER, Vector2i(2, 10), false)
	spawn(world_value, &"undead", SimUnit.Faction.ENEMY, Vector2i(21, 10), false)


## Unit "in (x,y)" = at the center of the cell (docs/TESTS.md).
static func spawn(world_value: World, unit_type: StringName, faction: SimUnit.Faction, cell: Vector2i, ai_enabled: bool) -> SimUnit:
	var unit := world_value.spawn_unit(unit_data(unit_type), faction, SimMap.cell_center(cell))
	unit.ai_enabled = ai_enabled
	return unit


## Starting stats from GDD §7–§8, built in the test until data/units exists (M4).
## Columns: cost, HP, damage, attack interval (s), attack range, speed, engage radius, chase radius, will.
const GDD_STATS: Dictionary = {
	&"rat": [158, 20, 3, 0.8, 1.0, 3.0, 4.0, 0.0, &"HungerWill"],
	&"goblin": [254, 45, 7, 1.0, 1.0, 2.5, 5.0, 6.0, &"HoldGroundWill"],
	&"archer": [300, 35, 8, 1.5, 6.0, 1.8, 7.0, 4.0, &"HoldGroundWill"],
	&"paladin": [1900, 400, 25, 1.4, 1.0, 1.2, 4.0, 5.0, &"HoldGroundWill"],
	&"servant": [0, 30, 5, 1.0, 1.0, 3.0, 5.0, 0.0, &"NecroBoundWill"],
	&"undead": [0, 80, 8, 1.3, 1.0, 1.5, 4.0, 0.0, &"NecroBoundWill"],
	&"necromancer": [0, 120, 10, 2.0, 5.0, 1.3, 6.0, 0.0, &"NecroBoundWill"],
}


static func unit_data(unit_type: StringName) -> UnitData:
	var stats: Array = GDD_STATS[unit_type]
	var data := UnitData.new()
	data.unit_type = unit_type
	data.cost = stats[0]
	data.max_hp = stats[1]
	data.damage = stats[2]
	data.attack_interval = stats[3]
	data.attack_range = stats[4]
	data.speed = stats[5]
	data.engage_radius = stats[6]
	data.chase_radius = stats[7]
	data.will = stats[8]
	return data
