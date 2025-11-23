extends Sprite2D

var init_scale := 0.0
@export var upper_scale:float =1.0
@export var lower_scale:float =0.0

func _ready() -> void:
	init_scale = modulate.a
	
func _physics_process(delta: float) -> void:
	modulate.a = lerp(modulate.a,randf_range(upper_scale,lower_scale),delta*20)
	
