extends Sprite2D

@export var rot: float = 2.0

func _physics_process(delta: float) -> void:
	global_rotation += rot*delta
