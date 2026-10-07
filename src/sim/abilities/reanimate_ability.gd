class_name ReanimateAbility
extends SimAbility
## Necromancer (GDD §8): when ready, reanimates the reanimable corpse within REANIMATE_RADIUS
## and in sight with the highest max HP (ties: nearest, then lower ID), then the cooldown
## restarts. Ready at the start. In a tick when it will reanimate, it does not attack.

var cooldown: int = 0


func on_tick_start(_world: World, _unit: SimUnit) -> void:
	if cooldown > 0:
		cooldown -= 1


func blocks_attack(world: World, unit: SimUnit) -> bool:
	return cooldown == 0 and choose_corpse(world, unit) != null


func on_periodic(world: World, unit: SimUnit) -> void:
	if cooldown > 0 or not unit.is_alive():
		return
	var corpse := choose_corpse(world, unit)
	if corpse == null:
		return
	world.reanimate(corpse)
	cooldown = world.rules.reanimate_cooldown_ticks


## Flesh shields: highest max HP first, then nearest, then lower ID.
func choose_corpse(world: World, unit: SimUnit) -> SimCorpse:
	var best: SimCorpse = null
	var best_hp: int = 0
	var best_distance: float = 0.0
	for corpse: SimCorpse in world.corpses:
		if not corpse.reanimable:
			continue
		var distance := unit.position.distance_to(corpse.position)
		if distance > world.rules.reanimate_radius:
			continue
		if not SimVision.has_line_of_sight(world.map, unit.position, corpse.position):
			continue
		var max_hp := world.get_unit(corpse.unit_id).max_hp
		# Corpses are sorted by unit ID: strict comparisons keep the lower ID on full ties.
		if best == null or max_hp > best_hp or (max_hp == best_hp and distance < best_distance):
			best = corpse
			best_hp = max_hp
			best_distance = distance
	return best
