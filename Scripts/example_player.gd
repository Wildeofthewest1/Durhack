extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(delta: float) -> void:
	# Get input direction
	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalize diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()
	
	# Apply movement
	velocity = direction * speed
	move_and_slide()
