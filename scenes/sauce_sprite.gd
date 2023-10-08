extends Sprite2D
class_name SauceDisplacer

@export var resolution := Vector2.ZERO
@export var size := Vector2.ZERO
@export var target: Meatball

func _process(delta):
	if target == null: return
	if not target.is_on_floor(): return
	var px = (target.global_position.x + (size.x * 0.5)) / size.x
	var py = (target.global_position.z + (size.y * 0.5)) / size.y
	scale.x = target.mass * 0.5
	scale.y = target.mass * 0.5
	position.x = px * resolution.x - 10.0
	position.y = py * resolution.y - 10.0
	pass
