extends Node

@export var collision_momentum_threshold = 2.0
@export var collision_momentum_tolerance = 0.2
@export var collision_velocity_boost = 2.0
@export var collision_dedupe_time_ms = 100

var collision_cache = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var meatballs = get_tree().get_nodes_in_group("meatballs")
	for node in meatballs:
		node.connect("meatball_collided", _handle_meatball_collided)
		node.connect("died", _handle_meatball_died)

func compare_momentum(a: Meatball, b: Meatball):
	return a.velocity.length() * a.mass < b.velocity.length() * b.mass

func _handle_meatball_collided(originator: Meatball, collision: KinematicCollision3D):
	# Ignore collisions that were already handled
	for collision_idx in collision.get_collision_count():
		if not collision.get_collider(collision_idx) is Meatball:
			continue
		var other = collision.get_collider(collision_idx) as Meatball
		if other == originator:
			continue
		var key = collision_key(originator, collision.get_collider(collision_idx))
		var expiry = collision_cache.get(key, 0.0) as float
		var now = Time.get_ticks_msec()
		if expiry < now:
			smash_meatballs(originator, other, collision.get_normal(collision_idx))
			# Cache the collision for a short time
			collision_cache[key] = Time.get_ticks_msec() + collision_dedupe_time_ms

func collision_key(a: Node, b: Node):
	var ids = [a.get_instance_id(), b.get_instance_id()]
	ids.sort()
	return str(ids[0]) + str(ids[1])

func is_trading_collision(velocity1: Vector3, mass1: float, velocity2: Vector3, mass2: float):
	var momentum1 = velocity1.length() * mass1
	var momentum2 = velocity2.length() * mass2
	return momentum1 + momentum2 > collision_momentum_threshold\
		and abs(momentum1 - momentum2) > collision_momentum_tolerance

func smash_meatballs(originator: Meatball, other: Meatball, normal: Vector3):
	# Find the fastest, increase its mass. Find the slowest, decrease its mass
	if is_trading_collision(originator.velocity, originator.mass, other.velocity, other.mass):
		var ranked = [originator, other] as Array[Meatball]
		ranked.sort_custom(compare_momentum)
		ranked[0].shrink()
		ranked[1].grow()
	
	# Rebound off each other
	var total_speed = originator.velocity.length() + other.velocity.length()
	var originator_speed = total_speed * originator.mass / (originator.mass + other.mass)
	var other_speed = total_speed - originator_speed
	originator.velocity = normal * originator_speed * collision_velocity_boost
	other.velocity = normal * -1 * other_speed * collision_velocity_boost

func _handle_meatball_died(source: Meatball):
	var parent = source.get_parent_node_3d()
	if parent is Opponent:
		print("Opponent meatball died")
		parent.queue_free()
	# Otherwise game over
