extends SceneTree
## Saves a PNG of one frame of the game in a given phase, for the agent's visual check (M5).
## Run WITHOUT --headless:
##   "$GODOT" --path . -s res://tools/screenshot.gd -- --phase deploy --out reports/raw/shot.png
## Options: --phase recon|deploy|battle|result (default recon), --strategy <res path or file>
## (default s1_sciame_e_lame), --seed <n> (default 42), --ticks <n> for battle (default 200),
## --debug labels,grid,reveal_all,target_lines.

const MAIN_SCENE: String = "res://src/main.tscn"
const DEFAULT_STRATEGY: String = "res://tools/strategies/s1_sciame_e_lame.json"
const RESULT_TICK_LIMIT: int = 6000


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse(OS.get_cmdline_user_args())
	var controller := (load(MAIN_SCENE) as PackedScene).instantiate() as GameController
	root.add_child(controller)
	await process_frame
	controller.start_game(int(options.get("seed", "42")))
	for flag: String in String(options.get("debug", "")).split(",", false):
		controller.toggle_debug(StringName(flag))

	var strategy := SimStrategy.load_file(_strategy_path(options.get("strategy", DEFAULT_STRATEGY)))
	var world := controller.world
	var reveals := strategy.reveals_for(world.blitz_variant, world.hunt_variant)
	var phase: String = options.get("phase", "recon")
	if phase == "recon":
		if not reveals.is_empty():
			controller.reveal(reveals[0])
	else:
		for cell: Vector2i in reveals:
			controller.reveal(cell)
		controller.end_recon()
		for entry: Dictionary in strategy.plan_for(world.blitz_variant, world.hunt_variant).entries:
			controller.select_type(entry["type"])
			if controller.selected_guard != entry["guard"]:
				controller.toggle_guard()
			controller.place(entry["cell"])
		if phase == "battle":
			controller.start_battle()
			controller.advance(int(options.get("ticks", "200")))
			controller.toggle_pause()
		elif phase == "result":
			controller.start_battle()
			controller.advance(RESULT_TICK_LIMIT)

	for i: int in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var out: String = options.get("out", "reports/raw/screenshot_%s.png" % phase)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := root.get_viewport().get_texture().get_image().save_png(out)
	print("screenshot: phase=%s seed=%s variants=%s-%s message='%s' -> %s (%s)" % [
		phase, options.get("seed", "42"), world.blitz_variant, world.hunt_variant,
		controller.message, out, error_string(error)])
	quit(0 if error == OK else 1)


func _parse(args: PackedStringArray) -> Dictionary:
	var options: Dictionary = {}
	var i: int = 0
	while i + 1 < args.size():
		options[args[i].trim_prefix("--")] = args[i + 1]
		i += 2
	return options


func _strategy_path(value: String) -> String:
	if value.begins_with("res://") or value.is_absolute_path():
		return value
	return "res://" + value
