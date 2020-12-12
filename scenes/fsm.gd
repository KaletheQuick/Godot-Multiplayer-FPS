extends Node
class_name StackFSM

var stack : Array
signal state_changed
signal state_entered
signal state_exited

func _physics_process(_delta):
	var current_state_function = get_current_state()
	if current_state_function != null:
		if get_parent().has_method(current_state_function):
			get_parent().call(current_state_function)

func pop_state():
	emit_signal("state_exited", get_current_state())
	stack.pop_back()
	emit_signal("state_changed")

func push_state(state):
	if get_current_state() != state:
		stack.push_back(state)
		emit_signal("state_entered", state)
		emit_signal("state_changed")

func get_current_state():
	if stack.size() > 0:
		return stack[stack.size() - 1]
	else:
		return null
