extends SceneTree
## Headless simulation entry point (GDD §11). Arguments come from OS.get_cmdline_user_args().
## M1: parses the arguments and creates one World per seed.

const RULES_PATH: String = "res://data/rules.tres"
const EXIT_OK: int = 0
const EXIT_BAD_ARGS: int = 1

const USAGE: String = "usage: sim.sh --scenario <id> --strategy <file.json> (--seed <n> | --seeds <from>-<to>) --out <file.jsonl>"


func _initialize() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	if options.has("error"):
		printerr("sim: %s" % options["error"])
		printerr(USAGE)
		quit(EXIT_BAD_ARGS)
		return

	var rules := load(RULES_PATH) as RulesData
	var seeds: Array[int] = options["seeds"]
	for seed_value: int in seeds:
		var world := World.new(rules, seed_value)
		print("sim: scenario=%s seed=%d world created, state_hash=%s" % [
			options["scenario"], seed_value, world.state_hash()])
	quit(EXIT_OK)


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
