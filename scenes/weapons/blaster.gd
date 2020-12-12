extends Weapon
class_name Blaster

const RAY_LENGTH : float = 1000.0
var can_fire : bool = true

var projectile_scn = preload("res://scenes/weapons/blaster_projectile.tscn")

func _ready():
	var _cd_connected : bool = $cooldown.connect("timeout", self, "_on_cooldown_timeout")

func primary():
	if can_fire:
		can_fire = false
		$cooldown.start()
		$sounds/fire.play()
		$sounds/fire.pitch_scale = rand_range(0.9, 1.1)
		
		var projectile = projectile_scn.instance()
		projectile.hitboxes = hitboxes
		projectile.shooter = shooter
		Game.garbage.add_child(projectile)
		projectile.global_transform = global_transform
		
		# Raycast
		var state = get_world().direct_space_state
		var ray_from = shooter.head.global_transform.origin
		var ray_to = ray_from + (shooter.head.global_transform.basis.z * -RAY_LENGTH)
		var ray_result = state.intersect_ray(ray_from, ray_to, [self, shooter] + hitboxes, 7, true, false)
		if ray_result:
			if ray_result.collider is PhysicsBody:
				projectile.look_at(ray_result.position, Vector3.UP)

func _on_cooldown_timeout():
	can_fire = true
