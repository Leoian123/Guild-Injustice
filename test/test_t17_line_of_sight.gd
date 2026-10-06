extends GdUnitTestSuite
## T17 — corners and sight (GDD §5.2).


func test_T17_corner_blocks_sight() -> void:
	var from := SimMap.cell_center(Vector2i(4, 4))
	var to := SimMap.cell_center(Vector2i(5, 5))

	assert_bool(SimVision.has_line_of_sight(TestWorlds.test_map(), from, to)).is_true()

	var walls: Array[Vector2i] = [Vector2i(5, 4)]
	assert_bool(SimVision.has_line_of_sight(TestWorlds.test_map(walls), from, to)).is_false()
