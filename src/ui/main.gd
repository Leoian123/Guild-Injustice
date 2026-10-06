extends Node2D
## Entry scene. M2: shows the temple_01 map.

const MAP_PATH: String = "res://data/maps/temple_01.txt"

@onready var _map_view: MapView = $MapView


func _ready() -> void:
	_map_view.show_map(SimMap.load_from_file(MAP_PATH))
