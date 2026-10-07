class_name Hud
extends CanvasLayer
## Side panel: phase, reveals, budget and shop, battle controls, result, debug switches.
## Forwards clicks to the GameController and redraws on its `changed` signal.

const PANEL_WIDTH: float = 256.0
const UNIT_NAMES: Dictionary = {
	&"rat": "Ratto", &"goblin": "Goblin", &"archer": "Arciere", &"thief": "Ladro", &"paladin": "Paladino",
	&"servant": "Servo", &"undead": "Non morto", &"revenant": "Revenant", &"necromancer": "Necromante",
}
const REASONS: Dictionary = {
	"enemies_dead": "Tutti i nemici sono caduti",
	"player_dead": "Annientamento: nessuna tua unità è sopravvissuta",
	"relic_stolen": "La reliquia è stata rubata",
	"timeout": "Tempo scaduto",
}
const MESSAGE_COLOR: Color = Color(1.0, 0.55, 0.45)

var _controller: GameController
var _title: Label
var _info: Label
var _message: Label
var _recon_box: VBoxContainer
var _deploy_box: VBoxContainer
var _battle_box: VBoxContainer
var _result_box: VBoxContainer
var _result_text: Label
var _shop_buttons: Dictionary = {}
var _pause_button: Button
var _speed_buttons: Dictionary = {}
var _debug_checks: Dictionary = {}


func bind(controller: GameController) -> void:
	_controller = controller
	_build()
	controller.changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(_map_width(), 0)
	panel.size = Vector2(PANEL_WIDTH, _map_height())
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	column.add_child(_title)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_info)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", MESSAGE_COLOR)
	column.add_child(_message)

	_recon_box = VBoxContainer.new()
	column.add_child(_recon_box)
	_add_button(_recon_box, "Fine ricognizione", _controller.end_recon)

	_deploy_box = VBoxContainer.new()
	column.add_child(_deploy_box)
	for unit_type: StringName in _controller.scenario.player_units:
		var cost := SimScenario.unit_data(unit_type).cost
		var button := _add_button(_deploy_box, "%s  (%d)" % [UNIT_NAMES.get(unit_type, unit_type), cost],
			_controller.select_type.bind(unit_type))
		button.toggle_mode = true
		_shop_buttons[unit_type] = button
	_add_button(_deploy_box, "Via!", _controller.start_battle)

	_battle_box = VBoxContainer.new()
	column.add_child(_battle_box)
	_pause_button = _add_button(_battle_box, "Pausa", _controller.toggle_pause)
	var speeds := HBoxContainer.new()
	_battle_box.add_child(speeds)
	for value: int in GameController.SPEEDS:
		var button := _add_button(speeds, "%d×" % value, _controller.set_speed.bind(value))
		button.toggle_mode = true
		_speed_buttons[value] = button

	_result_box = VBoxContainer.new()
	column.add_child(_result_box)
	_result_text = Label.new()
	_result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_box.add_child(_result_text)
	_add_button(_result_box, "Rigioca (stesso seed)", _controller.replay)
	_add_button(_result_box, "Nuova partita", _controller.new_game)

	column.add_child(HSeparator.new())
	var debug_title := Label.new()
	debug_title.text = "Debug"
	column.add_child(debug_title)
	for entry: Array in [[&"labels", "F1 Stato e vita"], [&"grid", "F2 Griglia"],
			[&"reveal_all", "F3 Rivela tutto"], [&"target_lines", "F4 Linee di vista"]]:
		var check := CheckButton.new()
		check.text = entry[1]
		check.focus_mode = Control.FOCUS_NONE
		check.pressed.connect(_controller.toggle_debug.bind(entry[0]))
		column.add_child(check)
		_debug_checks[entry[0]] = check


func _refresh() -> void:
	var c := _controller
	var phase := c.phase
	_recon_box.visible = phase == GameController.Phase.RECON
	_deploy_box.visible = phase == GameController.Phase.DEPLOY
	_battle_box.visible = phase == GameController.Phase.BATTLE
	_result_box.visible = phase == GameController.Phase.RESULT
	_message.text = c.message
	match phase:
		GameController.Phase.RECON:
			_title.text = "Ricognizione"
			_info.text = "Seed %d\nRivelazioni: %d\nClic sinistro: rivela un'area.\nI \"!\" segnalano zone di possibile minaccia." \
				% [c.seed_value, c.fog.reveals_left()]
		GameController.Phase.DEPLOY:
			_title.text = "Schieramento"
			_info.text = "Seed %d\nBudget rimasto: %d su %d\nClic sinistro: piazza. Clic destro: rimuovi.\nSolo celle visibili." \
				% [c.seed_value, c.scenario.budget - c.plan.cost(), c.scenario.budget]
			for unit_type: StringName in _shop_buttons:
				(_shop_buttons[unit_type] as Button).set_pressed_no_signal(unit_type == c.selected_type)
		GameController.Phase.BATTLE:
			_title.text = "Battaglia"
			_info.text = "Seed %d\nTempo: %.1f s\nTimer reliquia: %d / %d\nSpazio: pausa." \
				% [c.seed_value, float(c.world.tick) / c.rules.tick_rate, c.world.relic_timer, c.rules.steal_ticks]
			_pause_button.text = "Riprendi" if c.paused else "Pausa"
			for value: int in _speed_buttons:
				(_speed_buttons[value] as Button).set_pressed_no_signal(value == c.speed)
		GameController.Phase.RESULT:
			var summary := c.summary()
			_title.text = "Vittoria" if c.world.result == "win" else "Sconfitta"
			_info.text = "Seed %d   Varianti: Blitz %s, Caccia %s" % [c.seed_value, c.world.blitz_variant, c.world.hunt_variant]
			var killed := _by_type(summary["killed"])
			if summary["killed_risen"] > 0:
				killed += "\n  + %d rianimati" % summary["killed_risen"]
			_result_text.text = "%s.\nDurata: %.1f s\n\nUnità perse:\n%s\n\nNemici uccisi:\n%s" \
				% [REASONS.get(c.world.reason, c.world.reason), summary["seconds"], _by_type(summary["lost"]), killed]
	for key: StringName in _debug_checks:
		(_debug_checks[key] as CheckButton).set_pressed_no_signal(c.get("debug_" + String(key)))


# "  3 Ratto" lines in the order of UNIT_NAMES; "  nessuna" if empty.
func _by_type(counts: Dictionary) -> String:
	var lines: PackedStringArray = []
	for unit_type: StringName in UNIT_NAMES:
		if counts.has(unit_type):
			lines.append("  %d %s" % [counts[unit_type], UNIT_NAMES[unit_type]])
	return "\n".join(lines) if not lines.is_empty() else "  nessuna"


func _add_button(parent: Container, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _map_width() -> float:
	return _controller.world.map.width * _controller.cell_size_px


func _map_height() -> float:
	return _controller.world.map.height * _controller.cell_size_px
