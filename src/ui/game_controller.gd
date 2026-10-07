class_name GameController
extends Node2D
## One game of temple_01 (GDD §2): reconnaissance, deployment, battle, result.
## Holds the session and forwards player input to the simulation; views only read it.

enum Phase { RECON, DEPLOY, BATTLE, RESULT }

const SCENARIO_ID: StringName = &"temple_01"
const SPEEDS: Array[int] = [1, 2, 4]

signal changed

@export var cell_size_px: int = 0

var scenario: ScenarioData
var rules: RulesData
var world: World
var fog: SimFog
var plan: DeploymentPlan
var phase: Phase = Phase.RECON
var seed_value: int = 0
## Unit type selected in the shop during deployment.
var selected_type: StringName = &""
var paused: bool = false
var speed: int = 1
## Last message for the player (invalid placement, …).
var message: String = ""

## Debug switches (M5): labels, grid, reveal all, target lines of sight.
var debug_labels: bool = false
var debug_grid: bool = false
var debug_reveal_all: bool = false
var debug_target_lines: bool = false

var _tick_accumulator: float = 0.0

@onready var _map_view: MapView = $MapView
@onready var _world_view: WorldView = $WorldView


func _ready() -> void:
	scenario = SimScenario.load_scenario(SCENARIO_ID)
	rules = SimScenario.load_rules()
	_world_view.controller = self
	start_game(_fresh_seed())
	var hud := Hud.new()
	add_child(hud)
	hud.bind(self)


func start_game(new_seed: int) -> void:
	seed_value = new_seed
	world = SimScenario.create_world(scenario, rules, seed_value)
	fog = SimFog.new(world.map, rules)
	plan = DeploymentPlan.new()
	phase = Phase.RECON
	selected_type = scenario.player_units[0]
	paused = false
	speed = SPEEDS[0]
	message = ""
	_tick_accumulator = 0.0
	_map_view.show_map(world.map)
	changed.emit()


func reveal(cell: Vector2i) -> void:
	if phase != Phase.RECON:
		return
	if not fog.reveal(cell):
		message = "Nessuna rivelazione rimasta."
	elif fog.reveals_left() == 0:
		end_recon()
		return
	changed.emit()


func end_recon() -> void:
	if phase != Phase.RECON:
		return
	phase = Phase.DEPLOY
	message = ""
	changed.emit()


func select_type(unit_type: StringName) -> void:
	selected_type = unit_type
	changed.emit()


func place(cell: Vector2i) -> void:
	if phase != Phase.DEPLOY:
		return
	var error := plan.placement_error(scenario, fog, selected_type, cell)
	if error.is_empty():
		plan.add(selected_type, cell)
		message = ""
	else:
		message = _placement_message(error)
	changed.emit()


func remove(cell: Vector2i) -> void:
	if phase == Phase.DEPLOY and plan.remove_at(cell):
		message = ""
		changed.emit()


func start_battle() -> void:
	if phase != Phase.DEPLOY:
		return
	if plan.entries.is_empty():
		message = "Schiera almeno un'unità."
		changed.emit()
		return
	SimScenario.deploy(world, plan)
	phase = Phase.BATTLE
	message = ""
	changed.emit()


## Runs up to `ticks` ticks at once (tools and tests); stops when the battle ends.
func advance(ticks: int) -> void:
	for i: int in ticks:
		if world.is_over():
			break
		world.step()
	_check_end()
	changed.emit()


func toggle_pause() -> void:
	paused = not paused
	changed.emit()


func set_speed(value: int) -> void:
	speed = value
	changed.emit()


func toggle_debug(which: StringName) -> void:
	match which:
		&"labels":
			debug_labels = not debug_labels
		&"grid":
			debug_grid = not debug_grid
		&"reveal_all":
			debug_reveal_all = not debug_reveal_all
		&"target_lines":
			debug_target_lines = not debug_target_lines
	changed.emit()


func new_game() -> void:
	start_game(_fresh_seed())


func replay() -> void:
	start_game(seed_value)


func cell_at(screen_position: Vector2) -> Vector2i:
	return Vector2i((screen_position / float(cell_size_px)).floor())


## Result numbers for the end screen (GDD §2): units lost and enemies killed by type
## (risen enemies counted apart), duration in seconds.
func summary() -> Dictionary:
	var lost: Dictionary = {}
	var killed: Dictionary = {}
	var killed_risen: int = 0
	for unit: SimUnit in world.units:
		if unit.is_alive():
			continue
		if unit.faction == SimUnit.Faction.PLAYER:
			lost[unit.unit_type] = lost.get(unit.unit_type, 0) + 1
		elif unit.reanimated:
			killed_risen += 1
		else:
			killed[unit.unit_type] = killed.get(unit.unit_type, 0) + 1
	var ticks: int = world.end_tick + 1 if world.is_over() else world.tick
	return {"lost": lost, "killed": killed, "killed_risen": killed_risen, "seconds": float(ticks) / rules.tick_rate}


func _process(delta: float) -> void:
	if phase != Phase.BATTLE or paused:
		return
	_tick_accumulator += delta * speed
	var tick_length: float = 1.0 / rules.tick_rate
	var stepped: bool = false
	while _tick_accumulator >= tick_length and not world.is_over():
		_tick_accumulator -= tick_length
		world.step()
		stepped = true
	if stepped:
		_check_end()
		changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse := event as InputEventMouseButton
		var cell := cell_at(mouse.position)
		if not world.map.is_inside(cell):
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if phase == Phase.RECON:
				reveal(cell)
			elif phase == Phase.DEPLOY:
				place(cell)
		elif mouse.button_index == MOUSE_BUTTON_RIGHT:
			remove(cell)
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_F1:
				toggle_debug(&"labels")
			KEY_F2:
				toggle_debug(&"grid")
			KEY_F3:
				toggle_debug(&"reveal_all")
			KEY_F4:
				toggle_debug(&"target_lines")
			KEY_SPACE:
				if phase == Phase.BATTLE:
					toggle_pause()


func _check_end() -> void:
	if phase == Phase.BATTLE and world.is_over():
		phase = Phase.RESULT


func _fresh_seed() -> int:
	return int(Time.get_unix_time_from_system()) % 1000000


func _placement_message(error: String) -> String:
	if error == "over budget":
		return "Budget insufficiente."
	if error.ends_with("not walkable"):
		return "Cella non calpestabile."
	if error.ends_with("not visible"):
		return "Puoi schierare solo su celle visibili."
	return error
