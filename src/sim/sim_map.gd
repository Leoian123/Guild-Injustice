class_name SimMap
extends RefCounted
## Cell grid of a map (GDD §4). Origin top-left, y down. Cells outside the grid count as walls.

const WALL: String = "#"
const FLOOR: String = "."
const ENTRANCE: String = "E"
const RELIC: String = "R"

var width: int = 0
var height: int = 0
var relic_cell: Vector2i = Vector2i.ZERO
var entrances: Array[Vector2i] = []

var _walls: PackedByteArray = PackedByteArray()


## Returns null and pushes an error if the file is missing or malformed.
static func load_from_file(path: String) -> SimMap:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("SimMap: cannot read '%s'" % path)
		return null
	return from_text(text)


## Parses rows of the legend '#', '.', 'E', 'R'. Accepts LF and CRLF line endings.
static func from_text(text: String) -> SimMap:
	var rows: PackedStringArray = text.replace("\r", "").split("\n")
	# Only trailing empty lines are allowed: an empty row inside would shift every y.
	while not rows.is_empty() and rows[rows.size() - 1].is_empty():
		rows.remove_at(rows.size() - 1)
	if rows.is_empty():
		push_error("SimMap: empty map")
		return null

	var map := SimMap.new()
	map.width = rows[0].length()
	map.height = rows.size()
	map._walls.resize(map.width * map.height)
	var relic_count: int = 0
	for y: int in map.height:
		var row: String = rows[y]
		if row.length() != map.width:
			push_error("SimMap: row %d has length %d, expected %d" % [y, row.length(), map.width])
			return null
		for x: int in map.width:
			var symbol: String = row[x]
			match symbol:
				WALL:
					map._walls[y * map.width + x] = 1
				FLOOR:
					pass
				ENTRANCE:
					map.entrances.append(Vector2i(x, y))
				RELIC:
					map.relic_cell = Vector2i(x, y)
					relic_count += 1
				_:
					push_error("SimMap: unknown symbol '%s' at (%d,%d)" % [symbol, x, y])
					return null
	if relic_count != 1:
		push_error("SimMap: expected one relic, found %d" % relic_count)
		return null
	return map


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_wall(cell: Vector2i) -> bool:
	if not is_inside(cell):
		return true
	return _walls[cell.y * width + cell.x] == 1


func is_walkable(cell: Vector2i) -> bool:
	return not is_wall(cell)


func set_wall(cell: Vector2i, wall: bool) -> void:
	_walls[cell.y * width + cell.x] = 1 if wall else 0


## Center of the relic cell (GDD §4).
func relic_position() -> Vector2:
	return cell_center(relic_cell)


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) + Vector2(0.5, 0.5)
