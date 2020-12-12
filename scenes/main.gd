extends Node

# Port must be the same as the server's.
const PORT : int = 27015
const MAX_PLAYERS : int = 5

# Controller types
enum { PLAYER, BOT, PUPPET, ALIEN }

var my_id : int = -1

var server_num_bots : int = 2
var server_num_aliens : int = 6
var server_bot_states : Dictionary = {}
var server_can_update : bool = true
var server_char_state : Game.State
var server_char_states_collection : Dictionary = {}

var last_world_state_timestamp : int = 0
var world_state_buffer : Array = []

func _ready():
	# Don't auto-quit on mobile
	get_tree().set_auto_accept_quit(false)
	# Connect button events
	var _host_pressed = $ui/menu/v_box/host.connect("pressed", self, "_on_host_pressed")
	var _connect_pressed = $ui/menu/v_box/connect.connect("pressed", self, "_on_connect_pressed")
	# Server update rate timer
	var _rate_connected = $rate.connect("timeout", self, "_on_rate_timeout")
	# Set spawn and intereset points for players in a global game script
	Game.spawn_points = $map/spawns.get_children()
	Game.interest_points = $map/points.get_children()
	# Randomize stuff
	randomize()

func _physics_process(_delta):
	# Server process
	if is_instance_valid(get_tree().network_peer) and get_tree().is_network_server() and server_can_update:
		server_can_update = false
		$rate.start(1.0/20.0)
		# Send world snapshot
		send_world_state()
	# Client process
	if is_instance_valid(get_tree().network_peer) and !get_tree().is_network_server():
		process_world_state()

# Server
func setup_server():
	# Setting up the network API
	var enet = NetworkedMultiplayerENet.new()
	enet.create_server(PORT, MAX_PLAYERS)
	get_tree().set_network_peer(enet)
	# Connect network events
	var _client_connected = get_tree().connect("network_peer_connected", self, "_on_peer_connected_server")
	var _client_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	# Create bots
	create_bots(server_num_bots)
	create_aliens(server_num_aliens)

# Client
func setup_client():
		# Connect network events
	var _peer_connected = get_tree().connect("network_peer_connected", self, "_on_peer_connected_client")
	var _peer_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	var _connected_to_server = get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	var _connection_failed = get_tree().connect("connection_failed", self, "_on_connection_failed")
	var _server_disconnected = get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	# Setup network instance
	var enet = NetworkedMultiplayerENet.new()
	var _client_created = enet.create_client($ui/menu/v_box/ip.text, PORT)
	get_tree().set_network_peer(enet)

func _on_host_pressed():
	setup_server()
	create_character(str(get_tree().get_network_unique_id()), PLAYER)
	set_menu_visible(false)

func _on_connect_pressed():
	get_tree().set_network_peer(null)
	Game.display_message("Connecting...")
	set_buttons_enabled(false)
	setup_client()

func _on_connection_failed():
	Game.display_message("Connection failed!")
	set_buttons_enabled(true)

# If we are successfully connected to server
func _on_connected_to_server():
	my_id = get_tree().get_network_unique_id()
	Game.display_message("Connected! Your id is " + str(my_id))
	create_character(str(my_id), PLAYER)
	create_bots_client(server_num_bots)
	create_aliens_client(server_num_aliens)
	set_menu_visible(false)

# If server disconnects
func _on_server_disconnected():
	Game.display_message("Server disconnected.")
	get_tree().set_network_peer(null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Reload the scene for now
	var _scene_reloaded = get_tree().reload_current_scene()

# If someone connects on client
func _on_peer_connected_client(id):
	Game.display_message("Client" + str(id) + " connected.")
	create_character(str(id), PUPPET)

# If someone connect on server
func _on_peer_connected_server(id):
	Game.display_message("Client" + str(id) + " connected.")
	create_character(str(id), PUPPET)

# Common peer disconnected function
func _on_peer_disconnected(id):
	Game.display_message("Client" + str(id) + " disconnected.")
	var characters_children = $characters.get_children()
	for child in characters_children:
		if int(child.name) == id:
			$characters.remove_child(child)
			child.queue_free()
	# Remove from character state collection
	var _erased = server_char_states_collection.erase(id)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit()

func create_bots(count : int):
	for i in count:
		create_character("Bot" + str(i), BOT)

func create_bots_client(count : int):
	for i in count:
		create_character("Bot" + str(i), PUPPET)

func create_aliens(count : int):
	for i in count:
		create_alien("Alien" + str(i), BOT)

func create_aliens_client(count : int):
	for i in count:
		create_alien("Alien" + str(i), PUPPET)

func create_character(char_name : String, type : int):
	var character = Game.char_scn.instance()
	var char_mesh = Game.gobot_scn.instance()
	char_mesh.set_character(character)
	character.set_name(char_name)
	$characters.add_child(character)
	character.add_child(char_mesh)
	character.translation = Game.get_random_spawn()
	match type:
		PLAYER:
			var controller = Game.player_scn.instance()
			controller.set_name("controller")
			character.add_child(controller)
			character.set_controller(controller)
			controller.set_character(character)
			character.get_node("head/container/camera").current = true
		BOT:
			var controller = Game.bot_scn.instance()
			controller.set_name("controller")
			character.add_child(controller)
			character.set_controller(controller)
			controller.set_character(character)
		PUPPET:
			var controller = Game.puppet_scn.instance()
			controller.set_name("controller")
			character.add_child(controller)
			character.set_controller(controller)
			controller.set_character(character)

func create_alien(alien_name : String, type : int):
	var character = Game.char_scn.instance()
	var char_mesh = Game.alien_scn.instance()
	char_mesh.set_character(character)
	character.set_name(alien_name)
	$characters.add_child(character)
	character.add_child(char_mesh)
	character.translation = Game.get_random_spawn()
	match type:
		BOT:
			var controller = Game.bot_scn.instance()
			controller.set_name("controller")
			character.add_child(controller)
			character.set_controller(controller)
			controller.set_character(character)
		PUPPET:
			var controller = Game.puppet_scn.instance()
			controller.set_name("controller")
			character.add_child(controller)
			character.set_controller(controller)
			controller.set_character(character)

func set_menu_visible(value : bool):
	$ui/menu.visible = value

func set_buttons_enabled(value : bool):
	$ui/menu/v_box/connect.disabled = !value
	$ui/menu/v_box/host.disabled = !value
	$ui/menu/v_box/ip.editable = value

func _on_rate_timeout():
	server_can_update = true

func send_character_state(character_state : Game.State):
	if !get_tree().is_network_server():
		rpc_unreliable_id(1, "process_character_state", character_state.to_array())
	else:
		server_char_state = character_state

remote func process_character_state(char_state_array : Array):
	var new_character_state : Game.State = Game.State.to_instance(char_state_array)
	var char_id = get_tree().get_rpc_sender_id()
	if server_char_states_collection.has(char_id):
		# Check if new character state is fresh
		if new_character_state.timestamp > server_char_states_collection[char_id].timestamp:
			server_char_states_collection[char_id] = new_character_state
			if $characters.has_node(str(char_id)) and char_id != 1:
				var character = $characters.get_node(str(char_id))
				character.controller.apply_state(new_character_state)
	else:
		server_char_states_collection[char_id] = new_character_state
		
func send_world_state():
	if !server_char_states_collection.empty():
		var char_states : Dictionary = {}
		for char_id in server_char_states_collection:
			var char_arr = server_char_states_collection[char_id].to_array()
			char_states[char_id] = char_arr
		# Append server state
		char_states[1] = server_char_state.to_array()
		# Append bot states
		for bot_name in server_bot_states.keys():
			char_states[bot_name] = server_bot_states[bot_name].to_array()
		# Send the world state
		var world_state : Array = []
		world_state.append(OS.get_system_time_msecs())
		world_state.append(char_states)
		rpc_unreliable_id(0, "update_world_state", world_state)

puppet func update_world_state(new_world_state : Array):
	if new_world_state[0] > last_world_state_timestamp and !get_tree().is_network_server():
		last_world_state_timestamp = new_world_state[0]
		world_state_buffer.append(new_world_state)

func process_world_state():
	var render_time = OS.get_system_time_msecs() - 100
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[1][0]:
			world_state_buffer.remove(0)
		var interp_ratio = float(render_time - world_state_buffer[0][0]) / float(world_state_buffer[1][0] - world_state_buffer[0][0])
		var old_world_state = world_state_buffer[0]
		var new_world_state = world_state_buffer[1]
		for char_id in new_world_state[1].keys():
			if $characters.has_node(str(char_id)) and str(char_id) != str(get_tree().get_network_unique_id()):
				var character = $characters.get_node(str(char_id))
				var old_state = Game.State.to_instance(old_world_state[1][char_id])
				var new_state = Game.State.to_instance(new_world_state[1][char_id])
				if new_state != null:
					character.controller.interp_state(old_state, new_state, interp_ratio)

func update_bot_state(bot_name : String, new_state : Game.State):
	server_bot_states[bot_name] = new_state
