extends RigidBody
class_name Prop

var start_pos : Vector3

var lvl : float
var plvl : float
var avl : float

var scrape_contact : bool = false
var scrape_player : AudioStreamPlayer3D
var scrape_sound
onready var hit_sounds : Array = [
	preload("res://sounds/boomstick/shell_01.wav")
]

var shooter : Character

func _ready():
	start_pos = global_transform.origin
	
	# Scrape sound
	scrape_player = AudioStreamPlayer3D.new()
	add_child(scrape_player)
	scrape_player.bus = "Sounds"
	scrape_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	scrape_player.global_transform.origin = global_transform.origin
	scrape_player.stream = scrape_sound
	scrape_player.play()

func _integrate_forces(physics_state : PhysicsDirectBodyState):
	lvl = physics_state.linear_velocity.length()
	avl = physics_state.angular_velocity.length()
	
	# Scrape sound
	if scrape_sound != null:
		if lvl < 0.2:
			scrape_contact = false
			lvl = 0.0
		scrape_player.unit_db = lerp(scrape_player.unit_db, float(!scrape_contact) * -80.0, physics_state.step * 5)
		scrape_player.unit_size = clamp(lvl, 0.0, 1.0)
	
	# Hit sound
	if physics_state.get_contact_count() >= 1:
		scrape_contact = true
		for i in physics_state.get_contact_count():
			var collider = physics_state.get_contact_collider_object(i)
			if collider is StaticBody or collider is RigidBody:
				if plvl - lvl >= 0.25 and hit_sounds.size() > 0:
					play_hit_sound()
	else:
		scrape_contact = false
	
	# Previous velocity length
	plvl = lvl

# Emit sound when object has hit something.
func play_hit_sound():
	var new_hit_player = AudioPlayerLifetime.new()
	Game.garbage.add_child(new_hit_player)
	new_hit_player.lifetime = 5.0
	new_hit_player.global_transform.origin = global_transform.origin
	new_hit_player.bus = "Sounds"
	new_hit_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	new_hit_player.stream = hit_sounds[randi() % hit_sounds.size()]
	new_hit_player.pitch_scale = rand_range(0.9, 1.1)
	new_hit_player.play()

# Type checking
func is_prop():
	return true
