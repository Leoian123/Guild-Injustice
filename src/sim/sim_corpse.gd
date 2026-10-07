class_name SimCorpse
extends SimState
## A corpse left by a dead unit (GDD §6.7).

var unit_id: int = 0
var unit_type: StringName = &""
var position: Vector2 = Vector2.ZERO
var ttl: int = 0
