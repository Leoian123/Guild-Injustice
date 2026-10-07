class_name SimFog
extends RefCounted
## Fog and reveals during reconnaissance and deployment (GDD §5.1). The fog ignores walls.
## It is not battle state: in battle the fog disappears.

var map: SimMap
var rules: RulesData
## Reveal points chosen so far, as cells; each reveals around the cell center.
var reveals: Array[Vector2i] = []
var _visible: PackedByteArray = PackedByteArray()


func _init(p_map: SimMap, p_rules: RulesData) -> void:
	map = p_map
	rules = p_rules
	_visible.resize(map.width * map.height)
	_mark(map.relic_position(), rules.heart_vision_radius)


func reveals_left() -> int:
	return rules.reveals - reveals.size()


## Reveals the cells within REVEAL_RADIUS of the center of `cell`. False if none is left.
func reveal(cell: Vector2i) -> bool:
	if reveals_left() <= 0 or not map.is_inside(cell):
		return false
	reveals.append(cell)
	_mark(SimMap.cell_center(cell), rules.reveal_radius)
	return true


func is_visible(cell: Vector2i) -> bool:
	if not map.is_inside(cell):
		return false
	return _visible[cell.y * map.width + cell.x] == 1


func _mark(center: Vector2, radius: float) -> void:
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			if SimMap.cell_center(cell).distance_to(center) <= radius:
				_visible[y * map.width + x] = 1
