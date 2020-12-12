extends Controller
class_name Player

var MOUSE_SENSITIVITY = 1.0
var TOUCH_SENSITIVITY = 1.75
var INVERSION = -1

var water_filter : bool = false
var touch_mode : bool = false

# Touch screen
onready var right_ball = get_node("touch/track_right/track/ball")
onready var left_ball = get_node("touch/track_left/track/ball")

# Aberration effect
var aberration : float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var _character_changed_connected = connect("character_changed", self, "_on_character_changed")

func _physics_process(delta):
	if character.state != character.DEAD:
		character.process_actions()
		character.process_movement(delta)
		character.process_rotations(delta)
	# Send state to server
	send_state()
	
	process_input(delta)
	process_effects()
	
	if aberration > 0.0:
		aberration -= delta * 2.0
	$hud/filter.material.set("shader_param/amount", 0.25 + aberration * 4.0)
	$hud/hurt.modulate.a = aberration * 0.33

func process_input(_delta):
	# Reset rots
	character.rots = Vector2.ZERO
	
	# Character input
	character.set_action(0, Input.is_action_pressed("forward"))
	character.set_action(1, Input.is_action_pressed("backward"))
	character.set_action(2, Input.is_action_pressed("left"))
	character.set_action(3, Input.is_action_pressed("right"))
	character.set_action(4, Input.is_action_pressed("jump"))
	character.set_action(5, Input.is_action_pressed("primary"))
	character.set_action(6, Input.is_action_pressed("secondary"))
	character.set_action(7, Input.is_action_just_released("next_weapon"))
	
	# Capturing/freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Recapture the mouse on left click
	if Input.is_action_just_pressed("primary") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func process_effects():
	# Underwater fog
#	if water_filter:
#		$head/camera.environment.fog_depth_begin = 0
#		$head/camera.environment.fog_depth_end = 8
#		AudioServer.set_bus_effect_enabled(1, 0, true)
#		$head/camera/water.unit_db = 1
#	else:
#		$head/camera.environment.fog_depth_begin = 32
#		$head/camera.environment.fog_depth_end = 512
#		AudioServer.set_bus_effect_enabled(1, 0, false)
#		$head/camera/water.unit_db = -80
	pass

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and !touch_mode:
		character.rots = Vector2(event.relative.y * MOUSE_SENSITIVITY * INVERSION * 0.005, event.relative.x * MOUSE_SENSITIVITY * INVERSION * 0.005)

func set_water_filter(value : bool):
	water_filter = value

func _on_character_changed():
	character.get_node("mesh").set_visible_to_camera(false)
	var _health_changed_connected = character.connect("health_changed", self, "_on_health_changed")
	var _score_changed_connected = character.connect("score_changed", self, "_on_character_score_changed")

func _on_health_changed(new_health):
	$hud/health.text = "Health: " + str(floor(new_health))

func _on_character_score_changed(new_score):
	$hud/score.text = "Score: " + str(new_score)

func is_player():
	return true

# Networking
func send_state():
	var new_state = Game.State.new(character.translation, character.rotation.y, character.head.rotation.x, character.vel, character.state, character.action, character.health, character.score, OS.get_system_time_msecs())
	Game.main.send_character_state(new_state)
