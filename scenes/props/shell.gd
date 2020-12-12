extends Prop
class_name Shell

var lifetime = 5.0

func _ready():
	hit_sounds = [
		preload("res://sounds/boomstick/shell_01.wav"),
		preload("res://sounds/boomstick/shell_02.wav"),
		preload("res://sounds/boomstick/shell_03.wav"),
		preload("res://sounds/boomstick/shell_04.wav"),
		preload("res://sounds/boomstick/shell_05.wav"),
		preload("res://sounds/boomstick/shell_06.wav")
	]

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		free()
