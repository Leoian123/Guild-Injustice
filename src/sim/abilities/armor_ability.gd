class_name ArmorAbility
extends SimAbility
## Paladin (GDD §7): every hit is reduced by ARMOR_REDUCTION, unless at least
## SURROUND_COUNT living enemies are within SURROUND_RADIUS in the snapshot.


func damage_reduction(target: SimUnit, _attacker: SimUnit, snapshot: SimSnapshot, rules: RulesData) -> int:
	var position := snapshot.position_of(target.id)
	var enemies: int = 0
	for index: int in snapshot.size():
		if not snapshot.alive[index] or snapshot.factions[index] == target.faction:
			continue
		if snapshot.positions[index].distance_to(position) <= rules.surround_radius:
			enemies += 1
	if enemies >= rules.surround_count:
		return 0
	return rules.armor_reduction
