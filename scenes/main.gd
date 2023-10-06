extends Node

@export var collision_momentum_threshold = 3.0
@export var collision_momentum_tolerance = 0.2
@export var collision_velocity_boost = 2.0
@export var collision_dedupe_time_ms = 1000
@export var slowdown_time_ms = 1000

var collision_cache = {}
var player_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

func new_game():
	$UserInterface/DimRect.hide()
	var meatballs = get_tree().get_nodes_in_group("meatballs")
	player_count = meatballs.size()
	set_player_count(player_count)
	for node in meatballs:
		node.connect("meatball_collided", _handle_meatball_collided)
		node.connect("died", _handle_meatball_died)

func compare_momentum(a: Meatball, b: Meatball):
	return a.linear_velocity.length() * a.mass < b.linear_velocity.length() * b.mass

func _handle_meatball_collided(originator: Meatball, other: Meatball, normal: Vector3):
	# Ignore collisions that were already handled
	var key = collision_key(originator, other)
	var expiry = collision_cache.get(key, 0.0) as float
	var now = Time.get_ticks_msec()
	if expiry < now:
		smash_meatballs(originator, other, normal)
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
	if is_trading_collision(originator.linear_velocity, originator.mass, other.linear_velocity, other.mass):
		var ranked = [originator, other] as Array[Meatball]
		ranked.sort_custom(compare_momentum)
		ranked[0].shrink()
		ranked[1].grow()
	
	# Rebound off each other
	var total_speed = originator.linear_velocity.length() + other.linear_velocity.length()
	originator.apply_central_force(-normal * total_speed)
	other.apply_central_force(normal * total_speed)

func _handle_meatball_died(source: Meatball):
	var parent = source.get_parent_node_3d()
	if parent is Opponent:
		print("Opponent meatball died")
		parent.queue_free()
		player_count -= 1
		set_player_count(player_count)
		if player_count == 1:
			# Winner!
			show_victory()
	else:
		parent.queue_free()
		player_count -= 1
		set_player_count(player_count)
		show_defeat()

func set_player_count(count: int):
	$UserInterface/PlayerCountLabel.text = "Active meatballs: %s" % str(count)

func show_victory():
	$UserInterface/DimRect/GameOverMessage.text = "You have consumed all the meat!"
	$UserInterface/DimRect.show()
	reset_game()

func show_defeat():
	$UserInterface/DimRect/GameOverMessage.text = "You have been consumed"
	$UserInterface/DimRect.show()
	reset_game()

func reset_game():
	$ResetTimer.start()

func _on_reset_timer_timeout():
	get_tree().reload_current_scene()
