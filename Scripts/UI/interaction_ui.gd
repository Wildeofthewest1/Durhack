extends CanvasLayer
class_name InteractionUI

@export var interaction_manager: InteractionManager
@export var show_interaction_prompt: bool = true

@onready var interaction_panel: InteractionPanel = $InteractionPanel
@onready var player_ui: PlayerUI = $InteractionPanel/PanelContainer/MarginContainer/ContentContainer/PlayerContent/PlayerUI
@onready var talk_ui: TalkUI = $InteractionPanel/PanelContainer/MarginContainer/ContentContainer/TalkContent/TalkUI
@onready var info_label: RichTextLabel = $InteractionPanel/PanelContainer/MarginContainer/ContentContainer/InfoContent/InfoLabel

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var minimap_container: Control = $MinimapContainer

var current_interactable: Interactable = null

func _ready() -> void:
	# Connect interaction manager signals
	if interaction_manager:
		interaction_manager.interaction_triggered.connect(_on_interaction_triggered)
		interaction_manager.interactable_in_range.connect(_on_interactable_in_range)
		interaction_manager.interactable_out_of_range.connect(_on_interactable_out_of_range)
	
	# Connect panel signals
	if interaction_panel:
		interaction_panel.tab_changed.connect(_on_tab_changed)
	
	# Connect talk UI signals
	if talk_ui:
		talk_ui.option_selected.connect(_on_dialogue_option_selected)
	
	# Hide interaction prompt initially
	if interaction_prompt:
		interaction_prompt.visible = false

func _process(delta: float) -> void:
	_update_interaction_prompt()

func _update_interaction_prompt() -> void:
	if not show_interaction_prompt or not interaction_prompt:
		return
	
	if not interaction_manager:
		interaction_prompt.visible = false
		return
	
	var closest: Interactable = interaction_manager.get_closest_interactable()
	
	if closest and closest.can_be_interacted():
		interaction_prompt.visible = true
		interaction_prompt.text = "[E] " + closest.get_interaction_name()
		
		# Position prompt above the interactable
		var screen_pos: Vector2 = _world_to_screen(closest.global_position)
		screen_pos.y -= 50  # Offset above the object
		interaction_prompt.global_position = screen_pos
	else:
		interaction_prompt.visible = false

func _world_to_screen(world_pos: Vector2) -> Vector2:
	var viewport: Viewport = get_viewport()
	if not viewport:
		return Vector2.ZERO
	
	var camera: Camera2D = viewport.get_camera_2d()
	if not camera:
		return world_pos  # Return world pos if no camera
	
	return world_pos  # Simple fallback - in 2D with camera, this works

func _on_interaction_triggered(interactable: Interactable) -> void:
	current_interactable = interactable
	
	# Update info panel with interactable information
	_update_info_panel(interactable)
	
	# Switch to appropriate tab based on interactable type
	var interactable_type: String = interactable.get_interactable_type()
	
	if interactable.has_dialogue:
		# Switch to talk tab and start dialogue
		if interaction_panel:
			interaction_panel.switch_to_tab(InteractionPanel.PanelTab.TALK)
		_start_dialogue(interactable)
	else:
		# Just show info
		if interaction_panel:
			interaction_panel.switch_to_tab(InteractionPanel.PanelTab.INFO)
			interaction_panel.expand_panel()

func _on_interactable_in_range(_interactable: Interactable) -> void:
	pass  # Could add visual feedback here

func _on_interactable_out_of_range(_interactable: Interactable) -> void:
	if current_interactable == _interactable:
		# End dialogue if we're talking to this interactable
		if talk_ui and talk_ui.is_dialogue_active():
			talk_ui.end_dialogue()
		current_interactable = null

func _update_info_panel(interactable: Interactable) -> void:
	if not info_label:
		return
	
	var info_text: String = "[b]" + interactable.get_interaction_name() + "[/b]\n\n"
	info_text += "Type: " + interactable.get_interactable_type() + "\n"
	
	# Add custom data if available
	if not interactable.custom_data.is_empty():
		info_text += "\n[b]Additional Information:[/b]\n"
		for key: String in interactable.custom_data.keys():
			if key != "dialogue":
				info_text += key + ": " + str(interactable.custom_data[key]) + "\n"
	
	info_label.text = info_text

func _start_dialogue(interactable: Interactable) -> void:
	if not talk_ui:
		return
	
	var dialogue_data: Dictionary = interactable.get_dialogue_data()
	
	if dialogue_data.is_empty():
		# Create a default dialogue
		dialogue_data = {
			"start": {
				"text": "Hello there!",
				"speaker": interactable.get_interaction_name(),
				"options": [
					{"text": "Goodbye", "next": "end"}
				]
			}
		}
	
	var speaker_sprite: Texture2D = interactable.get_interaction_sprite()
	talk_ui.start_dialogue(dialogue_data, interactable.dialogue_start_node, speaker_sprite)

func _on_dialogue_option_selected(_option_index: int) -> void:
	# Handle dialogue option selection
	# Could trigger events, give items, etc.
	pass

func _on_tab_changed(_tab_name: String) -> void:
	# Handle tab changes
	if _tab_name == "talk" and not talk_ui.is_dialogue_active():
		# If switching to talk tab but no active dialogue, start one with current interactable
		if current_interactable and current_interactable.has_dialogue:
			_start_dialogue(current_interactable)

# Public API

func add_inventory_item(item: Dictionary) -> bool:
	if player_ui:
		return player_ui.add_item(item)
	return false

func remove_inventory_item(slot_index: int, quantity: int = 1) -> bool:
	if player_ui:
		return player_ui.remove_item(slot_index, quantity)
	return false

func get_inventory_item(slot_index: int) -> Dictionary:
	if player_ui:
		if slot_index >= 0 and slot_index < player_ui.inventory_data.size():
			return player_ui.inventory_data[slot_index].duplicate()
	return {}

func add_upgrade(upgrade: Dictionary) -> void:
	if player_ui:
		player_ui.add_upgrade(upgrade)

func add_fleet_ship(ship: Dictionary) -> void:
	if player_ui:
		player_ui.add_fleet_ship(ship)

func set_player_stats(name: String, level: int, credits: int) -> void:
	if player_ui:
		player_ui.set_player_stats(name, level, credits)

func open_panel() -> void:
	if interaction_panel:
		interaction_panel.expand_panel()

func close_panel() -> void:
	if interaction_panel:
		interaction_panel.collapse_panel()

func switch_to_player() -> void:
	if interaction_panel:
		interaction_panel.switch_to_tab(InteractionPanel.PanelTab.PLAYER)

func switch_to_talk() -> void:
	if interaction_panel:
		interaction_panel.switch_to_tab(InteractionPanel.PanelTab.TALK)

func switch_to_info() -> void:
	if interaction_panel:
		interaction_panel.switch_to_tab(InteractionPanel.PanelTab.INFO)
