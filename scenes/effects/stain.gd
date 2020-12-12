extends Spatial

var color : Color
var lifetime : float = 10.0

func _ready():
	$mesh.get_surface_material(0).albedo_color = color
	rotation.z = rand_range(-TAU, TAU)
	var rand_scale = rand_range(0.15, 1.5)
	scale = Vector3(rand_scale, rand_scale, rand_scale)

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
