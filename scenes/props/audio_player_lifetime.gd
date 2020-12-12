extends AudioStreamPlayer3D
class_name AudioPlayerLifetime

var lifetime : float = 5.0

func _process(delta):
	lifetime -= delta
	if lifetime <= 0.0:
		free()
