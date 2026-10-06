extends GdUnitTestSuite
## T18 — A* path (GDD §6.3).


func test_T18_path_cost_to_relic() -> void:
	var map := TestWorlds.temple_01()
	var path := SimPathfinder.new(map).find_path(Vector2i(8, 33), map.relic_cell)

	assert_array(path).is_not_empty()
	assert_float(SimPathfinder.path_cost(path)).is_equal_approx(41.3, 0.1)
	for i: int in path.size():
		assert_bool(map.is_wall(path[i])).override_failure_message("wall cell %s in path" % path[i]).is_false()
		if i == 0:
			continue
		var step: Vector2i = path[i] - path[i - 1]
		assert_int(maxi(absi(step.x), absi(step.y))).is_equal(1)
		if step.x != 0 and step.y != 0:
			# No corner cutting: both orthogonal neighbours of a diagonal step are free.
			var side_a := Vector2i(path[i - 1].x + step.x, path[i - 1].y)
			var side_b := Vector2i(path[i - 1].x, path[i - 1].y + step.y)
			assert_bool(map.is_wall(side_a) or map.is_wall(side_b)) \
				.override_failure_message("corner cut at %s" % path[i]).is_false()
