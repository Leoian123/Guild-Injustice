class_name HoldGroundWill
extends SimWill
## Courage (GDD §6.8): chases only what it can reach within chase_radius of its post.


func accepts(_world: World, unit: SimUnit, enemy: SimUnit) -> bool:
	return unit.home.distance_to(enemy.position) <= unit.chase_radius + unit.attack_range


func idle_destination(_world: World, unit: SimUnit) -> Variant:
	return unit.home


func allows_kite_step(_world: World, unit: SimUnit, position: Vector2) -> bool:
	return unit.home.distance_to(position) <= unit.chase_radius
