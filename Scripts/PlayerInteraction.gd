extends Area2D
class_name PlayerInteraction

signal interaction_target_changed(new_target: PlanetNPC)

@export var interact_key: StringName = "interact"  # bind "E" to this in Input Map

@onready var interaction_ui: InteractionUI = (
	get_tree().get_first_node_in_group("InteractUI") as InteractionUI
)

var _current_target: PlanetNPC = null

func _ready() -> void:
	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(interact_key):
		if _current_target != null:
			if interaction_ui != null:
				interaction_ui.open_for_planet(_current_target)

func _on_area_entered(area: Area2D) -> void:
	# We assume area's parent is the PlanetNPC
	var parent_node: Node = area.get_parent()
	if parent_node is PlanetNPC:
		_current_target = parent_node
		emit_signal("interaction_target_changed", _current_target)

func _on_area_exited(area: Area2D) -> void:
	var parent_node: Node = area.get_parent()
	if parent_node == _current_target:
		_current_target = null
		emit_signal("interaction_target_changed", _current_target)
