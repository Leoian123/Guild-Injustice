class_name SimPathfinder
extends RefCounted
## A* on the cell grid (GDD §6.3): 8 directions, no corner cutting, orthogonal cost 1, diagonal √2.

var _astar: AStarGrid2D = AStarGrid2D.new()


func _init(map: SimMap) -> void:
	_astar.region = Rect2i(0, 0, map.width, map.height)
	_astar.cell_size = Vector2.ONE
	# Diagonal only if both orthogonal neighbours are free.
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_astar.jumping_enabled = false
	_astar.update()
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			if map.is_wall(cell):
				_astar.set_point_solid(cell, true)


## Cells from `from` to `to`, both included. Empty if unreachable.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not _astar.is_in_boundsv(from) or not _astar.is_in_boundsv(to):
		return path
	if _astar.is_point_solid(from) or _astar.is_point_solid(to):
		return path
	path.assign(_astar.get_id_path(from, to))
	return path


## Sum of step lengths: 1 for orthogonal steps, √2 for diagonal ones.
static func path_cost(path: Array[Vector2i]) -> float:
	var cost: float = 0.0
	for i: int in range(1, path.size()):
		cost += Vector2(path[i - 1]).distance_to(Vector2(path[i]))
	return cost
