extends Node

# This is a global script. It autoloads and we can access it from other scripts. A singleton.
# It contains useful functions and preloads different scenes and effects.

# Main scene for quick access.
onready var main = get_tree().root.get_child(get_tree().root.get_child_count() - 1)

# This node is a container for spawned instances like declas, particles etc.
onready var garbage = main.get_node("garbage")

# Impacts
onready var impact_scns = [
	preload("res://scenes/impacts/concrete.tscn"),
	preload("res://scenes/impacts/metal.tscn"),
	preload("res://scenes/impacts/alien_flesh.tscn")
]

# Other effects
onready var burn_scn = preload("res://scenes/impacts/burn.tscn")
onready var stain_scn = preload("res://scenes/effects/stain.tscn")
onready var splatter_scn = preload("res://scenes/effects/splatter.tscn")
onready var explosion_scn = preload("res://scenes/weapons/explosion.tscn")

# Footsteps
onready var footsteps = {
	generic = [
		preload("res://sounds/footsteps/generic_1.wav"),
		preload("res://sounds/footsteps/generic_2.wav"),
		preload("res://sounds/footsteps/generic_3.wav"),
		preload("res://sounds/footsteps/generic_4.wav"),
		preload("res://sounds/footsteps/generic_5.wav"),
		preload("res://sounds/footsteps/generic_6.wav")
	],
	metal = [
		preload("res://sounds/footsteps/metal_1.wav"),
		preload("res://sounds/footsteps/metal_2.wav"),
		preload("res://sounds/footsteps/metal_3.wav"),
		preload("res://sounds/footsteps/metal_4.wav"),
		preload("res://sounds/footsteps/metal_5.wav"),
		preload("res://sounds/footsteps/metal_6.wav")
	],
	soil = [
		preload("res://sounds/footsteps/soil_1.wav"),
		preload("res://sounds/footsteps/soil_2.wav"),
		preload("res://sounds/footsteps/soil_3.wav"),
		preload("res://sounds/footsteps/soil_4.wav"),
		preload("res://sounds/footsteps/soil_5.wav"),
		preload("res://sounds/footsteps/soil_6.wav")
	],
	ladder = [
		preload("res://sounds/footsteps/ladder_1.wav"),
		preload("res://sounds/footsteps/ladder_2.wav"),
		preload("res://sounds/footsteps/ladder_3.wav"),
		preload("res://sounds/footsteps/ladder_4.wav"),
		preload("res://sounds/footsteps/ladder_5.wav"),
		preload("res://sounds/footsteps/ladder_6.wav")
	]
}

# Gobot noises
var gobot_noises = [
	preload("res://sounds/gobot/noise_1.wav"),
	preload("res://sounds/gobot/noise_2.wav"),
	preload("res://sounds/gobot/noise_3.wav")
]

# Impact sounds
onready var hit_sounds = {
	concrete = [
		preload("res://sounds/physics/impacts/concrete_1.wav")
	],
	metal = [
		preload("res://sounds/physics/metal/metal_hit_1.wav"),
		preload("res://sounds/physics/metal/metal_hit_2.wav"),
		preload("res://sounds/physics/metal/metal_hit_3.wav"),
		preload("res://sounds/physics/metal/metal_hit_4.wav"),
		preload("res://sounds/physics/metal/metal_hit_5.wav"),
		preload("res://sounds/physics/metal/metal_hit_6.wav")
	]
}

# Scratching/sliding sounds
onready var slide_sounds = {
	concrete = preload("res://sounds/physics/metal/metal_slide.wav"),
	metal = preload("res://sounds/physics/metal/metal_slide.wav")
}

# Controllers
onready var char_scn = preload("res://scenes/characters/character.tscn")
onready var player_scn = preload("res://scenes/controllers/player.tscn")
onready var puppet_scn = preload("res://scenes/controllers/puppet.tscn")
onready var bot_scn = preload("res://scenes/controllers/bot.tscn")

# Character meshes
onready var gobot_scn = preload("res://scenes/meshes/gobot.tscn")
onready var alien_scn = preload("res://scenes/meshes/alien.tscn")

# Weapons
onready var boomstick_scn = preload("res://scenes/weapons/boomstick.tscn")

# Gameplay
var spawn_points : Array = []
var interest_points : Array = []

# Cool colors
var colors = ["#ffc100", "#c356ea", "#26e129", "#0079ff", "#fa1028"]

# Helper functions
func is_server() -> bool:
	return get_tree().is_network_server()

func is_bit_enabled(mask : int, index : int) -> bool:
	return mask & (1 << index) != 0

func enable_bit(mask : int, index : int) -> int:
	return mask | 1 << index

func disable_bit(mask : int, index : int) -> int:
	return mask & ~(1 << index)

# Don't use, doesn't work
func get_single_enabled_bit(mask : int) -> int:
	if mask == 0:
		return -1
	var i = 0
	var pos = 0
	while (i & mask) == 0:
		i = i << 1
		pos += 1
	return pos

# Misc functions
func display_message(text : String):
	main.get_node("ui/message").text = text
	yield(get_tree().create_timer(3.0), "timeout")
	main.get_node("ui/message").text = ""

func create_splatter(pos, color):
	if pos == null:
		pos = self.global_transform.origin
	var splatter = Game.splatter_scn.instance()
	splatter.color = color
	garbage.add_child(splatter)
	splatter.global_transform.origin = pos
	for i in 4:
		var state : PhysicsDirectSpaceState = garbage.get_world().direct_space_state
		randomize()
		var rand_dir = Vector3(pos.x + rand_range(-100, 100), pos.y - 100, pos.z + rand_range(-100, 100))
		var result = state.intersect_ray(pos, rand_dir, [], 1)
		if result:
			if result.collider is StaticBody:
				var stain = Game.stain_scn.instance()
				stain.color = color
				Game.garbage.add_child(stain)
				stain.global_transform.origin = result.position + result.normal * 0.01
				stain.look_at(result.position - result.normal, Vector3(1, 1, 0))

func create_impact(parent : Node, pos : Vector3, norm : Vector3, material : PhysicsMaterial):
	var impact_index = 0
	if material:
		match material.resource_name:
			"Metal":
				impact_index = 1
			"Alien":
				impact_index = 2
	var impact = impact_scns[impact_index].instance()
	parent.add_child(impact)
	impact.global_transform.origin = pos + norm * 0.01
	impact.look_at(pos - norm, Vector3(1, 1, 0))
	impact.rotation = Vector3(impact.rotation.x, impact.rotation.y, rand_range(-1, 1))
	var rand_scale = rand_range(0.75, 1.25)
	impact.scale = Vector3(rand_scale, rand_scale, rand_scale)

# Not sture why we need those, godot has lerp, normalize and range_lerp
func interp(norm, min_value, max_value):
	return (max_value - min_value) * norm + min_value

func norm(value, min_value, max_value):
	return (value - min_value) / (max_value - min_value)

func map(value, source_min, source_max, dest_min, dest_max):
	return interp(norm(value, source_min, source_max), dest_min, dest_max)

func random_point(area : float, height : float):
	return Vector3(rand_range(-area, area), height, rand_range(-area, area))

func get_random_spawn():
	return Game.spawn_points[randi() % Game.spawn_points.size()].translation

func get_all_children(node : Node, array : Array):
	for n in node.get_children():
		array.push_back(n)
		if n.get_child_count() > 0:
			get_all_children(n, array)

func predicted_position(target_position : Vector3, shooter_position : Vector3, target_velocity : Vector3, projectile_speed : float) -> Vector3:
	var displacement = target_position - shooter_position
	var target_move_angle = deg2rad(target_velocity.angle_to(-displacement))
	if target_velocity.length() == 0 or target_velocity.length() > projectile_speed and sin(target_move_angle) / projectile_speed > cos(target_move_angle) / target_velocity.length():
		return target_position
	var shoot_angle = asin(sin(target_move_angle) * target_velocity.length() / projectile_speed)
	return target_position + target_velocity * displacement.length() / sin(PI - target_move_angle - shoot_angle) * sin(shoot_angle) / target_velocity.length()

# Structures
class Move:
	var commands : Commands
	var state : State
	
	func _init(_commands, _state):
		commands = _commands
		state = _state

class Commands:
	var num : int
	var action : int
	var rot : Vector2
	var delta : float
	
	func _init(_num, _action, _rot, _delta):
		num = _num
		action = _action
		rot = _rot
		delta = _delta
	
	func to_array() -> Array:
		return [num, action, rot, delta]
	
	static func to_instance(array : Array) -> Commands:
		return Commands.new(array[0], array[1], array[2], array[3])

class State:
	var pos : Vector3
	var rot_y : float
	var head_rot_x : float
	var vel : Vector3
	var char_state : int
	var action : int
	var health : int
	var score : int
	var timestamp : int
	
	func _init(_pos, _rot_y, _head_rot_x, _vel, _char_state, _action, _health, _score, _timestamp):
		pos = _pos
		rot_y = _rot_y
		head_rot_x = _head_rot_x
		vel = _vel
		char_state = _char_state
		action = _action
		health = _health
		score = _score
		timestamp = _timestamp
	
	func to_array() -> Array:
		return [pos, rot_y, head_rot_x, vel, char_state, action, health, score, timestamp]
	
	static func to_instance(array : Array) -> State:
		return State.new(array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8])
