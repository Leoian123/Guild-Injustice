class_name SimVision
extends RefCounted
## Line of sight (GDD §5.2): supercover of the segment between two points.
## A cell is touched if its closed square intersects the segment, so a segment through
## the corner shared by two diagonal cells also touches the other two cells at that corner.


static func has_line_of_sight(map: SimMap, from: Vector2, to: Vector2) -> bool:
	for cell: Vector2i in touched_cells(from, to):
		if map.is_wall(cell):
			return false
	return true


## Cells whose closed square [x, x+1] × [y, y+1] intersects the segment, column by column.
static func touched_cells(from: Vector2, to: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var min_x: float = minf(from.x, to.x)
	var max_x: float = maxf(from.x, to.x)
	var first_column: int = ceili(min_x) - 1
	var last_column: int = floori(max_x)
	for column: int in range(first_column, last_column + 1):
		# Part of the segment inside the closed strip [column, column + 1].
		var x_low: float = maxf(min_x, float(column))
		var x_high: float = minf(max_x, float(column + 1))
		if x_low > x_high:
			continue
		var y_low: float = minf(from.y, to.y)
		var y_high: float = maxf(from.y, to.y)
		if from.x != to.x:
			var y_a: float = _y_at(from, to, x_low)
			var y_b: float = _y_at(from, to, x_high)
			y_low = minf(y_a, y_b)
			y_high = maxf(y_a, y_b)
		for row: int in range(ceili(y_low) - 1, floori(y_high) + 1):
			cells.append(Vector2i(column, row))
	return cells


static func _y_at(from: Vector2, to: Vector2, x: float) -> float:
	return from.y + (x - from.x) * (to.y - from.y) / (to.x - from.x)
