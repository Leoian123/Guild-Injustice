class_name SimCombat
extends RefCounted
## Damage of one hit, from the snapshot only (GDD §6.1, §6.5).


## Multipliers first (attacker abilities), rounded down; then flat reductions
## (target abilities); at least 1.
static func compute_damage(attacker: SimUnit, target: SimUnit, snapshot: SimSnapshot, rules: RulesData) -> int:
	var multiplier: float = 1.0
	for ability: SimAbility in attacker.abilities:
		multiplier *= ability.damage_multiplier(attacker, target, snapshot, rules)
	var reduction: int = 0
	for ability: SimAbility in target.abilities:
		reduction += ability.damage_reduction(target, attacker, snapshot, rules)
	var value: int = floori(attacker.damage * multiplier) - reduction
	return maxi(1, value)
