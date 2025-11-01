extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT   # <- ensures the property exists

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		queue_free()
