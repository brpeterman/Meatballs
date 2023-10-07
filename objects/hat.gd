extends Marker3D

@export var target: Meatball
@export var collider: CollisionShape3D

@onready var offset = position.y
@onready var height = offset

func _ready():
	top_level = true
	target.meatball_collided.connect(_on_meatball_body_meatball_collided)
	
func _process(delta):
	if not target: return
	global_position = target.global_position
	global_position.y += height

func _on_meatball_body_meatball_collided(source, body, normal):
	_resize()

func _resize():
	if not target or not collider: return
	var h = 0.5 * pow(target.SIZE_DELTA, target.mass)
	var tween = create_tween()
	tween.tween_property(self, 'height', h, 0.1) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
