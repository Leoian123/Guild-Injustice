class_name WorldView
extends Node2D
## Draws fog, threat markers, corpses, units, planned units and debug overlays with plain
## shapes. Reads the GameController and its World; decides nothing.

const FOG_COLOR: Color = Color(0.03, 0.03, 0.05, 0.82)
const GRID_COLOR: Color = Color(1, 1, 1, 0.08)
const PLAYER_COLOR: Color = Color(0.35, 0.6, 0.95)
const ENEMY_COLOR: Color = Color(0.85, 0.3, 0.35)
const RISEN_COLOR: Color = Color(0.55, 0.3, 0.75)
const PLAN_COLOR: Color = Color(0.35, 0.6, 0.95, 0.55)
const FLEE_COLOR: Color = Color(1.0, 0.85, 0.2)
const THREAT_COLOR: Color = Color(0.95, 0.35, 0.2)
const CORPSE_COLOR: Color = Color(0.5, 0.5, 0.5)
const REANIMABLE_COLOR: Color = Color(0.65, 0.35, 0.85)
const HP_BACK_COLOR: Color = Color(0, 0, 0, 0.6)
const HP_COLOR: Color = Color(0.3, 0.9, 0.4)
const SIGHT_COLOR: Color = Color(0.3, 1.0, 0.4, 0.8)
const BLOCKED_COLOR: Color = Color(1.0, 0.3, 0.3, 0.8)
const LABEL_COLOR: Color = Color(1, 1, 1)
const REVEAL_PREVIEW_COLOR: Color = Color(1, 1, 1, 0.35)
const GUARD_COLOR: Color = Color(0.95, 0.8, 0.3)

## One letter per unit type, drawn on the unit.
const LETTERS: Dictionary = {
	&"rat": "R", &"goblin": "G", &"archer": "A", &"thief": "L", &"paladin": "P",
	&"servant": "S", &"undead": "U", &"revenant": "V", &"necromancer": "N",
}
const STATE_SHORT: Array[String] = ["IDL", "MOV", "ATK", "FLE", "DEA"]

var controller: GameController


func _process(_delta: float) -> void:
	# Cheap enough at this size; keeps hover previews and battle animation current.
	queue_redraw()


func _draw() -> void:
	if controller == null or controller.world == null:
		return
	var cell := float(controller.cell_size_px)
	var world := controller.world
	var fogged := controller.phase <= GameController.Phase.DEPLOY and not controller.debug_reveal_all
	if controller.debug_grid:
		_draw_grid(world.map, cell)
	for corpse: SimCorpse in world.corpses:
		_draw_corpse(corpse, cell)
	for unit: SimUnit in world.units:
		if not unit.is_alive():
			continue
		if fogged and not controller.fog.is_visible(Vector2i(unit.position.floor())):
			continue
		_draw_unit(unit, cell)
	if controller.phase == GameController.Phase.DEPLOY:
		for entry: Dictionary in controller.plan.entries:
			_draw_planned(entry["type"], entry["cell"], entry["guard"], cell)
	if fogged:
		_draw_fog(world.map, cell)
	# Threat markers belong to the fog: a marker disappears once its zone is visible (GDD §5.1).
	if fogged:
		for marker: Vector2i in controller.scenario.threat_markers:
			if not controller.fog.is_visible(marker):
				_draw_threat(marker, cell)
	if controller.phase == GameController.Phase.RECON and controller.fog.reveals_left() > 0:
		var hover := controller.cell_at(get_local_mouse_position())
		if world.map.is_inside(hover):
			draw_arc(SimMap.cell_center(hover) * cell, controller.rules.reveal_radius * cell, 0, TAU, 64, REVEAL_PREVIEW_COLOR, 2.0)
	if controller.debug_target_lines and controller.phase >= GameController.Phase.BATTLE:
		_draw_target_lines(world, cell)


func _draw_grid(map: SimMap, cell: float) -> void:
	for x: int in map.width + 1:
		draw_line(Vector2(x * cell, 0), Vector2(x * cell, map.height * cell), GRID_COLOR)
	for y: int in map.height + 1:
		draw_line(Vector2(0, y * cell), Vector2(map.width * cell, y * cell), GRID_COLOR)


func _draw_fog(map: SimMap, cell: float) -> void:
	for y: int in map.height:
		for x: int in map.width:
			if not controller.fog.is_visible(Vector2i(x, y)):
				draw_rect(Rect2(Vector2(x, y) * cell, Vector2(cell, cell)), FOG_COLOR)


func _draw_threat(marker: Vector2i, cell: float) -> void:
	var center := SimMap.cell_center(marker) * cell
	draw_circle(center, cell * 0.7, THREAT_COLOR)
	_draw_text(center, "!", Color.WHITE, 14)


func _draw_corpse(corpse: SimCorpse, cell: float) -> void:
	var center := corpse.position * cell
	var color := REANIMABLE_COLOR if corpse.reanimable else CORPSE_COLOR
	var half := cell * 0.25
	draw_line(center - Vector2(half, half), center + Vector2(half, half), color, 2.0)
	draw_line(center + Vector2(-half, half), center + Vector2(half, -half), color, 2.0)


func _draw_unit(unit: SimUnit, cell: float) -> void:
	var center := unit.position * cell
	var radius := cell * 0.4
	var color := PLAYER_COLOR
	if unit.faction == SimUnit.Faction.ENEMY:
		color = RISEN_COLOR if unit.reanimated else ENEMY_COLOR
	draw_circle(center, radius, color)
	if unit.state == SimUnit.State.FLEE:
		draw_arc(center, radius + 2.0, 0, TAU, 24, FLEE_COLOR, 2.0)
	if unit.guard:
		draw_rect(Rect2(center - Vector2(radius, radius) - Vector2(2, 2), Vector2(radius, radius) * 2.0 + Vector2(4, 4)), GUARD_COLOR, false, 1.5)
	draw_line(center, center + unit.facing * radius * 1.4, Color.WHITE, 1.5)
	_draw_text(center, LETTERS.get(unit.unit_type, "?"), Color.BLACK, 10)
	var bar := Rect2(center + Vector2(-radius, -radius - 5.0), Vector2(radius * 2.0, 3.0))
	draw_rect(bar, HP_BACK_COLOR)
	var ratio := clampf(float(unit.hp) / unit.max_hp, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), HP_COLOR)
	if controller.debug_labels:
		_draw_text(center + Vector2(0, -radius - 10.0), "%s %d" % [STATE_SHORT[unit.state], unit.hp], LABEL_COLOR, 9)


func _draw_planned(unit_type: StringName, cell_position: Vector2i, guard: bool, cell: float) -> void:
	var center := SimMap.cell_center(cell_position) * cell
	draw_arc(center, cell * 0.4, 0, TAU, 24, PLAN_COLOR, 2.0)
	if guard:
		var half := cell * 0.4 + 2.0
		draw_rect(Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0), GUARD_COLOR, false, 1.5)
	_draw_text(center, LETTERS.get(unit_type, "?"), PLAN_COLOR, 10)


func _draw_target_lines(world: World, cell: float) -> void:
	for unit: SimUnit in world.units:
		if not unit.is_alive():
			continue
		var target := world.get_unit(unit.target_id)
		if target == null:
			continue
		var sight := SimVision.has_line_of_sight(world.map, unit.position, target.position)
		draw_line(unit.position * cell, target.position * cell, SIGHT_COLOR if sight else BLOCKED_COLOR, 1.0)


func _draw_text(center: Vector2, text: String, color: Color, size: int) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center + Vector2(-width / 2.0, size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
