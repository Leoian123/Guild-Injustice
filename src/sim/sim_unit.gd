class_name SimUnit
extends RefCounted
## Runtime state of one unit. Values are copied from UnitData at creation.

enum Faction { PLAYER, ENEMY }
enum State { IDLE, MOVE, ATTACK, FLEE, DEAD }

const NO_TARGET: int = -1

var id: int = 0
var unit_type: StringName = &""
var faction: Faction = Faction.PLAYER
var state: State = State.IDLE
var hp: int = 0
var position: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.ZERO
var target_id: int = NO_TARGET
var attack_cd: int = 0
var ai_enabled: bool = true


func _init(p_id: int, p_data: UnitData, p_faction: Faction, p_position: Vector2) -> void:
	id = p_id
	unit_type = p_data.unit_type
	faction = p_faction
	hp = p_data.max_hp
	position = p_position
