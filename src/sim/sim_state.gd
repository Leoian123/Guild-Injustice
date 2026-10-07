class_name SimState
extends RefCounted
## Base of every piece of battle state (GDD §12). describe() writes all script variables
## in declaration order and recurses into nested SimState, so a new field reaches the
## state_hash on its own. Fields leave the hash only by being listed in hash_excluded().


## Names of fields that are not battle state: fixed inputs, data derived from them,
## buffers cleared every tick.
func hash_excluded() -> PackedStringArray:
	return PackedStringArray()


func describe() -> String:
	var excluded := hash_excluded()
	var parts: PackedStringArray = [String((get_script() as Script).get_global_name())]
	for property: Dictionary in get_property_list():
		if not (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var name: String = property["name"]
		if name in excluded:
			continue
		parts.append("%s=%s" % [name, format_value(get(name))])
	return "{%s}" % "|".join(parts)


## Exact text of a state value. Unsupported types are an error, never silently skipped.
static func format_value(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "1" if value else "0"
		TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_STRING, TYPE_STRING_NAME:
			return var_to_str(value)
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
				TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY:
			var items: PackedStringArray = []
			for item: Variant in value:
				items.append(format_value(item))
			return "[%s]" % ",".join(items)
		TYPE_OBJECT:
			if value is SimState:
				return (value as SimState).describe()
			if value is RandomNumberGenerator:
				return "rng(%d)" % (value as RandomNumberGenerator).state
	push_error("SimState: cannot describe a value of type %s" % type_string(typeof(value)))
	return "?"
