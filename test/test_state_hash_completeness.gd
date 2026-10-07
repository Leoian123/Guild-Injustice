extends GdUnitTestSuite
## Guard for GDD §12: every state field of every entity reaches the state_hash.
## Not a rule test from docs/TESTS.md: it protects the hash itself.


func test_every_state_field_changes_the_hash() -> void:
	var world := _sample_world()
	var entities: Array[SimState] = [world]
	for unit: SimUnit in world.units:
		entities.append(unit)
		entities.append(unit.will)
		entities.append_array(unit.abilities)
	entities.append_array(world.corpses)
	assert_array(world.corpses).is_not_empty()

	var checked: int = 0
	for entity: SimState in entities:
		for property: Dictionary in entity.get_property_list():
			if not (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var name: String = property["name"]
			if name in entity.hash_excluded():
				continue
			var original: Variant = entity.get(name)
			var changed: Variant = _changed(original)
			if changed == null:
				# Containers and nested entities are covered through their own fields.
				continue
			var before := world.state_hash()
			entity.set(name, changed)
			var after := world.state_hash()
			entity.set(name, original)
			assert_str(after).override_failure_message(
				"%s.%s does not reach the state_hash" % [entity.get_script().get_global_name(), name]
			).is_not_equal(before)
			checked += 1
	# Sanity: the walk really visited fields of every entity kind.
	assert_int(checked).is_greater(30)


func test_rng_state_changes_the_hash() -> void:
	var world := _sample_world()
	var before := world.state_hash()
	world.rng.randi()
	assert_str(world.state_hash()).is_not_equal(before)


# Every will and ability, a corpse and some history behind them. The necromancer stays
# beyond REANIMATE_RADIUS so the corpse is not reanimated.
func _sample_world() -> World:
	var world := TestWorlds.world(3)
	TestWorlds.spawn(world, &"rat", SimUnit.Faction.PLAYER, Vector2i(5, 5), true)
	TestWorlds.spawn(world, &"goblin", SimUnit.Faction.PLAYER, Vector2i(6, 6), true)
	TestWorlds.spawn(world, &"archer", SimUnit.Faction.PLAYER, Vector2i(3, 3), true)
	TestWorlds.spawn(world, &"thief", SimUnit.Faction.PLAYER, Vector2i(4, 7), true)
	TestWorlds.spawn(world, &"paladin", SimUnit.Faction.PLAYER, Vector2i(6, 3), true)
	TestWorlds.spawn(world, &"necromancer", SimUnit.Faction.ENEMY, Vector2i(20, 2), true)
	var servant := TestWorlds.spawn(world, &"servant", SimUnit.Faction.ENEMY, Vector2i(7, 5), true)
	TestWorlds.add_anchors(world)
	servant.hp = 1
	TestWorlds.run_until(world, 20)
	return world


# A different value of the same type, or null for containers and nested entities.
func _changed(value: Variant) -> Variant:
	match typeof(value):
		TYPE_BOOL:
			return not value
		TYPE_INT:
			return value + 1
		TYPE_FLOAT:
			return value + 0.5
		TYPE_VECTOR2:
			return value + Vector2(0.5, 0.25)
		TYPE_STRING_NAME:
			return StringName(String(value) + "_x")
		TYPE_STRING:
			return value + "_x"
	return null
