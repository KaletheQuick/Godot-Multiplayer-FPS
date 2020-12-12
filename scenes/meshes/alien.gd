extends SkMesh

var footstep_sounds : Array = [
	preload("res://sounds/footsteps/barefoot_1.wav"),
	preload("res://sounds/footsteps/barefoot_2.wav"),
	preload("res://sounds/footsteps/barefoot_3.wav"),
	preload("res://sounds/footsteps/barefoot_4.wav")
]

func _ready():
	ragdoll_scene = preload("res://scenes/meshes/alien_ragdoll.tscn")

func set_visible_to_camera(value : bool):
	.set_visible_to_camera(value)
	$skeleton/blaster.set_layer_mask_bit(0, value)
	$skeleton/blaster.set_layer_mask_bit(10, !value)

func play_footstep() -> void:
	if character.dir.dot(character.vel) > 0.1:
		$sounds/footstep.stream = footstep_sounds[randi() % footstep_sounds.size()]
		$sounds/footstep.play()

func is_alien():
	return true
