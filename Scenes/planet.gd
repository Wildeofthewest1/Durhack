extends CharacterBody2D

@export var mass = 10.00
@export var radius = 1.00
@export var initial_speed = 0
@export var initial_direction = Vector2.ZERO 




@export var autoorbit = false
@export var parent_star: CharacterBody2D #Add the host star of the system
@export var parent_planet: CharacterBody2D #Add planetary moons 

var gravity_scale = 100
var g_limit = mass*5

func _ready():
	#set planet size
	scale = radius * scale
	
	
	if not autoorbit:
		velocity = initial_speed * initial_direction
	if autoorbit:
		if is_in_group("Moon"):
			var planet_speed = parent_planet.velocity
			var speed = (60 * parent_planet.mass * gravity_scale/(global_position - parent_planet.global_position).length())**(0.5)
			var direction = (global_position - parent_planet.global_position).normalized()
			velocity = speed * direction.orthogonal() + planet_speed
			#times 60 because of the physics framerate
		if not is_in_group("Star") and not is_in_group("Moon"):
			var speed = (60 * parent_star.mass * gravity_scale/(global_position - parent_star.global_position).length())**(0.5)
			var direction = (global_position - parent_star.global_position).normalized()
			velocity = speed * direction.orthogonal()


func _process(_delta: float) -> void:
	#print(name, " ", (position - orbital_parent.position).length())
	if not is_in_group("Star"):
		#print((position - parent_star.position).length())
		#print(velocity.length())
		pass
	pass
func _physics_process(delta: float) -> void:
	move_and_slide()
	force_g()

@onready var planets =  get_tree().get_nodes_in_group("Planets")
func force_g():
	for i in range(len(planets)):
		if i != get_index():
			var direction_g = global_position - planets[i].global_position
			if direction_g.length() > 3:
				velocity -= (direction_g.normalized()
								* planets[i].mass * gravity_scale/direction_g.length()**2)
