extends SceneTree
## Headless simulation entry point (GDD §11). Arguments come from OS.get_cmdline_user_args().
## Validates the strategy for every seed first (exit 2 and the reason on stderr), then runs
## the battles, writes one JSON line per battle to --out and a readable summary to stdout.
## Paths are relative to the project root.

const EXIT_OK: int = 0
const EXIT_BAD_ARGS: int = 1
const EXIT_INVALID_STRATEGY: int = 2
const COMBINATIONS: Array[String] = ["A-A", "A-B", "B-A", "B-B"]

const USAGE: String = "usage: sim.sh --scenario <id> --strategy <file.json> (--seed <n> | --seeds <from>-<to>) --out <file.jsonl>"


func _initialize() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	if options.has("error"):
		_fail(EXIT_BAD_ARGS, options["error"], true)
		return
	var scenario_path := "res://data/scenarios/%s.tres" % options["scenario"]
	if not ResourceLoader.exists(scenario_path):
		_fail(EXIT_BAD_ARGS, "unknown scenario '%s'" % options["scenario"], false)
		return
	var scenario := load(scenario_path) as ScenarioData
	var rules := SimScenario.load_rules()
	var strategy := SimStrategy.load_file(_project_path(options["strategy"]))
	if strategy == null:
		_fail(EXIT_BAD_ARGS, "cannot read strategy '%s'" % options["strategy"], false)
		return
	var seeds: Array[int] = options["seeds"]

	# Validation first: an invalid strategy produces no output at all (GDD §11).
	var worlds: Array[World] = []
	for seed_value: int in seeds:
		var prepared := SimRunner.prepare(scenario, rules, strategy, seed_value)
		if prepared.has("error"):
			_fail(EXIT_INVALID_STRATEGY, "invalid strategy '%s' for seed %d, %s" % [
				strategy.strategy_name, seed_value, prepared["error"]], false)
			return
		worlds.append(prepared["world"])

	var out := FileAccess.open(ProjectSettings.globalize_path(_project_path(options["out"])), FileAccess.WRITE)
	if out == null:
		_fail(EXIT_BAD_ARGS, "cannot write '%s'" % options["out"], false)
		return
	var wins: Dictionary = {}
	var games: Dictionary = {}
	for i: int in seeds.size():
		var result := SimRunner.run_to_end(worlds[i], scenario, strategy, seeds[i])
		out.store_line(JSON.stringify(result, "", false))
		var combination := "%s-%s" % [result["variant"]["blitz"], result["variant"]["hunt"]]
		games[combination] = games.get(combination, 0) + 1
		if result["result"] == "win":
			wins[combination] = wins.get(combination, 0) + 1
	out.close()
	_print_summary(strategy.strategy_name, seeds.size(), wins, games)
	quit(EXIT_OK)


func _print_summary(strategy_name: String, total: int, wins: Dictionary, games: Dictionary) -> void:
	var won: int = 0
	for combination: String in wins:
		won += wins[combination]
	print("sim: %s — wins %d/%d" % [strategy_name, won, total])
	for combination: String in COMBINATIONS:
		if games.has(combination):
			print("sim:   %s  %d/%d" % [combination, wins.get(combination, 0), games[combination]])


func _fail(code: int, message: String, with_usage: bool) -> void:
	printerr("sim: %s" % message)
	if with_usage:
		printerr(USAGE)
	quit(code)


# Project-root-relative paths become res:// paths; absolute and res:// paths stay.
func _project_path(path: String) -> String:
	if path.begins_with("res://") or path.is_absolute_path():
		return path
	return "res://" + path


func _parse_args(args: PackedStringArray) -> Dictionary:
	var values: Dictionary = {}
	var i: int = 0
	while i < args.size():
		var key: String = args[i]
		if not key in ["--scenario", "--strategy", "--seed", "--seeds", "--out"]:
			return {"error": "unknown argument '%s'" % key}
		if i + 1 >= args.size():
			return {"error": "missing value for '%s'" % key}
		values[key] = args[i + 1]
		i += 2

	for required: String in ["--scenario", "--strategy", "--out"]:
		if not values.has(required):
			return {"error": "missing '%s'" % required}
	if values.has("--seed") == values.has("--seeds"):
		return {"error": "give exactly one of '--seed' and '--seeds'"}

	var seeds: Array[int] = []
	if values.has("--seed"):
		var text: String = values["--seed"]
		if not text.is_valid_int():
			return {"error": "invalid seed '%s'" % text}
		seeds.append(text.to_int())
	else:
		var bounds: PackedStringArray = (values["--seeds"] as String).split("-")
		if bounds.size() != 2 or not bounds[0].is_valid_int() or not bounds[1].is_valid_int():
			return {"error": "invalid seed range '%s'" % values["--seeds"]}
		var first: int = bounds[0].to_int()
		var last: int = bounds[1].to_int()
		if first > last:
			return {"error": "invalid seed range '%s'" % values["--seeds"]}
		for seed_value: int in range(first, last + 1):
			seeds.append(seed_value)

	return {
		"scenario": values["--scenario"],
		"strategy": values["--strategy"],
		"out": values["--out"],
		"seeds": seeds,
	}
