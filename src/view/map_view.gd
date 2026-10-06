class_name MapView
extends Node2D
## Draws a SimMap with plain shapes. Reads the map, decides nothing.

const WALL_COLOR: Color = Color(0.16, 0.15, 0.17)
const FLOOR_COLOR: Color = Color(0.42, 0.40, 0.36)
const ENTRANCE_COLOR: Color = Color(0.55, 0.45, 0.28)
const RELIC_COLOR: Color = Color(0.85, 0.72, 0.25)

## Pixels per cell (GDD §4).
@export var cell_size_px: int = 0

var map: SimMap


func show_map(value: SimMap) -> void:
	map = value
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	var cell_size := Vector2(cell_size_px, cell_size_px)
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			var color := WALL_COLOR if map.is_wall(cell) else FLOOR_COLOR
			draw_rect(Rect2(Vector2(cell) * cell_size, cell_size), color)
	for cell: Vector2i in map.entrances:
		draw_rect(Rect2(Vector2(cell) * cell_size, cell_size), ENTRANCE_COLOR)
	var relic_center := map.relic_position() * float(cell_size_px)
	draw_circle(relic_center, cell_size_px * 0.4, RELIC_COLOR)
