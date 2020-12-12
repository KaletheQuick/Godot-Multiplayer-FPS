extends KinematicBody
class_name Character

export var blood_color : Color

# Movement constants
var GRAVITY : float = -24.8
var MAX_SPEED : float = 10.0
var JUMP_FORCE : float = 8.0
var ACCEL : float = 8.0
var DECEL : float = 6.0
var AIR_ACCEL : float = 3.0
var AIR_DECEL : float = 3.0
var MAX_FLY_SPEED : float = 12.0
var FLY_ACCEL : float = 5.0
var MAX_WATER_SPEED : float = 6.0
var WATER_ACCEL : float = 2.0
var MAX_CLIMB_SPEED : float = 6.0
var CLIMB_ACCEL : float = 10.0

# Movement variables
var vel : Vector3
var pvel : Vector3
var dir : Vector3
var accel : float
var speed : float

# Last received impulse. Used for ragdolls.
var impulse : Vector3
var health : float = 100.0
signal health_changed

enum { AIR, GROUND, WATER, CLIMB, DEAD, FLY }
var state : int = AIR setget set_state
signal state_changed

# Rotations: character yaw and camera pitch
onready var head = get_node("head")
var rots : Vector2 = Vector2.ZERO

# Action bits
# Forward, backward, left, right, jump, primary, secondary, next weapon
var action : int = 0b00000000

var controller : Controller setget set_controller
signal controller_changed

# Scoring
var last_damage_dealer : KinematicBody
var score : int = 0 setget set_score
signal score_changed

func _ready():
	var _state_changed_connected = connect("state_changed", self, "_on_state_changed")
	var _respawn_connected = $respawn.connect("timeout", self, "_on_respawn_timeout")

func _process(_delta):
	if translation.distance_squared_to(Vector3.ZERO) >= 40000:
		set_state(DEAD)

func process_actions():
	dir = (int(get_action(0)) - int(get_action(1))) * head.global_transform.basis.z * -1
	dir += (int(get_action(3)) - int(get_action(2))) * head.global_transform.basis.x
	# Normalize direction so the diagonal movement doesn't exceed 1
	dir = dir.normalized()
	
	# Jumping
	if get_action(4) and state == GROUND:
		vel.y = JUMP_FORCE
	
	speed = MAX_SPEED
	
	# Shooting
	if get_action(5):
		if $mesh.has_method("is_gobot"):
			$head/holder/boomstick.primary()
		else:
			$head/holder/blaster.primary()

func process_movement(delta):
	match state:
		AIR:
			dir.y = 0
			dir = dir.normalized()
			var hvel = vel
			hvel.y = 0
			var target = dir
			target *= speed
			if dir.dot(hvel) > 0:
				accel = ACCEL
			else:
				accel = DECEL
			hvel = hvel.linear_interpolate(target, accel * delta)
			vel.x = hvel.x
			vel.z = hvel.z
			vel.y += delta * GRAVITY
			vel = move_and_slide(vel, Vector3.UP, true, 4, 0.78, false)
			
			if is_on_floor():
				set_state(GROUND)
		GROUND:
			dir.y = 0
			dir = dir.normalized()
			var hvel = vel
			hvel.y = 0
			var target = dir
			target *= speed
			if dir.dot(hvel) > 0:
				accel = ACCEL
			else:
				accel = DECEL
			hvel = hvel.linear_interpolate(target, accel * delta)
			vel.x = hvel.x
			vel.z = hvel.z
			# Glitches without applying gravity
			vel.y += delta * GRAVITY
			vel.y = move_and_slide(vel, Vector3.UP, true, 4, 0.78, false).y
			
			if !is_on_floor():
				set_state(AIR)
		WATER:
			dir = dir.normalized()
			var target = dir
			target *= MAX_WATER_SPEED
			vel = vel.linear_interpolate(target, WATER_ACCEL * delta)
			vel = move_and_slide(vel)
		CLIMB:
			dir = dir.normalized()
			var target = dir
			target *= MAX_CLIMB_SPEED
			vel = vel.linear_interpolate(target, CLIMB_ACCEL * delta)
			vel = move_and_slide(vel)
		DEAD:
			pass
		FLY:
			# Flying
			dir = dir.normalized()
			var target = dir
			target *= MAX_FLY_SPEED
			vel = vel.linear_interpolate(target, FLY_ACCEL * delta)
			vel = move_and_slide(vel)

func process_rotations(_delta):
	head.rotate_x(rots.x)
	var head_rotation_x = clamp(head.rotation_degrees.x, -85.0, 85.0)
	head.rotation_degrees.x = head_rotation_x
	rotate_y(rots.y)

# Actions/commands functions
func set_action(index : int, value : bool):
	if value == true:
		action = Game.enable_bit(action, index)
	else:
		action = Game.disable_bit(action, index)

func get_action(index):
	return Game.is_bit_enabled(action, index)

# State functions
func set_state(new_state : int):
	if state != new_state:
		var old_state = state
		state = new_state
		emit_signal("state_changed", new_state, old_state)

func _on_state_changed(new_state, old_state):
	match new_state:
		DEAD:
			if last_damage_dealer != null and (Game.is_server() or last_damage_dealer.controller.has_method("is_player")):
				last_damage_dealer.set_score(last_damage_dealer.score + 1)
			$shape.disabled = true
			visible = false
			$mesh.spawn_ragdoll(impulse)
			if has_node("mesh/particles/damage"):
				$mesh/particles/damage.emitting = false
				$mesh/sounds/damage.unit_db = -80
			$respawn.start()
	match old_state:
		DEAD:
			$shape.disabled = false
			vel = Vector3.ZERO
			visible = true
			translation = Game.get_random_spawn()

# If character has been hit apply damage and knockback
func hit(damage, dealer):
	last_damage_dealer = dealer
	$head/container/camera.shake(1.0, 0.15)
	if controller.has_method("is_player") or Game.is_server():
		set_health(health - damage)
	if controller.has_method("is_bot"):
		controller.target = dealer
	if controller.has_method("is_player"):
		controller.aberration = 1.0
	if has_node("mesh/particles/damage"):
		$mesh/particles/damage.emitting = true
		$mesh/sounds/damage.unit_db = 0.0
		yield(get_tree().create_timer(1.0), "timeout")
		$mesh/particles/damage.emitting = false
		$mesh/sounds/damage.unit_db = -80.0

func _on_respawn_timeout():
	set_health(100.0)
	set_state(AIR)

# Health setter function
func set_health(value):
	if health != value:
		health = value
		emit_signal("health_changed", health)
	if health <= 0 and state != DEAD:
		set_state(DEAD)

func set_score(value):
	if score != value:
		score = value
		emit_signal("score_changed", score)

func set_controller(new_controller : Controller):
	if controller != new_controller:
		controller = new_controller
		emit_signal("controller_changed")
