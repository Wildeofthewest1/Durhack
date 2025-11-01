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
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			print("Player: E pressed!")
			var manager: InteractionManager = $"InteractionManager"
			if manager:
				print("Player: Found manager")
				var closest: Interactable = manager.get_closest_interactable()
				if closest:
					print("Player: Found interactable, triggering!")
					manager.trigger_interaction(closest)
				else:
					print("Player: No closest interactable")
