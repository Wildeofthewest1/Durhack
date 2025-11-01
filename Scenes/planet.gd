extends CharacterBody2D

@export var mass = 100.00
@export var initial_speed = 0
@export var initial_direction = Vector2.ZERO 

@export var autoorbit = false
@export var orbital_parent: CharacterBody2D
func _ready():
	if not autoorbit:
		velocity = initial_speed * initial_direction
	if autoorbit and not is_in_group("Star"):
		#times 60 because of the physics framerate
		var speed = (60 * orbital_parent.mass * 1e4/(position - orbital_parent.position).length())**(0.5)
		print(speed)
		var direction = (position - orbital_parent.position).normalized()
		velocity = speed * direction.orthogonal()


func _process(_delta: float) -> void:
	#print(name, " ", (position - orbital_parent.position).length())
	#if not is_in_group("Star"):
		##print((orbital_parent.mass 
				##* 1e4 * 30/(position - orbital_parent.position).length())**(0.5))
		#pass
	pass
func _physics_process(delta: float) -> void:
	move_and_slide()
	force_g()

@onready var planets =  get_tree().get_nodes_in_group("Planets")
func force_g():
	for i in range(len(planets)):
		if i != get_index():
			var direction_g = position - planets[i].global_position
			velocity -= (direction_g.normalized()
							* planets[i].mass * 1e4/direction_g.length()**2)
