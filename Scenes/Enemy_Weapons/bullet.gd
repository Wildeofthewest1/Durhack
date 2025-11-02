extends Area2D

@export var initial_speed: float = 300
@export var speed: float = initial_speed
@export var lifetime: float = 3
@export var deceleration: float = 0.0
@export var damage: int = 20   # 💥 how much damage to deal

@onready var sprite = $Sprite2D

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	speed = initial_speed
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	if deceleration > 0.0:
		speed = max(speed - deceleration * delta, 0.0)
		
	if initial_speed > 0.0 and sprite:
		var alpha = clamp(speed / initial_speed, 0, 1.0)
		sprite.modulate.a = alpha


func _on_body_entered(body: Node) -> void:
	# ✅ damage enemies
	print("damaged enemy")
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

		queue_free()
		return

	# ✅ optionally remove if it hits walls, player, etc.
	if body.is_in_group("player") or body.is_in_group("environment"):
		queue_free()
