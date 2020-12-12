extends Camera

# Shake
var magnitude : float = 0.0
var lifetime : float = 0.0
var offset_delay : float = 0.0
var is_shaking : bool = false
var should_shake : bool = false
var offset : Vector3 = Vector3.ZERO

func _physics_process(delta):
	if should_shake:
		offset_delay -= delta
		if offset_delay <= 0.0:
			offset_delay = 0.05
			offset.x = rand_range(-magnitude, magnitude)
			offset.y = rand_range(-magnitude, magnitude)
		lifetime -= delta
		if lifetime <= 0.0:
			should_shake = false
			magnitude = 0
			offset = Vector3.ZERO
	
	if rotation.length() > 0.01:
		rotation = lerp(rotation, offset, delta * 5.0)
	else:
		rotation = Vector3.ZERO

func shake(new_magnitude, new_lifetime):
	if magnitude <= new_magnitude:
		magnitude = new_magnitude
		lifetime = new_lifetime
		should_shake = true
		rotation.x = 0.02
