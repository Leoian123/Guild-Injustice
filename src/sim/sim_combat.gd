class_name SimCombat
extends RefCounted
## Damage of one hit, from the snapshot only (GDD §6.1, §6.5).


## Multipliers first, rounded down; then flat reductions; at least 1.
## Ability multipliers and reductions arrive in M4.
static func compute_damage(attacker: SimUnit, _target: SimUnit, _snapshot: SimSnapshot, _rules: RulesData) -> int:
	var multiplier: float = 1.0
	var reduction: int = 0
	var value: int = floori(attacker.damage * multiplier) - reduction
	return maxi(1, value)
