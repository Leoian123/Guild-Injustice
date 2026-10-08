class_name PreyWill
extends SimWill
## The prey (GDD §7, rabbit): never accepts a target; without one it wanders in a swarm of its
## own kind, always leashed to its den.

## Where the unit was released; newborns take the den of their first parent.
var den: Vector2 = Vector2.ZERO


func on_spawn(_world: World, unit: SimUnit) -> void:
	den = unit.position


func accepts(_world: World, _unit: SimUnit, _enemy: SimUnit) -> bool:
	return false


func leash_point() -> Variant:
	return den


func inherit_den(parent_will: SimWill) -> void:
	if parent_will is PreyWill:
		den = (parent_will as PreyWill).den
