extends Skeleton

var color : Color setget set_color

func _ready():
	var children = get_children()
	$pb_head/noise.stream = Game.gobot_noises[randi() % Game.gobot_noises.size()]
	$pb_head/noise.play()
	yield(get_tree().create_timer(3.0), "timeout")
	$pb_root/sound.unit_db = -80.0
	$pb_root/damage.emitting = false
	var explosion = Game.explosion_scn.instance()
	Game.garbage.add_child(explosion)
	explosion.global_transform.origin = $pb_root.global_transform.origin
	for child in children:
		if child is PhysicalBone:
			child.joint_type = PhysicalBone.JOINT_TYPE_NONE
			child.apply_central_impulse((child.global_transform.origin - $pb_root.global_transform.origin).normalized() * 30.0)
	$pb_root.scale = Vector3(0.001, 0.001, 0.001)
	yield(get_tree().create_timer(2.0), "timeout")
	free()

func set_color(new_color : Color):
	color = new_color
	$mesh.get_surface_material(0).set("shader_param/color", new_color)
	$mesh.get_surface_material(1).set("emission", new_color)

func is_gobot_ragdoll():
	return true
