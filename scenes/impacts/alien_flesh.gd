extends Impact

func _ready():
	$sound.pitch_scale = rand_range(0.8, 1.2)
	$dust.emitting = true
	$particles.emitting = true
	Game.create_splatter(global_transform.origin, Color("#02ce00"))
