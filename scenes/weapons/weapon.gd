extends Spatial
class_name Weapon

onready var shooter : KinematicBody = get_owner()
var hitboxes : Array

var first_person_animations : bool = false
var anim_tree : AnimationTree
var anim_state_machine : AnimationNodeStateMachinePlayback

func _ready():
	var _controller_changed_connected = shooter.connect("controller_changed", self, "_on_shooter_controller_changed")

func _enter_tree():
	pass

func _on_shooter_controller_changed():
	get_hitboxes()
	visible = shooter.controller.has_method("is_player")

func get_hitboxes():
	var _skeleton_children : Array
	Game.get_all_children(shooter.get_node("mesh/skeleton"), _skeleton_children)
	for n in _skeleton_children:
		if n is Hitbox:
			hitboxes.push_back(n)

func _process(_delta):
	pass

func fire():
	pass

func random_spread(spread : float):
	return Vector3(rand_range(-spread, spread), rand_range(-spread, spread), rand_range(-spread, spread))

func is_weapon():
	return true
