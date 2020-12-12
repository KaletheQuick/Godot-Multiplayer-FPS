extends Node
class_name Controller

var character : KinematicBody setget set_character
signal character_changed

func set_character(new_character : KinematicBody):
	if character != new_character:
		character = new_character
		emit_signal("character_changed")

# Networking
func send_state():
	pass

# From client to server without interpolation
func apply_state(new_state):
	character.translation = new_state.pos
	character.rotation.y = new_state.rot_y
	character.head.rotation.x = new_state.head_rot_x
	character.vel = new_state.vel
	if character.state != new_state.char_state and new_state.char_state != character.DEAD:
		character.set_state(new_state.char_state)
	character.action = new_state.action
	#character.set_health(new_state.health)
	#character.set_score(new_state.score)
	# Shooting
	if character.get_action(5):
		character.get_node("head/holder/boomstick").primary()

# From server to client with interpolation
func interp_state(old_state, new_state, interp_ratio):
	character.translation = lerp(old_state.pos, new_state.pos, interp_ratio)
	character.rotation.y = lerp_angle(old_state.rot_y, new_state.rot_y, interp_ratio)
	character.head.rotation.x = lerp(old_state.head_rot_x, new_state.head_rot_x, interp_ratio)
	character.vel = lerp(old_state.vel, new_state.vel, interp_ratio)
	if character.state != new_state.char_state:
		character.set_state(new_state.char_state)
	character.action = new_state.action
	character.set_health(new_state.health)
	character.set_score(new_state.score)
	# Shooting
	if character.get_action(5):
		character.get_node("head/holder/boomstick").primary()
