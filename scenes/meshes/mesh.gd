extends Spatial
class_name SkMesh

var anim_tree : AnimationTree
var anim_state_machine : AnimationNodeStateMachinePlayback
var run_blend : Vector2 = Vector2(0.0, 0.0)
var ragdoll_scene : PackedScene
var hitboxes : Array = []
var color : Color

var character : KinematicBody setget set_character

func _ready():
	anim_tree = $animation_tree
	anim_tree.active = true
	anim_state_machine = anim_tree.get("parameters/state_machine/playback")
	var _skeleton_children : Array
	Game.get_all_children($skeleton, _skeleton_children)
	for n in _skeleton_children:
		if n.has_method("is_hitbox"):
			hitboxes.push_back(n)
	# Visibility
	set_visible_to_camera(true)
	
func _process(delta):
	if character.state != character.DEAD:
		# Animations
		# Aim up and down
		var look_y = clamp(sin(character.head.rotation.x), -1.57, 1.57)
		look_y = range_lerp(look_y, -1.57, 1.57, -1.0, 1.0)
		anim_tree.set("parameters/look_y/add_amount", look_y)
		# Locomotion
		if character.state == character.GROUND:
			var run_blend_target = Vector2(character.vel.dot(character.global_transform.basis.x), character.vel.dot(character.global_transform.basis.z * -1))
			run_blend = lerp(run_blend, run_blend_target, delta * 15.0)
			anim_tree.set("parameters/state_machine/ground/blend_position", run_blend)

func _on_character_state_changed(new_state, _old_state):
	match new_state:
		character.AIR:
			anim_state_machine.travel("air")
		character.GROUND:
			anim_state_machine.travel("ground")
		character.WATER:
			anim_state_machine.travel("air")
		character.CLIMB:
			anim_state_machine.travel("air")
		character.DEAD:
			pass
		character.FLY:
			anim_state_machine.travel("air")

# Set mesh visibility to player's camera.
# Because we don't want to see the player's mesh by default.
# Only in ragdoll state.
func set_visible_to_camera(value : bool):
	$skeleton/mesh.set_layer_mask_bit(0, value)
	$skeleton/mesh.set_layer_mask_bit(10, !value)
	for hitbox in hitboxes:
		hitbox.get_parent().visible = value

func enable_ragdoll_collisions(value : bool):
	var sk_children = $skeleton.get_children()
	for i in sk_children:
		if i is PhysicalBone:
			i.get_node("shape").disabled = !value

func spawn_ragdoll(impulse):
	if ragdoll_scene != null:
		var ragdoll = ragdoll_scene.instance()
		if ragdoll.has_method("set_color"):
			ragdoll.set_color(color)
		Game.garbage.add_child(ragdoll)
		ragdoll.global_transform = $skeleton.global_transform
		for i in ragdoll.get_bone_count():
			ragdoll.set_bone_pose(i, $skeleton.get_bone_pose(i))
		yield(get_tree().create_timer(0.001), "timeout")
		ragdoll.physical_bones_start_simulation()
		for hitbox in hitboxes:
			var pb = ragdoll.get_node(hitbox.pb_name)
			var hitbox_children = hitbox.get_children()
			for child in hitbox_children:
				if child is Impact:
					hitbox.remove_child(child)
					pb.add_child(child)
			if hitbox.active:
				pb.apply_central_impulse(impulse * 5.0)

func set_character(new_character : KinematicBody):
	character = new_character
	var _state_changed_connected = character.connect("state_changed", self, "_on_character_state_changed")
