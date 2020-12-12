extends Skeleton

var lifetime : float = 10.0

func _ready():
	pass

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func is_alien_ragdoll():
	return true
