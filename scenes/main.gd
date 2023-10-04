extends Node

@export var collision_velocity_threshold = 2.0
@export var collision_velocity_tolerance = 0.1
@export var collision_velocity_boost = 5.0
@export var collision_dedupe_time_ms = 100

var collision_cache = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var meatballs = get_tree().get_nodes_in_group("meatballs")
	for node in meatballs:
		node.connect("meatball_collided", _handle_meatball_collided)
		node.connect("died", _handle_meatball_died)

func compare_velocity(a: Meatball, b: Meatball):
	return a.velocity.length() < b.velocity.length()

func _handle_meatball_collided(originator: Meatball, collision: KinematicCollision3D):
	# Ignore collisions that were already handled
	var key = originator.get_instance_id() ^ collision.get_collider().get_instance_id()
	
	var expiry = collision_cache.get(key, 0.0) as float
	var now = Time.get_ticks_msec()
	if expiry < now:
		for collision_idx in collision.get_collision_count():
			if not collision.get_collider(collision_idx) is Meatball:
				continue
			var other = collision.get_collider(collision_idx) as Meatball
			if other == originator:
				continue
			var total_speed = originator.velocity.length() + other.velocity.length()
			if total_speed > collision_velocity_threshold:
				# Mash them together
				if abs(originator.velocity.length() - other.velocity.length()) > collision_velocity_tolerance:
					# Find the fastest, increase its mass. Find the slowest, decrease its mass
					var ranked = [originator, other] as Array[Meatball]
					ranked.sort_custom(compare_velocity)
					ranked[0].shrink()
					ranked[1].grow()
					
					# Rebound off each other
					var normal = collision.get_normal(collision_idx) # with respect to originator
					var originator_speed = total_speed * originator.mass / (originator.mass + other.mass)
					var other_speed = total_speed - originator_speed
					originator.velocity = normal * originator_speed * collision_velocity_boost
					other.velocity = normal * -1 * other_speed * collision_velocity_boost
					
			# Cache the collision for a short time
			collision_cache[key] = Time.get_ticks_msec() + collision_dedupe_time_ms

func _handle_meatball_died(source: Meatball):
	var parent = source.get_parent_node_3d()
	if parent is Opponent:
		print("Opponent meatball died")
		parent.queue_free()
	# Otherwise game over
