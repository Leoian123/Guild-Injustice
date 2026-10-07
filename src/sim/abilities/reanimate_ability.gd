class_name ReanimateAbility
extends SimAbility
## Necromancer (GDD §8): when ready, reanimates the nearest corpse within REANIMATE_RADIUS
## and in sight (ties: lower ID), then the cooldown restarts. Ready at the start.

var cooldown: int = 0


func on_tick_start(_world: World, _unit: SimUnit) -> void:
	if cooldown > 0:
		cooldown -= 1


func on_periodic(world: World, unit: SimUnit) -> void:
	if cooldown > 0 or not unit.is_alive():
		return
	var best: SimCorpse = null
	var best_distance: float = 0.0
	for corpse: SimCorpse in world.corpses:
		var distance := unit.position.distance_to(corpse.position)
		if distance > world.rules.reanimate_radius:
			continue
		if not SimVision.has_line_of_sight(world.map, unit.position, corpse.position):
			continue
		# Corpses are sorted by unit ID: a strict comparison keeps the lower ID on ties.
		if best == null or distance < best_distance:
			best = corpse
			best_distance = distance
	if best == null:
		return
	world.reanimate(best)
	cooldown = world.rules.reanimate_cooldown_ticks
