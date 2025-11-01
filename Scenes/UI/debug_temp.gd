# DEBUG SCRIPT - Attach this to your Main node temporarily
extends Node2D

@onready var interaction_manager: InteractionManager = $Player/InteractionManager
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	print("=== INTERACTION SYSTEM DEBUG ===")
	print("Player node: ", player)
	print("InteractionManager node: ", interaction_manager)
	
	if interaction_manager:
		print("InteractionManager.player: ", interaction_manager.player)
		print("Detection radius: ", interaction_manager.detection_radius)
	
	# Check for interactables in scene
	var interactables: Array[Node] = get_tree().get_nodes_in_group("interactables")
	print("Interactables in scene: ", interactables.size())
	for interactable: Node in interactables:
		print("  - ", interactable.name, " at ", interactable.global_position)

func _process(_delta: float) -> void:
	if not player or not interaction_manager:
		return
	
	# Show distance to interactables
	var interactables: Array[Node] = get_tree().get_nodes_in_group("interactables")
	for node: Node in interactables:
		if node is Interactable:
			var interactable: Interactable = node as Interactable
			var distance: float = player.global_position.distance_to(interactable.global_position)
			
			# Only print when nearby
			if distance < 250:
				print("Distance to ", interactable.interaction_name, ": ", distance)
				print("  Can interact: ", interactable.can_be_interacted())
				print("  In detection range: ", distance <= interaction_manager.detection_radius)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_E:
			print("E key pressed!")
			if interaction_manager:
				var closest: Interactable = interaction_manager.get_closest_interactable()
				print("  Closest interactable: ", closest)
				if closest:
					print("  Name: ", closest.interaction_name)
					print("  Distance: ", player.global_position.distance_to(closest.global_position))
