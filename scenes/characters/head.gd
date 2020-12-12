extends Position3D

# Strafe leaning
const LEAN_SMOOTH : float = 10.0
const LEAN_MULT : float = 0.066

func _physics_process(delta):
	$container.rotation.z = lerp($container.rotation.z, (float(get_parent().get_action(2)) - float(get_parent().get_action(3))) * LEAN_MULT, delta * LEAN_SMOOTH)
