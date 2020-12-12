extends Weapon
class_name Boomstick

const IMPULSE : float = 4.0
const KNOCKBACK : float = 10.0
const PELLETS : int = 16
const SPREAD : float = 50.0
const RAY_LENGTH : float = 500.0
var can_fire : bool = true
var firing : bool = false
var run_blend : float = 0.0
var primary_translation : Vector3 = Vector3(0.1, -0.12, -0.11)
var secondary_translation : Vector3 = Vector3(0.025, -0.10, -0.08)

func _ready():
	anim_tree = $animation_tree
	anim_tree.active = true
	anim_state_machine = anim_tree.get("parameters/state_machine/playback")
	var _cd_connected : bool = $cooldown.connect("timeout", self, "_on_cooldown_timeout")
	translation = primary_translation

func _process(delta):
	#$particles/light.light_energy = lerp($particles/light.light_energy, float(firing) * 10.0, delta * 25.0)
	firing = false
	
	# Animations
	if shooter != null:
		var run_blend_target = shooter.dir.dot(shooter.vel) * float(shooter.is_on_floor())
		run_blend = lerp(run_blend, run_blend_target, delta * 20)
		anim_tree.set("parameters/state_machine/idle_run/blend_position", run_blend)
		anim_state_machine.travel("idle_run")
		
		if shooter.get_action(6):
			translation = translation.linear_interpolate(secondary_translation, delta * 20)
		else:
			translation = translation.linear_interpolate(primary_translation, delta * 20)
	

func primary():
	if can_fire:
		firing = true
		can_fire = false
		$cooldown.start()
		$sounds/fire.play()
		$sounds/fire.pitch_scale = rand_range(0.9, 1.1)
		$sounds/fire_distant.play()
		$sounds/fire_distant.pitch_scale = rand_range(0.9, 1.1)
		$particles/flames.restart()
		$particles/smoke.restart()
		anim_tree.set("parameters/fire/active", true)
		# Rays
		var state = get_world().direct_space_state
		var ray_from = shooter.head.global_transform.origin
		for i in PELLETS:
			var ray_to = ray_from + (shooter.head.global_transform.basis.z * -RAY_LENGTH) + random_spread(SPREAD)
			var ray_result = state.intersect_ray(ray_from, ray_to, [self, shooter] + hitboxes, 7, true, false)
			if ray_result:
				var collider = ray_result.collider
				var impulse = (collider.global_transform.origin - global_transform.origin).normalized() * IMPULSE
				if collider is StaticBody:
					if collider is Hitbox:
						collider.active = true
						var character : Character = collider.get_owner().get_parent()
						character.impulse = impulse
						character.vel = character.vel + impulse
						character.hit(collider.damage, shooter)
						Game.create_impact(collider, ray_result.position, ray_result.normal, collider.physics_material_override)
					else:
						Game.create_impact(Game.garbage, ray_result.position, ray_result.normal, collider.physics_material_override)
				if collider is PhysicalBone:
					collider.apply_central_impulse(impulse)
					# TODO: Find a way to determine physical bone's material.
					var mat_override = PhysicsMaterial.new()
					if collider.get_parent().has_method("is_gobot_ragdoll"):
						mat_override.resource_name = "Metal"
					else:
						mat_override.resource_name = "Alien"
					Game.create_impact(collider, ray_result.position, ray_result.normal, mat_override)
				if collider is Prop:
					collider.apply_central_impulse(impulse)
					Game.create_impact(collider, ray_result.position, ray_result.normal, collider.physics_material_override)
		# Cam shake
		shooter.get_node("head/container/camera").shake(1.0, 0.15)
		# Knockback
		if !shooter.is_on_floor():
			shooter.vel = shooter.vel + shooter.head.global_transform.basis.z * KNOCKBACK

func _on_cooldown_timeout():
	can_fire = true
