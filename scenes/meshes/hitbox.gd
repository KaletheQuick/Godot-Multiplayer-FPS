extends StaticBody
class_name Hitbox

var active : bool = false
export var damage : float = 5.0
export var pb_name : String = "pb_root"

func is_hitbox():
	return true
