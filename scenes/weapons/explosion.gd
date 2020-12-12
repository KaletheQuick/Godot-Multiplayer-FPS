extends Spatial
class_name Explosion

const DAMAGE = 100.0
const RADIUS = 4.0
const IMPULSE = 25.0

var shooter : Character
var timer : float = 0.0

func _ready():
	var _body_entered = $area.connect("body_entered", self, "_on_body_entered")
	# Smooth light transition
	$tween.interpolate_property($light, "light_energy", 15.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.0)
	$tween.start()
	# Area radius
	$area/shape.shape.radius = RADIUS
	# Particles
	var scale_factor = RADIUS * 1.0
	$smoke.scale *= scale_factor
	$smoke.emitting = true
	$flames.scale *= scale_factor
	$flames.emitting = true
	$debris.scale *= scale_factor
	$debris.emitting = true
	$sparks.scale *= scale_factor
	$sparks.emitting = true

func _process(delta):
	if timer >= delta and has_node("area"):
		$area.free()
	if timer >= 4.0:
		queue_free()
	timer += delta

func _on_body_entered(body):
	var impulse = (body.global_transform.origin - global_transform.origin).normalized() * IMPULSE
	if body.has_method("hit"):
		var proximity = (global_transform.origin - body.global_transform.origin).length()
		var effect = clamp(1 - (proximity / RADIUS), 0, 1)
		body.hit(DAMAGE * effect, shooter)
		body.impulse = impulse
		body.vel = body.vel + impulse
	if body.has_method("apply_central_impulse"):
		body.apply_central_impulse(impulse * 5.0)

func is_explosion():
	return true
