extends SkMesh

var shell_scene : PackedScene = preload("res://scenes/props/shell.tscn")

var footstep_sounds : Array = [
	preload("res://sounds/footsteps/generic_1.wav"),
	preload("res://sounds/footsteps/generic_2.wav"),
	preload("res://sounds/footsteps/generic_3.wav"),
	preload("res://sounds/footsteps/generic_4.wav"),
	preload("res://sounds/footsteps/generic_5.wav"),
	preload("res://sounds/footsteps/generic_6.wav")
]

var weapon_anim_player : AnimationPlayer

func _ready():
	# Ragdoll
	ragdoll_scene = preload("res://scenes/meshes/gobot_ragdoll.tscn")
	# Random color
	color = Color(Game.colors[randi() % Game.colors.size()])
	$skeleton/mesh.get_surface_material(0).set("shader_param/color", color)
	$skeleton/mesh.get_surface_material(1).set("emission", color)
	# Weapon animations
	weapon_anim_player = $skeleton/a_hand_r/animation_player

func _process(_delta):
	if character.get_action(5):
		anim_tree.set("parameters/fire/active", true)
		weapon_anim_player.play("Boomstick_Fire")

func spawn_shells() -> void:
	var shell_1 = shell_scene.instance()
	Game.garbage.add_child(shell_1)
	shell_1.global_transform = $skeleton/a_hand_r/skeleton.global_transform * $skeleton/a_hand_r/skeleton.get_bone_global_pose(2)
	shell_1.rotation_degrees += Vector3(0.0, 45.0, 0.0)
	shell_1.apply_central_impulse(shell_1.transform.basis.z * -4 + character.vel)
	var shell_2 = shell_scene.instance()
	Game.garbage.add_child(shell_2)
	shell_2.global_transform = $skeleton/a_hand_r/skeleton.global_transform * $skeleton/a_hand_r/skeleton.get_bone_global_pose(4)
	shell_2.rotation_degrees += Vector3(0.0, 45.0, 0.0)
	shell_2.apply_central_impulse(shell_2.transform.basis.z * -4 + character.vel)

func play_footstep() -> void:
	if character.dir.dot(character.vel) > 0.1:
		$sounds/footsteps.stream = footstep_sounds[randi() % footstep_sounds.size()]
		$sounds/footsteps.play()

func set_visible_to_camera(value : bool):
	.set_visible_to_camera(value)
	$skeleton/a_hand_r/skeleton/boomstick.set_layer_mask_bit(0, value)
	$skeleton/a_hand_r/skeleton/boomstick.set_layer_mask_bit(10, !value)

func is_gobot():
	return true
