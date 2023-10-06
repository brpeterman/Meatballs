extends Node3D
class_name Opponent

@export var mass = 2.0
@export var jump_power = 250.0
@export var base_speed = 10.0
@export var retarget_time = 5.0
@export var retarget_jitter = 1.0
@export var max_jump_wait = 10.0

var pawn: Meatball
var target: Meatball

# Called when the node enters the scene tree for the first time.
func _ready():
	pawn = $Meatball as Meatball
	pawn.mass = mass
	pawn.jump_power = jump_power
	pawn.base_speed = base_speed
	$RetargetTimer.wait_time = retarget_time + randf_range(-retarget_jitter/2, retarget_jitter/2)
	$JumpTimer.wait_time = randf_range(0, max_jump_wait)
	choose_target()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	if target == null:
		return
	
	var direction = pawn.global_position.direction_to(target.global_position)
	# Jitter a bit for some randomness
	direction = Vector3(direction.x + randf_range(-0.1, 0.1), 0.0, direction.z + randf_range(-0.1, 0.1))
	pawn.set_direction(direction.normalized())

func choose_target():
	var meatballs = get_tree().get_nodes_in_group("meatballs") as Array[Meatball]
	var filter_self = func (item):
		return item != pawn
	var filtered_meatballs = meatballs.filter(filter_self)
	
	if filtered_meatballs.size() > 0:
		target = filtered_meatballs[randi_range(0, filtered_meatballs.size() - 1)]

func _on_retarget_timer_timeout():
	choose_target()

func _on_jump_timer_timeout():
	$JumpTimer.wait_time = randf_range(0, max_jump_wait)
	pawn.jump()
