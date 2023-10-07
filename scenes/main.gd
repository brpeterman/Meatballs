extends Node

@export var collision_energy_threshold = 100.0
@export var collision_momentum_tolerance = 0.2
@export var collision_energy_modulation = 0.1
@export var collision_dedupe_time_ms = 500
@export var sawblade_impulse = 50.0

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
		node.connect("saw_collided", _handle_saw_collided)
		node.connect("died", _handle_meatball_died)

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

func is_trading_collision(a: Meatball, b: Meatball):
	var velocity1 = a.linear_velocity
	var velocity2 = b.linear_velocity
	var energy1 = kinetic_energy(a)
	var energy2 = kinetic_energy(b)
	var angle = min(velocity1.angle_to(velocity2), velocity2.angle_to(velocity1))
	# TODO: Ignore angle if one is much faster than the other
	return energy1 + energy2 > collision_energy_threshold\
		and angle > PI/2.0

func compare_energy(a: Meatball, b: Meatball):
	return kinetic_energy(a) < kinetic_energy(b)

func kinetic_energy(body: Meatball):
	return body.mass * pow(body.linear_velocity.length(), 2) / 2.0

func smash_meatballs(originator: Meatball, other: Meatball, normal: Vector3):
	# Find the fastest, increase its mass. Find the slowest, decrease its mass
	if is_trading_collision(originator, other):
		var ranked = [originator, other] as Array[Meatball]
		ranked.sort_custom(compare_energy)
		ranked[0].shrink()
		ranked[1].grow()
	
	# Rebound off each other
	originator.apply_central_impulse(normal * kinetic_energy(originator) * collision_energy_modulation)
	other.apply_central_impulse(-normal * kinetic_energy(other) * collision_energy_modulation)

func _handle_saw_collided(body: Meatball, normal: Vector3):
	body.shrink()
	body.apply_central_impulse(normal.normalized() * sawblade_impulse)

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
