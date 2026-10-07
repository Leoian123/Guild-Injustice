class_name HungerWill
extends SimWill
## Hunger (GDD §6.8): chases anything while hungry, nothing while sated.

var bites_left: int = 0
var digest_ticks: int = 0


func is_sated() -> bool:
	return digest_ticks > 0


func on_spawn(world: World, _unit: SimUnit) -> void:
	bites_left = world.rules.rat_hunger_bites


func on_tick_start(world: World, _unit: SimUnit) -> void:
	if digest_ticks > 0:
		digest_ticks -= 1
		if digest_ticks == 0:
			bites_left = world.rules.rat_hunger_bites


func accepts(_world: World, _unit: SimUnit, _enemy: SimUnit) -> bool:
	return not is_sated()


func on_attack_landed(world: World, _unit: SimUnit) -> void:
	bites_left -= 1
	if bites_left <= 0:
		bites_left = 0
		digest_ticks = world.rules.rat_digest_ticks
