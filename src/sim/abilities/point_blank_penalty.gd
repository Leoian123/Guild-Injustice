class_name PointBlankPenalty
extends SimAbility
## Archer (GDD §7): with any enemy within POINT_BLANK_RADIUS, damage × POINT_BLANK_MULT.


func damage_multiplier(attacker: SimUnit, _target: SimUnit, snapshot: SimSnapshot, rules: RulesData) -> float:
	var position := snapshot.position_of(attacker.id)
	for index: int in snapshot.size():
		if not snapshot.alive[index] or snapshot.factions[index] == attacker.faction:
			continue
		if snapshot.positions[index].distance_to(position) <= rules.point_blank_radius:
			return rules.point_blank_mult
	return 1.0
