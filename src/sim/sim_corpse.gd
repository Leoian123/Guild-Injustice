class_name SimCorpse
extends SimState
## A corpse left by a dead unit (GDD §6.7).

var unit_id: int = 0
var unit_type: StringName = &""
var position: Vector2 = Vector2.ZERO
var ttl: int = 0
## Integrity left (GDD §6.7): rats eat it, reanimation needs at least 1.
var integrity: int = 0
## Outcome of the reanimation roll at death (GDD §6.7).
var reanimable: bool = false
