extends Spatial
class_name Projectile

var shooter : KinematicBody
var hitboxes : Array
var lifetime : float = 3.0
var speed : float = 30.0

func _ready():
	for hitbox in hitboxes:
		$ray_cast.add_exception(hitbox)

func _physics_process(delta):
	translation += -global_transform.basis.z * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		free()
	if is_instance_valid(self):
		if $ray_cast.is_colliding():
			var collider = $ray_cast.get_collider()
			var pos = $ray_cast.get_collision_point()
			var norm = $ray_cast.get_collision_normal()
			var impact = Game.burn_scn.instance()
			collider.add_child(impact)
			impact.global_transform.origin = pos + norm * 0.01
			impact.look_at(pos - norm, Vector3(1, 1, 0))
			if collider is Hitbox:
				collider.get_owner().get_parent().hit(collider.damage, shooter)
			free()
